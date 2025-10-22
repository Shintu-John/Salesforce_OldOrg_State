# Transport Charges - OldOrg State Documentation

**Last Updated**: October 22, 2025
**OldOrg Implementation Date**: October 14-15, 2025 (Issues 1 & 3)
**Status**: ✅ All Code Fixes Deployed
**Type**: Bug Fixes & Data Correction
**Financial Impact**: £1,788,766 net positive (£919,510 recovered + £869,546 saved)

---

## Executive Summary

This document captures the **completed state** of three interrelated transport charge issues discovered and resolved in OldOrg during October 2025. Unlike other scenarios which document new features for migration, this scenario documents **bug fixes already deployed** in OldOrg that must be migrated to NewOrg to prevent the same issues.

**Three Issues Resolved**:

1. **Issue 1: Missing Transport Charges** (CODE BUG - ✅ FIXED)
   - 562 Jobs missing charges due to map reassignment bug
   - Single-line code fix deployed Oct 14, 2025
   - 289 charges backfilled (£919,510 recovered)

2. **Issue 2: Missing Material Category Breakdown** (USER PROCESS ISSUE - ⚠️ NOT CODE)
   - 287 Jobs missing breakdown records
   - NOT a code bug - users skipped Stage 2 of 2-stage process
   - No code changes required for migration

3. **Issue 3: Transport Charge Calculation Bug** (CODE BUG - ✅ FIXED)
   - 1,034 Jobs with incorrect calculations due to hybrid source bug
   - Three-phase fix deployed Oct 15, 2025 (code + data + validation)
   - £869,546 saved in overcharges

**Migration Significance**: NewOrg may have the **same bugs** (pre-Oct 14-15 code). This migration ensures NewOrg has the fixes to prevent identical issues.

---

## What's Being Migrated

**Critical Code Fixes** (Issues 1 & 3):
- ✅ **rlcsJobService.cls** - 2 bug fixes (map reassignment + OrderItem source of truth)
- ✅ **rlcsJobServiceTest.cls** - 20 test methods updated
- ✅ **Transport_Only_One_Method.validationRule** - NEW validation rule

**NOT Being Migrated** (Issue 2):
- ❌ No code changes (user process issue, not a bug)
- ❌ Material_Category_Breakdown creation logic already exists
- ❌ Issue is about user completing 2-stage RLCS Job Creator process

**Why This Matters**:
- NewOrg likely has **pre-Oct 14 code** with same bugs
- Without migration, NewOrg will experience identical issues:
  - Jobs created without transport charges (Issue 1)
  - Incorrect charge calculations (Issue 3)
- Migration prevents repeating £1.79M financial impact

---

## Issue 1: Missing Transport Charges (CODE FIX)

### Problem

**Date Discovered**: October 14, 2025
**Root Cause**: Oct 10, 2025 deployment added description fields requiring re-query but forgot to reassign the `jobsToProcessById` map at line 277

**Symptoms**:
- 562 Jobs (Oct 8-9, 2025) missing Transport charge records
- 53% failure rate vs 5% baseline
- Jobs had Transport__c rate but no RLCS_Charge__c records

**Example**:
```
Job-025316 (a4fSj0000004UvSIAU)
- Transport__c: £136 per tonne
- Material_Weight_Tonnes__c: 0.954 tonnes
- Expected: £136 × 0.954 = £129.74
- Actual: No charge record ❌
```

### Root Cause Analysis

**File**: [rlcsJobService.cls](../../force-app/main/default/classes/rlcsJobService.cls)
**Lines**: 259-277

**The Bug**:

Oct 10, 2025 deployment (for CS Invoicing Date/Description fields) added SOQL re-query to fetch `Order_Product__r` relationship fields needed for charge creation. The re-query was added correctly, but **line 277 was missing** - the critical reassignment that would make the loop use the fully-queried records.

```apex
// Lines 261-276: Re-query jobs with Order_Product__r fields
if (jobsToProcessById.size() > 0) {
    Map<Id, RLCS_Job__c> jobsWithOrderProductMap = new Map<Id, RLCS_Job__c>(
        [SELECT Id, Material_Weight_Tonnes__c, Unit_Count__c,
                Transport_Per_Tonne__c, Transport_Per_Unit__c,
                Transport__c, Sales_Transport__c, Customer_Account__c,
                Haullier__c, Processor__c, VAT__c,
                Order_Product__r.Transport__c,               // ← Needed for charge
                Order_Product__r.Secondary_Transport_Charge__c,
                Order_Product__r.Secondary_Transport_P_T__c,
                Order_Product__r.Secondary_Transport_Per_Tonne__c,
                Order_Product__r.Secondary_Transport_Per_Unit__c,
                Order_Product__r.Secondary_Haulier__c
         FROM RLCS_Job__c
         WHERE Id IN :jobsToProcessById.keySet()]
    );
    // ❌ BUG: Line 277 MISSING:
    // jobsToProcessById = jobsWithOrderProductMap;
}

// Line 302: Loop uses OLD incomplete jobsToProcessById
for (RLCS_Job__c job : jobsToProcessById.values()) {
    // This uses Trigger.new objects WITHOUT Order_Product__r fields
    // job.Order_Product__r.Transport__c = null
    // Transport charge creation fails silently
}
```

**Why Silent Failure**:
1. Trigger.new doesn't include relationship fields (Salesforce limitation)
2. Re-query fetched complete data including Order_Product__r.Transport__c
3. Without reassignment at line 277, loop still used incomplete Trigger.new
4. Code doesn't crash when Order_Product__r is null, just skips charge creation
5. No error logs, no exceptions - charges simply not created

**Impact**: 562 Jobs (53% of Oct 8-9 Jobs) missing transport charges

### The Fix (Issue 1)

**Deploy ID**: 0AfSj000000ymo9KAA
**Date**: October 14, 2025 at 18:37 UTC
**Duration**: 1 minute 22 seconds
**Test Results**: 65/65 passing (100%)

**Change Made**:

```apex
// Line 277: THE FIX - Re-assign map to use fully-queried records
if (jobsToProcessById.size() > 0) {
    Map<Id, RLCS_Job__c> jobsWithOrderProductMap = new Map<Id, RLCS_Job__c>(
        [SELECT Id, Material_Weight_Tonnes__c, ..., Order_Product__r.Transport__c
         FROM RLCS_Job__c
         WHERE Id IN :jobsToProcessById.keySet()]
    );
    // ✅ THE FIX: Single line added
    jobsToProcessById = jobsWithOrderProductMap;
}

// Now loop uses complete records with relationship fields
for (RLCS_Job__c job : jobsToProcessById.values()) {
    // job.Order_Product__r.Transport__c is populated ✅
    // Transport charges created correctly ✅
}
```

**Lines Changed**: 1 line added (line 277)

**Files Modified**:
- force-app/main/default/classes/rlcsJobService.cls (1 line)

**Single line of code fixed a £919,510 issue!**

### Backfill Results

After deploying fix, ran backfill script to create missing charges for affected 562 Jobs.

**Script**: backfill_missing_transport_charges_v3.apex (Anonymous Apex)
**Executed**: October 14, 2025 at 16:31 UTC
**Result**: ✅ Completed Successfully

**Charges Created**:
- Total: 289 transport charges
- Total Value: £919,510
- Breakdown:
  - Per Tonne: 187 charges (64.7%)
  - Per Unit: 78 charges (27.0%)
  - Per Load: 24 charges (8.3%)

**Note**: 58 of these charges were created with incorrect £136 rate (40 Fridge + 18 Cat3 products). This data quality issue led to the discovery of Issue 3.

### Verification

**Post-Fix Jobs** (Created after Oct 14, 18:38 UTC):
- Job-030670: 74 units × £6.06 = £448.44 ✅
- Job-030673: 1 unit × £16.54 = £16.54 ✅
- Job-030674: 105 units × £6.07 = £636.30 ✅

All Jobs created after fix receive transport charges correctly.

---

## Issue 2: Missing Material Category Breakdown (NOT A CODE BUG)

### Problem

**Date Discovered**: October 14, 2025 (during Issue 1 investigation)
**Status**: ⚠️ USER ACTION REQUIRED (NOT for migration)

**Symptoms**:
- 287 Jobs with Material_Weight_Tonnes populated
- Missing Material_Category_Breakdown__c records
- ALL 287 Jobs have CSV_Document__c = null

### Root Cause

**THIS IS NOT A CODE BUG** - This is a user process issue.

**Finding**: 100% correlation discovered:
- ALL 287 Jobs without breakdown have CSV_Document__c = null
- ALL Jobs WITH breakdown have CSV_Document__c != null

**What Happened**:

Users completed **Stage 1** of 2-stage RLCS Job Creator process but skipped **Stage 2**:

#### Stage 1: Job Creator Upload ✅ (Completed)
1. User uploads CSV with Job details
2. System creates RLCS_Job__c records (Material_Weight_Tonnes, Unit_Count, etc.)
3. System generates ICER Report CSV
4. ICER Report stored in Salesforce Files
5. Batch Tracker status = "Completed"

**Result**: Jobs created but Material_Category_Breakdown NOT created yet

#### Stage 2: Manual ICER Report Upload ❌ (Skipped)
1. User should download ICER Report from Stage 1
2. User should upload ICER Report via Manual Upload interface
3. System should create Material_Category_Breakdown records
4. System should update CSV_Document__c field

**Result**: Users never completed this step!

### Affected Jobs Breakdown

**Total**: 287 Jobs

**WEEE Waste Types** (Require Breakdown): 208 Jobs (72.5%)
- Cooling: 67 Jobs
- Display: 49 Jobs
- Small Mixed WEEE: 41 Jobs
- LDA (Large Domestic Appliances): 17 Jobs
- Others: 34 Jobs

**Non-WEEE Waste Types** (No Breakdown Needed): 79 Jobs (27.5%)
- Mixed Municipal Waste: 62 Jobs
- Lead Batteries: 5 Jobs
- Cardboard: 3 Jobs
- Others: 9 Jobs

### Why This Is NOT Migrated

**Reason 1: Not a Code Bug**
- Material_Category_Breakdown creation code already exists in both OldOrg and NewOrg
- [iParserio_ICER_ReportCsvBatch.cls](../../force-app/main/default/classes/iParserio_ICER_ReportCsvBatch.cls)
- Code works correctly when users complete Stage 2
- Issue is user not executing Stage 2, not code failing to create records

**Reason 2: Process Issue, Not Technical Issue**
- 100% correlation: CSV_Document__c = null means Stage 2 not done
- Code would create breakdown IF user uploaded ICER Report
- No code changes needed

**Reason 3: User Action Required**
- 50 WEEE Jobs have ICER Reports ready to upload (immediate action)
- 158 WEEE Jobs require user investigation
- 79 Non-WEEE Jobs need no action (breakdown not required)

**Migration Impact**: None - NewOrg already has Stage 2 code. User training/process improvements recommended but not part of migration.

---

## Issue 3: Transport Charge Calculation Bug (CODE FIX)

### Problem

**Date Discovered**: October 14, 2025 (during Issue 1 backfill analysis)
**Date Fixed**: October 15, 2025
**Root Cause**: Code used OrderItem **rate** but Job **flags** to determine calculation method (hybrid source bug)

**Symptoms**:
- Transport charges not matching expected amounts
- Discrepancy between OrderItem pricing and Job charges
- 1,034 Jobs affected
- £870,835.90 in potential overcharges

**Example**:
```
Job: 100 units, 2.5 tonnes
OrderItem: £4.34 per tonne, Transport_Per_Tonne__c = true
Job: Transport_Per_Unit__c = true (out of sync!)

BUGGY Calculation: 100 units × £4.34 = £434.00 (WRONG - used Job flag)
CORRECT Calculation: 2.5 tonnes × £4.34 = £10.85 (RIGHT - should use OrderItem flag)
```

### Root Cause Analysis

**Primary Cause**: Code Bug in [rlcsJobService.cls](../../force-app/main/default/classes/rlcsJobService.cls)

**The Bug** (Line 393-396):

```apex
// BUGGY CODE (Before Phase 1 fix)
Decimal primaryTransportAmount =
    (job.Transport_Per_Tonne__c ?              // ❌ Reading Job flag (WRONG)
        (job.Material_Weight_Tonnes__c ?? 0) :
     job.Transport_Per_Unit__c ?               // ❌ Reading Job flag (WRONG)
        (job.Unit_Count__c ?? 0) :
        1) *
    job.Order_Product__r?.Transport__c;        // ✅ Reading OrderItem rate (RIGHT)
```

**The Problem**:
- Code read OrderItem **rate** (correct source ✅)
- But read Job **flags** to determine calculation method (wrong source ❌)
- Job flags could be out of sync with OrderItem flags
- Result: "Hybrid" calculation using mismatched sources

**Impact**:
- When OrderItem = "per tonne" but Job = "per unit" → Wrong multiplier used
- When OrderItem = "per unit" but Job = "per tonne" → Wrong multiplier used
- No single source of truth → Inconsistent calculations

**Secondary Cause**: Oct 13-14 Data Changes

109 OrderItems changed to £136.00 per tonne on Oct 13-14 as part of bulk pricing update. Jobs using these OrderItems had old flags (per unit). The code bug amplified the impact:

```
OrderItem: £136 per tonne (new value Oct 13-14)
Job: Per unit flag (old value)
Buggy Code: 100 units × £136 = £13,600 (massive overcharge!)
Should Be: 2.5 tonnes × £136 = £340
```

**Evidence of Original Design Intent**:

Found comment in Oct 7, 2025 code backup:
```apex
// "Read from OrderItem (source of truth)"
```

This proves OrderItem was **always intended** as source of truth for both rate AND flags. The bug was incomplete implementation.

### The Fix (Issue 3) - Three Phases

#### Phase 1: Fix the Code (Prevent Future Issues)

**Deploy ID**: 0AfSj000000yp2rKAA
**Date**: October 15, 2025 at 11:18 UTC
**Duration**: 3 minutes 55 seconds
**Test Results**: 65/65 passing (100%)

**Changes Made**:

**File**: [rlcsJobService.cls](../../force-app/main/default/classes/rlcsJobService.cls)

**Change 1: Primary Transport Calculation (Line 393-396)**

```apex
// BEFORE (Buggy):
Decimal primaryTransportAmount =
    (job.Transport_Per_Tonne__c ?                    // ❌ Job flag
        (job.Material_Weight_Tonnes__c ?? 0) :
     job.Transport_Per_Unit__c ?                     // ❌ Job flag
        (job.Unit_Count__c ?? 0) :
        1) *
    primaryTransportRate;

// AFTER (Fixed):
Decimal primaryTransportAmount =
    (job.Order_Product__r?.Transport_Per_Tonne__c ?  // ✅ OrderItem flag
        (job.Material_Weight_Tonnes__c ?? 0) :
     job.Order_Product__r?.Transport_Per_Unit__c ?   // ✅ OrderItem flag
        (job.Unit_Count__c ?? 0) :
        1) *
    primaryTransportRate;
```

**Changes 2-3**: Similar fixes for:
- Rebate transport calculation (Line ~420)
- Additional transport calculation location (Line ~450)

**Change 4**: Updated **4 SOQL queries** to include OrderItem transport flag fields:
```apex
// Added to all Job queries:
Order_Product__r.Transport_Per_Tonne__c
Order_Product__r.Transport_Per_Unit__c
```

**Test Class Updates**:

**File**: [rlcsJobServiceTest.cls](../../force-app/main/default/classes/rlcsJobServiceTest.cls)

Updated **20 test methods** to set OrderItem flags before creating Jobs:

```apex
// BEFORE - only set Job fields:
Job.Transport_Per_Tonne__c = true;

// AFTER - set OrderItem fields (source of truth):
orderProduct.Transport_Per_Tonne__c = true;
orderProduct.Transport_Per_Unit__c = false;
update orderProduct;
```

**Test Methods Updated**:
1. testCreateJobWithTransportPerTonne
2. testCreateJobWithTransportPerUnit
3. testCreateJobWithTransportPerLoad
4. testUpdateJobTransportRate
5. testMultipleJobsWithDifferentRates
6. ... (15 more methods)

**Result**: ✅ Code now consistently uses OrderItem as source of truth for **both rate AND flags**

#### Phase 2: Rollback the Data (Undo Oct 13-14 Changes)

**Objective**: Rollback 109 OrderItems changed to £136 per tonne on Oct 13-14

**Discovery**:
- 949 Jobs affected by Oct 13-14 changes
- 109 unique OrderItems (one OrderItem → many Jobs)
- All needed rollback to pre-Oct-12 values

**Each OrderItem Updated**:
1. Transport__c: Reverted to pre-Oct-12 rate
2. Transport_Per_Tonne__c: Set to `false`
3. Transport_Per_Unit__c: Set to `true`

**Rate Distribution After Rollback**:

| Rate | Count | Notes |
|------|-------|-------|
| £0.00 | 10 | Free transport |
| £2.11 | 47 | Standard rate 1 |
| £4.34 | 29 | Standard rate 2 |
| £8.06 | 23 | Premium rate |
| **Total** | **109** | All per-unit |

**Execution**:
- Method: Individual record updates (`sf data update record`)
- Script: Scripts/phase2_rollback_all_109_orderitems.sh
- Result: ✅ 109/109 OrderItems updated (100% success)
- Duration: ~7 minutes

**Sample Before/After**:

Before:
```
OrderItem: 802Sj000008tBuMIAU
Rate: £136.00
Per_Tonne: true
Per_Unit: false
```

After:
```
OrderItem: 802Sj000008tBuMIAU
Rate: £2.11
Per_Tonne: false
Per_Unit: true ✅
```

#### Phase 3: Correct Existing Charges (Fix Past Charges)

**Objective**: Correct 145 transport charges calculated using buggy code

**Discovery**:
- Total: 145 charges
- Unlocked (no invoice): 75 charges (52%)
- Locked (invoiced): 70 charges (48%)

**Part A: Locked Charges (56 charges handled)**

**Problem**: Already invoiced - cannot modify charge amounts

**Solution**: Change 5 OrderItems to match what was actually invoiced

**Why This Works**:
- Invoices are final legal documents
- Better to make system reflect reality
- Future calculations will match historical invoices

**OrderItems Updated to Match Invoices**:

| OrderItem ID | Before | After | Example |
|--------------|--------|-------|---------|
| 802Sj00000BWoLCIA1 | £1.00 per tonne | £1.00 per unit | Invoice #808: 29 units → £29.00 |
| 802Sj000009ubsaIAA | £152.88 per tonne | £152.88 per unit | Match invoice amounts |
| 802Sj000009un49IAA | £152.88 per tonne | £152.88 per unit | Match invoice amounts |
| 802Sj00000Be3iQIAR | £136 per tonne | £136 per unit | Match invoice amounts |
| 802Sj00000Bf7nBIAR | £152 per tonne | £152 per unit | Match invoice amounts |

**Example - Invoice #808, Job-017733**:

Before Fix:
- OrderItem: £1.00 per tonne
- Job: 29 units, 1.08 tonnes
- Calculation: 1.08 tonnes × £1.00 = £1.08
- Invoice: £29.00
- Mismatch: £27.92 ❌

After Fix:
- OrderItem: £1.00 per unit
- Job: 29 units, 1.08 tonnes
- Calculation: 29 units × £1.00 = £29.00
- Invoice: £29.00
- Perfect match ✅

**Financial Impact (Locked)**: £1,289.90 already paid (documented loss, cannot recover)

**Part B: Unlocked Charges (75 charges)**

**Problem**: Charges not yet invoiced had incorrect amounts

**Solution**: Direct charge amount updates (Cost__c field)

**Method**: Bulk CSV update using `sf data update bulk`

**Execution**:
- Bulk Job ID: 750Sj00000LD4UmIAL
- Duration: 6.93 seconds
- Result: ✅ 75/75 successful (100%)

**Sample Corrections**:

| Job | Before | After | Savings |
|-----|--------|-------|---------|
| Job-025478 | £16,592.00 | £257.42 | £16,334.58 |
| Job-025479 | £20,808.00 | £322.83 | £20,485.17 |
| Job-025481 | £35,224.00 | £546.49 | £34,677.51 |
| Job-022517 | £35.66 | £8.06 | £27.60 |
| Job-017632 | £4.34 | £0.00 | £4.34 |

**Financial Impact (Unlocked)**: ✅ £869,546.00 prevented overpayments (actual savings)

#### Phase 4: Validation Rule (Prevent Future Invalid States)

During Phase 3, discovered 3 OrderItems with **BOTH** Transport_Per_Tonne__c AND Transport_Per_Unit__c = true (invalid state causing calculation confusion).

**User Feedback**: "Don't we have a validation rule that they can only select one logic?"

**Discovery**: Validation existed for Secondary Transport but NOT Primary Transport!

**Deploy ID**: 0AfSj000000ypVtKAI
**Date**: October 15, 2025 at 12:31 UTC
**Duration**: 37 seconds
**Test Results**: N/A (validation rule, no tests required)

**File**: [Transport_Only_One_Method.validationRule-meta.xml](../../force-app/main/default/objects/OrderItem/validationRules/Transport_Only_One_Method.validationRule-meta.xml)

```xml
<errorConditionFormula>AND(
    Transport_Per_Tonne__c = TRUE,
    Transport_Per_Unit__c = TRUE
)</errorConditionFormula>

<errorMessage>You cannot select both 'Per Tonne' and 'Per Unit' for transport.
Please select only one calculation method, or leave both unchecked for
'Per Load' pricing.</errorMessage>
```

**Before Deployment**: Fixed 3 OrderItems to have only one flag true

**Result**: ✅ Validation rule now prevents invalid flag states

### Financial Impact Summary

| Category | Amount | Status |
|----------|--------|--------|
| **Prevented Overpayments** (Unlocked) | £869,546.00 | ✅ Saved |
| **Documented Overpayments** (Locked) | £1,289.90 | Already paid |
| **Total Impact** | **£870,835.90** | - |
| **Net Savings** | **£869,546.00** | ✅ Success |

**Top 5 Savings**:
1. Job-025481: £34,677.51
2. Job-025479: £20,485.17
3. Job-025478: £16,334.58
4. Job-025482: £29,321.91
5. Job-025483: £27,313.56

**These 5 jobs alone**: £128,132.73 saved

### Verification

**Code Verification**:
- ✅ 3/3 calculation locations fixed (primary, rebate, additional)
- ✅ 4/4 SOQL queries updated with OrderItem flag fields
- ✅ 20/20 test methods updated to set OrderItem flags
- ✅ 65/65 tests passing (100%)
- ✅ 2/2 deployments successful (code fix + validation)

**Data Verification**:
- ✅ 109/109 OrderItems rolled back to pre-Oct-12 values
- ✅ 949 Jobs using corrected OrderItems
- ✅ 75/75 unlocked charges updated
- ✅ 56 locked charges documented
- ✅ 5 OrderItems updated to match invoices

**Enhanced Report Verification** (1,034 total Jobs):
- ✅ 949 Jobs: Fixed in Phase 2 (Oct 13/14 rollback)
- ✅ 83 Jobs: Fixed in Phase 3 or already correct
- ⚠️ 2 Jobs: Left as-is (18T Box Wagon with pre-existing high rates)

**Success Rate**: 99.8% (1,032 out of 1,034 Jobs)

---

## Combined Impact - All Issues

### Financial Impact

| Issue | Impact | Status |
|-------|--------|--------|
| Issue 1 | £919,510 recovered | ✅ Complete |
| Issue 2 | No direct financial impact | ⚠️ User action (not code) |
| Issue 3 | £869,546 saved + £1,290 documented loss | ✅ Complete |
| **Total** | **£1,789,056** | **Net: £1,788,766 saved** |

### Records Affected

| Issue | Jobs | Charges | OrderItems |
|-------|------|---------|------------|
| Issue 1 | 562 | 289 backfilled | - |
| Issue 2 | 287 (208 WEEE) | - | - |
| Issue 3 | 1,034 | 145 corrected | 109 rolled back + 5 matched to invoices |

### Code Changes Summary

**Issue 1**:
- rlcsJobService.cls: 1 line added (map reassignment)
- Tests: No changes (existing tests passed)

**Issue 3**:
- rlcsJobService.cls: 3 calculation locations + 4 SOQL queries updated
- rlcsJobServiceTest.cls: 20 test methods updated
- Transport_Only_One_Method.validationRule: NEW validation rule

**Issue 2**:
- No code changes (user process issue)

---

## OldOrg State Verification

### Deployment Records

| Issue | Deploy ID | Date | Status | Components | Tests |
|-------|-----------|------|--------|------------|-------|
| Issue 1 | 0AfSj000000ymo9KAA | Oct 14, 2025 18:37 UTC | ✅ Succeeded | 1 (rlcsJobService.cls) | 65/65 ✅ |
| Issue 3 Code | 0AfSj000000yp2rKAA | Oct 15, 2025 11:18 UTC | ✅ Succeeded | 2 (rlcsJobService + Test) | 65/65 ✅ |
| Issue 3 Validation | 0AfSj000000ypVtKAI | Oct 15, 2025 12:31 UTC | ✅ Succeeded | 1 (Validation Rule) | N/A |

### Apex Classes

| Class | Lines (Without Comments) | Last Modified | Modified By |
|-------|-------------------------|---------------|-------------|
| rlcsJobService.cls | 41,558 | Oct 15, 2025 11:18 UTC | John Shintu |
| rlcsJobServiceTest.cls | 84,118 | Oct 15, 2025 11:18 UTC | John Shintu |
| RLCSChargeService.cls | 4,849 | Oct 10, 2025 11:00 UTC | John Shintu |

**Note**: RLCSChargeService.cls last modified Oct 10 for CS Invoicing scenario (different feature). Not modified for Transport Charges issues.

### Validation Rules

| Rule | Object | Active | Created Date |
|------|--------|--------|--------------|
| Transport_Only_One_Method | OrderItem | ✅ Yes | Oct 15, 2025 12:31 UTC |

### OrderItem Fields

**Primary Transport**:
- Transport__c (Decimal) - Rate amount
- Transport_Per_Tonne__c (Checkbox) - Flag for per-tonne calculation
- Transport_Per_Unit__c (Checkbox) - Flag for per-unit calculation
- (If both false: per-load calculation)

**Secondary Transport** (similar pattern):
- Secondary_Transport_Charge__c
- Secondary_Transport_P_T__c
- Secondary_Transport_Per_Tonne__c
- Secondary_Transport_Per_Unit__c
- Secondary_Haulier__c

**Note**: These fields existed before fixes. Fixes changed HOW code uses them (OrderItem as source of truth).

### RLCS_Job__c Fields

**Job Flags** (NO LONGER USED as source for calculation):
- Transport_Per_Tonne__c (Checkbox) - **Now only for display, NOT calculation**
- Transport_Per_Unit__c (Checkbox) - **Now only for display, NOT calculation**

**Measurement Fields** (Still used for multiplier):
- Material_Weight_Tonnes__c (Decimal)
- Unit_Count__c (Number)

**Relationship Field**:
- Order_Product__c (Lookup to OrderItem) - **Source of truth for rates and flags**

**Note**: Job flags still exist but code now reads flags from OrderItem, not Job.

---

## How Issues Are Related

### Discovery Timeline

```
Oct 8-9   → Issue 1 occurs (missing charges due to map reassignment bug)
Oct 10    → CS Invoicing deployment (added re-query, forgot reassignment)
Oct 13-14 → Bulk pricing changes (109 OrderItems to £136 per tonne)
Oct 14    → Issue 1 discovered and fixed (map reassignment)
Oct 14    → Issue 1 backfill creates 58 charges with wrong £136 rates
Oct 14    → Wrong rates lead to discovery of Issue 3 (hybrid calculation bug)
Oct 14    → During Issue 3 investigation, discover Issue 2 (missing breakdown)
Oct 15    → Issue 3 fixed (3 phases: code, data, validation)
Oct 15    → All issues documented and resolved
```

### Interconnected Solutions

**Code Fixes**:
- Issue 1: Map reassignment (1 line) - Ensures relationship fields available
- Issue 3: OrderItem source of truth (3 locations + queries + tests) - Uses those fields correctly

**Data Fixes**:
- Issue 1: Backfill 289 charges (recovered £919,510)
- Issue 3: Rollback 109 OrderItems, correct 145 charges (saved £869,546)

**Process/Validation**:
- Issue 2: User training recommended (not code change)
- Issue 3: Validation rule prevents invalid flag states

**Common Themes**:
1. Relationship Fields: Issues 1 & 3 both involve Order_Product__r relationships
2. Silent Failures: All three issues failed silently without errors
3. Field History: OrderItemHistory critical for understanding Issue 3
4. Financial Impact: £1.79M combined impact prevented/recovered

---

## Migration Significance

### Why NewOrg Needs These Fixes

**NewOrg Likely Has Same Bugs**:
- NewOrg created from OldOrg org snapshot
- Snapshot likely taken **before** Oct 14-15 fixes
- NewOrg would have **pre-Oct 14 code** with same bugs

**Without Migration, NewOrg Will Experience**:

**Issue 1 (Missing Charges)**:
- Jobs created without transport charges
- 53% failure rate vs 5% baseline
- Revenue loss (charges not created = not invoiced)

**Issue 3 (Wrong Calculations)**:
- Charges calculated using Job flags instead of OrderItem flags
- Potential overcharges when flags out of sync
- Financial impact could exceed £870K like in OldOrg

**Issue 2 (Not Code-Related)**:
- NewOrg already has Stage 2 ICER upload code
- Issue is user process, not code bug
- User training/process improvements needed in both orgs

### What Migration Prevents

**By migrating these fixes to NewOrg**:
1. ✅ Jobs will always have transport charges created (Issue 1 fixed)
2. ✅ Charges calculated using OrderItem as single source of truth (Issue 3 fixed)
3. ✅ Validation rule prevents invalid flag states (Issue 3 validation)
4. ✅ Prevents repeating £1.79M financial impact

---

## Future Behavior (After Migration)

**For all future Jobs in NewOrg**:

1. Job references OrderItem (Order_Product__c relationship)
2. Code reads **rate AND flags** from OrderItem ✅
3. Code uses Job **measurements** (tonnes/units)
4. Code calculates: (method logic from OrderItem) × rate from OrderItem
5. Charge created with correct amount ✅

**Example Scenarios**:

**Per Unit**:
```
OrderItem: £4.34 per unit (Transport_Per_Unit__c = true)
Job: 100 units, 2.5 tonnes
Calculation: 100 units × £4.34 = £434.00 ✅
```

**Per Tonne**:
```
OrderItem: £10.00 per tonne (Transport_Per_Tonne__c = true)
Job: 50 units, 3.2 tonnes
Calculation: 3.2 tonnes × £10.00 = £32.00 ✅
```

**Per Load**:
```
OrderItem: £150.00 per load (both flags false)
Job: 200 units, 5.0 tonnes
Calculation: 1 × £150.00 = £150.00 ✅
```

**All Job Creation Methods Covered**:

Fix works for ALL methods because it's in the trigger:
```
ANY Creation Method → Job Saved → Trigger Fires → rlcsJobService.createUpdateAutoJobCharges()
```

Methods covered:
- ✅ Standard UI
- ✅ RLCS Job Creator
- ✅ Manual Upload / Data Loader
- ✅ API Integration
- ✅ Process Builder / Flow
- ✅ Custom Apex Code

**No additional work needed!** ✅

---

## Key Takeaways

### What Went Wrong (OldOrg)

**Issue 1**:
1. ❌ Incomplete code change (added re-query, forgot reassignment)
2. ❌ Silent failure (no error, just missing charges)
3. ❌ Insufficient test coverage for relationship field dependency

**Issue 3**:
1. ❌ Hybrid calculation (mixed sources of truth)
2. ❌ Incomplete implementation of original design
3. ❌ No validation preventing invalid flag states
4. ❌ Job flags could get out of sync with OrderItem flags

**Issue 2**:
1. ❌ No validation requiring Stage 2 completion for WEEE types
2. ❌ No monitoring for Jobs stuck after Stage 1
3. ❌ Insufficient user training on 2-stage process

### What Went Right (OldOrg)

**Issue 1**:
1. ✅ Quick discovery (within days)
2. ✅ Fast root cause identification
3. ✅ Successful backfill (289 charges recovered)
4. ✅ Single-line fix

**Issue 3**:
1. ✅ Three-phase approach (code, data, charges)
2. ✅ 100% rollback success (109 OrderItems)
3. ✅ Creative solution for locked charges (match invoices)
4. ✅ £869,546 saved in unlocked charges
5. ✅ Validation rule prevents future invalid states

**Issue 2**:
1. ✅ 100% correlation analysis (CSV_Document__c = null)
2. ✅ Concrete evidence (Batch Tracker + ICER Report verified)
3. ✅ Waste type analysis (WEEE vs Non-WEEE identified)

### Improvements Implemented

**Code Quality**:
- ✅ Map reassignment fix (Issue 1)
- ✅ OrderItem source of truth enforced (Issue 3)
- ✅ Test coverage improved (20 test methods updated)
- ✅ Validation rule added (Issue 3)

**Documentation**:
- ✅ Complete analysis for all three issues
- ✅ CSV reports for data investigation
- ✅ Scripts for data fixes
- ✅ Consolidated master document

---

## Files Reference

### Code Files Modified (Issues 1 & 3)

**Apex Classes**:
- [rlcsJobService.cls](../../force-app/main/default/classes/rlcsJobService.cls) - Line 277 (Issue 1), Lines 393-450 + 4 queries (Issue 3)
- [rlcsJobServiceTest.cls](../../force-app/main/default/classes/rlcsJobServiceTest.cls) - 20 test methods (Issue 3)

**Validation Rules**:
- [Transport_Only_One_Method.validationRule-meta.xml](../../force-app/main/default/objects/OrderItem/validationRules/Transport_Only_One_Method.validationRule-meta.xml) - NEW (Issue 3)

### Code Files Referenced (Issue 2 - No Changes)

**RLCS Job Creator** (existing code, no changes):
- [RLCSJobAATFController.cls](../../force-app/main/default/classes/RLCSJobAATFController.cls) - Stage 1
- [iParserio_ICER_ReportCsvBatch.cls](../../force-app/main/default/classes/iParserio_ICER_ReportCsvBatch.cls) - Stage 2

### Source Documentation

- [TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md](source-docs/TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md) - Complete 1,140-line source documentation

---

## Known Limitations

**Issue 1 (Missing Charges)**:
- Fix only prevents future occurrences
- Backfill was one-time script execution in OldOrg
- NewOrg may need similar backfill if pre-Oct 14 Jobs exist

**Issue 3 (Calculation Bug)**:
- Fix only prevents future incorrect calculations
- Data corrections (Phase 2-3) were OldOrg-specific
- NewOrg may need similar data analysis if affected Jobs exist

**Issue 2 (Material Category Breakdown)**:
- Not a code bug - user training needed in both orgs
- Stage 2 upload still manual process
- No automation for Stage 2 completion reminder

---

## Documentation Date

**Created**: October 22, 2025
**OldOrg Implementation Dates**:
- Issue 1 Fix: October 14, 2025 at 18:37 UTC
- Issue 3 Code Fix: October 15, 2025 at 11:18 UTC
- Issue 3 Validation: October 15, 2025 at 12:31 UTC

**Deployment IDs**:
- Issue 1: 0AfSj000000ymo9KAA
- Issue 3 Code: 0AfSj000000yp2rKAA
- Issue 3 Validation: 0AfSj000000ypVtKAI

**Status**: ✅ All Fixes Complete in OldOrg, Ready for Migration to NewOrg

---

**END OF OLDORG STATE DOCUMENTATION**
