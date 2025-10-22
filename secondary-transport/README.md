# Secondary Transport & Charge Fixes - OldOrg State Documentation

**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Org**: OldOrg (recyclinglives.my.salesforce.com)
**Status**: ✅ Production (V4 - includes Oct 7-8 implementation + Oct 14-15 bug fixes)
**Implementation Versions:** V1-V4 (Oct 7 → Oct 15, 2025)

---

## Related Documentation

**This scenario consolidates the following documentation** (component-based analysis):

1. **[SECONDARY_TRANSPORT_IMPLEMENTATION.md](source-docs/SECONDARY_TRANSPORT_IMPLEMENTATION.md)** - Secondary transport feature + CSV upload fix (Oct 7-8, 2025)
2. **[TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md](source-docs/TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md)** - Transport charge bugs fixed (Oct 10-15, 2025)

**Component Analysis - Why Consolidated**:
- Core component: rlcsJobService.cls (41,558 lines) - Modified in both Oct 7-8 AND Oct 14-15
- Shared: rlcsJobTriggerHandler, RLCSChargeService, Job_Charge__c object
- Timeline: Oct 7-8 ADDED secondary transport → Oct 10 bug introduced → Oct 14-15 bugs FIXED
- Sequential versions of same system: V1 (Oct 7) → V2 (Oct 8) → V3 (Oct 10 bug) → V4 (Oct 15 fix)
- Must deploy together as they're sequential versions with interdependent fixes

**Deployment Strategy**: Deploy V4 (latest, Oct 15) which includes all features and fixes.

**Complete Scenario Index**: See [DOCUMENTATION_MAPPING_AND_SCENARIOS.md](../../Documentation/DOCUMENTATION_MAPPING_AND_SCENARIOS.md) for all migration scenarios.

---

## Executive Summary

**System Purpose**: RLCS transport charge automation - create PRIMARY and SECONDARY transport charges automatically when Jobs are created/updated.

**Key Functionality**:
- Automatic creation of TWO transport charges per job (primary + secondary)
- CSV upload integration (RLCS Job Creator and ICER Report)
- Transport charge calculation based on job weight/units
- Automatic recalculation when job data changes

**Version History**:
- **V1 (Oct 7, 2025)**: Secondary Transport feature - ability to create 2 charges per job
- **V2 (Oct 8, 2025)**: CSV Upload fix - populate weight/units from CSV columns 14-15
- **V3 (Oct 10, 2025)**: Description fields added - introduced bug (map not reassigned)
- **V4 (Oct 14-15, 2025)**: Bug fixes - map reassignment + OrderItem source of truth

**Current State**: Fully operational V4 with all features and fixes deployed

---

## System Overview

### Transport Charge Creation Flow

```
Job Created/Updated (any method: UI, CSV, API)
    ↓
rlcsJobTrigger fires (after insert/update)
    ↓
rlcsJobTriggerHandler.handleAfterInsert/Update()
    ↓
rlcsJobService.createUpdateAutoJobCharges()
    ↓
┌─────────────────────────────────────────┐
│ PRIMARY Transport Charge                │
│ - Charge_Type__c = "Transport"          │
│ - Vendor__c = Job.Haullier__c           │
│ - Cost calculated from Job fields       │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ SECONDARY Transport Charge              │
│ - Charge_Type__c = "Secondary Transport"│
│ - Vendor__c = Job.Secondary_Haulier__c  │
│ - Cost calculated from Job fields       │
└─────────────────────────────────────────┘
```

### CSV Upload Integration

**RLCS Job Creator** (Stage 1):
- Reads CSV columns 14-15 (Material_Weight_Tonnes, Number_of_Units)
- Populates Job.Material_Weight_Tonnes__c and Job.Number_of_Units__c
- Trigger fires → Transport charges created automatically

**ICER Report Upload** (Stage 2):
- Updates existing Job with detailed breakdown
- Updates Material_Weight_Tonnes__c and Number_of_Units__c
- Trigger fires → Transport charges recalculated

---

## Components Inventory

### Apex Classes (5 total)

| Class Name | Lines | Last Modified | Purpose |
|------------|-------|---------------|---------|
| **rlcsJobService** | 41,558 | Oct 15, 2025 | Core service - transport charge creation |
| **rlcsJobServiceTest** | 84,118 | Oct 15, 2025 | Test class (comprehensive) |
| RLCSChargeService | 4,849 | Oct 10, 2025 | Charge calculation service |
| RLCSChargeServiceTest | 18,681 | Oct 10, 2025 | Test class |
| rlcsJobTriggerHandler | 4,081 | Jul 1, 2025 | Trigger handler |

**Key Methods in rlcsJobService**:
- `createUpdateAutoJobCharges()` - Main entry point for charge creation
- Lines 380-450: Secondary transport logic
- Line 277: Map reassignment (fixed Oct 15)
- Lines 393-396: Primary transport calculation (fixed Oct 15)

### Triggers

| Trigger Name | Object | Events | Purpose |
|--------------|--------|--------|---------|
| rlcsJobTrigger | Job__c | after insert, after update | Calls rlcsJobService for charge automation |

### Custom Objects/Fields

**Job__c** (RLCS Job):
- Material_Weight_Tonnes__c (CSV column 14)
- Number_of_Units__c (CSV column 15)
- Haullier__c (primary haulier)
- Secondary_Haulier__c (secondary haulier)
- Transport_Rate_Per_Tonne__c
- Secondary_Transport_Rate_Per_Tonne__c
- Transport_Calculation_Method__c ("Per Tonne", "Per Unit", "Per Load")
- Secondary_Transport_Calculation_Method__c

**Job_Charge__c**:
- Charge_Type__c ("Transport", "Secondary Transport")
- Vendor__c (haulier account)
- Cost__c (calculated amount)

---

## Implementation History

### V1: Secondary Transport Feature (Oct 7, 2025)

**WHY**:
- Business requirement for jobs needing multiple transport legs
- Primary: Customer → Depot
- Secondary: Depot → Final destination (AATF/processor)
- Needed to track and charge for both transports separately

**WHAT**:
- Added "Secondary Transport" charge type
- Modified rlcsJobService to create 2 charges per job
- Added fields: Secondary_Haulier__c, Secondary_Transport_Rate_Per_Tonne__c, etc.
- Independent calculation methods for each charge

**WHEN**:
- Deployed: October 7, 2025 at 15:01:04 UTC
- Deploy ID: **0AfSj000000yDbtKAE** (first of 16 deployments that day)
- Final deploy: 0AfSj000000yF2cKAE at 18:53:23 UTC

**TESTING**:
- 83/83 tests passed (100%)
- Verified 2 charges created per job
- Verified independent rate calculation

**METRICS**:
- Before: 1 transport charge per job
- After: 2 transport charges per job (when secondary configured)
- Impact: Accurate tracking of multi-leg transport costs

### V2: CSV Upload Fix (Oct 8, 2025)

**WHY**:
- RLCS Job Creator created jobs with NULL weight/units
- CSV had data in columns 14-15 but wasn't being populated
- Caused charges to calculate as: NULL × rate = $0
- Required manual data entry for every job

**WHAT**:
- Modified RLCS Job Creator Visualforce page
- Added logic to read CSV columns 14-15
- Populate Material_Weight_Tonnes__c and Number_of_Units__c on insert
- Fixed ICER Report Upload to update these fields

**WHEN**:
- Deployed: October 8, 2025 at 09:01:19 UTC
- Deploy ID: **0AfSj000000yGbNKAU**
- Multiple subsequent deployments for refinements

**TESTING**:
- 17/17 tests passed (100%)
- Verified CSV column 14 → Material_Weight_Tonnes__c
- Verified CSV column 15 → Number_of_Units__c
- Verified charges calculate correctly: 0.954 × £242.14 = £231.00

**METRICS**:
- Before: Jobs created with NULL weight/units, $0 charges
- After: Jobs created with correct weight/units, correct charges
- Impact: Eliminated manual data entry requirement

### V3: Description Fields Added (Oct 10, 2025) - Bug Introduced

**WHY**:
- Business requested description fields on charges for better tracking

**WHAT**:
- Added Description__c fields to transport charges
- Modified rlcsJobService to populate descriptions
- **BUG**: Required re-query of jobs but forgot to reassign `jobsToProcessById` map at line 277

**WHEN**:
- Deployed: October 10, 2025 (multiple deployments)
- Final deploy: 0AfSj000000yVDpKAM at 11:04:32 UTC
- Bug discovered: October 10-14 (562 jobs missing transport charges)

**BUG IMPACT**:
- 53% of jobs created Oct 8-10 missing Transport charges
- 562 jobs affected
- £919,510 in charges not created
- Root cause: Map reassignment missing after re-query

### V4: Bug Fixes (Oct 14-15, 2025)

**WHY**:
- Issue #1: 562 jobs missing Transport charges (map reassignment bug)
- Issue #2: 287 jobs missing Material_Category_Breakdown (user workflow, not bug)
- Issue #3: Transport charge calculation using wrong source (Job vs OrderItem)

**WHAT - Issue #1 Fix**:
- Line 277 of rlcsJobService.cls: Reassign `jobsToProcessById` after re-query
- Single line fix
- Backfilled 289 missing Transport charges

**WHAT - Issue #3 Fix**:
- Lines 393-396 of rlcsJobService.cls: Use OrderItem as source of truth for rates
- Changed from Job.Transport_Rate_Per_Tonne__c to OrderItem lookup
- Prevents overcharge when rates differ

**WHEN**:
- Issue identified: October 14, 2025
- Fix deployed: October 15, 2025 at 11:18:19 UTC
- Deploy ID: **0AfSj000000yp2rKAA**
- Backfill completed: October 15, 2025

**TESTING**:
- All existing tests pass
- 20 test methods updated
- Verified charges created correctly for new jobs
- Verified backfill data accuracy

**METRICS**:
- Before fix: 562 jobs missing charges, £919,510 unrecovered
- After fix: 289 charges backfilled, system creating charges correctly
- Financial impact: £870,835.90 in overcharges prevented (Issue #3)

---

## Current State Verification

### Apex Class Query Results

**Query Date**: October 22, 2025

All 5 classes verified present in OldOrg with V4 modifications:
- rlcsJobService.cls: **Oct 15, 2025** (latest bug fixes)
- rlcsJobServiceTest.cls: Oct 15, 2025
- RLCSChargeService.cls: Oct 10, 2025
- RLCSChargeServiceTest.cls: Oct 10, 2025
- rlcsJobTriggerHandler.cls: Jul 1, 2025 (stable, no changes needed)

### Deployment History

**Oct 7-15, 2025**: 75 successful deployments during implementation and bug fixes
- Oct 7: 16 deployments (V1 - secondary transport feature)
- Oct 8: 5 deployments (V2 - CSV upload fix)
- Oct 9-10: 33 deployments (V3 - description fields + bug introduced)
- Oct 14-15: 21 deployments (V4 - bug fixes and refinements)

**Latest Production Version**: Oct 15, 2025 11:18:19 UTC (Deploy ID: 0AfSj000000yp2rKAA)

---

## Business Logic

### Transport Charge Calculation

**Calculation Methods** (3 options):
1. **Per Tonne**: Cost = Material_Weight_Tonnes__c × Rate_Per_Tonne
2. **Per Unit**: Cost = Number_of_Units__c × Rate_Per_Unit
3. **Per Load**: Cost = Fixed rate (one charge per job)

**Primary Transport**:
- Uses Job.Transport_Calculation_Method__c
- Rate from OrderItem.Transport_Rate_Per_Tonne__c (source of truth, fixed Oct 15)
- Vendor from Job.Haullier__c

**Secondary Transport**:
- Uses Job.Secondary_Transport_Calculation_Method__c
- Rate from OrderItem.Secondary_Transport_Rate_Per_Tonne__c
- Vendor from Job.Secondary_Haulier__c (or same as primary if not specified)

### CSV Upload Logic

**RLCS Job Creator** (Stage 1):
```
CSV Row → Parse columns 1-15
Column 14 → Material_Weight_Tonnes__c
Column 15 → Number_of_Units__c
Insert Job → Trigger fires → 2 charges created
```

**ICER Report Upload** (Stage 2):
```
CSV with breakdown → Match existing Job
Update Material_Weight_Tonnes__c (sum of breakdown)
Update Number_of_Units__c
Update Job → Trigger fires → Charges recalculated
```

### Charge Creation Decision Logic

```apex
if (Job has Transport rate configured) {
    Create PRIMARY transport charge
}

if (Job has Secondary Transport rate configured) {
    Create SECONDARY transport charge
}

// Both, one, or neither charges created based on configuration
```

---

## Configuration

### Required Fields on Job__c

**For Primary Transport**:
- Haullier__c (vendor account)
- Transport_Rate_Per_Tonne__c (or Per Unit/Per Load rate)
- Transport_Calculation_Method__c ("Per Tonne", "Per Unit", "Per Load")
- Material_Weight_Tonnes__c OR Number_of_Units__c (depending on method)

**For Secondary Transport**:
- Secondary_Haulier__c (optional, defaults to primary)
- Secondary_Transport_Rate_Per_Tonne__c (or Per Unit/Per Load rate)
- Secondary_Transport_Calculation_Method__c
- Material_Weight_Tonnes__c OR Number_of_Units__c

### CSV Column Mapping

| CSV Column | Job Field | Purpose |
|------------|-----------|---------|
| 1-13 | Various | Job details |
| **14** | Material_Weight_Tonnes__c | Weight for charge calculation |
| **15** | Number_of_Units__c | Unit count for charge calculation |

---

## Testing Scenarios

### Test Case 1: Dual Transport Charges

**Setup**:
1. Create Job with primary AND secondary transport configured
2. Set Material_Weight_Tonnes__c = 5.0
3. Set Transport_Rate_Per_Tonne__c = £100
4. Set Secondary_Transport_Rate_Per_Tonne__c = £50

**Execute**: Save Job

**Expected Result**:
- ✅ 2 Job_Charge__c records created
- ✅ PRIMARY: Charge_Type__c = "Transport", Cost__c = £500
- ✅ SECONDARY: Charge_Type__c = "Secondary Transport", Cost__c = £250

**Verified**: October 7, 2025 (V1)

### Test Case 2: CSV Upload Creates Charges

**Setup**:
1. Upload CSV via RLCS Job Creator
2. CSV column 14 = 0.954 tonnes
3. Job has Transport_Rate_Per_Tonne__c = £242.14

**Execute**: CSV upload completes

**Expected Result**:
- ✅ Job created with Material_Weight_Tonnes__c = 0.954
- ✅ Transport charge created with Cost__c = £231.00 (0.954 × 242.14)
- ✅ No manual data entry required

**Verified**: October 8, 2025 (V2)

### Test Case 3: Charge Recalculation on Update

**Setup**:
1. Job exists with 1 transport charge (£100)
2. Upload ICER Report with updated weight (changes from 1.0 to 1.5 tonnes)

**Execute**: ICER upload updates Job

**Expected Result**:
- ✅ Material_Weight_Tonnes__c updated to 1.5
- ✅ Trigger fires
- ✅ Transport charge recalculated to £150
- ✅ Automatic recalculation, no manual intervention

**Verified**: October 8, 2025 (V2)

### Test Case 4: Bug Fix Verification

**Setup**:
1. Create Job after Oct 15 fix
2. Ensure description fields populated

**Execute**: Save Job

**Expected Result**:
- ✅ Transport charge created (no missing charge bug)
- ✅ Description fields populated
- ✅ Map reassignment working (line 277 fix)

**Verified**: October 15, 2025 (V4)

---

## Files and Metadata

### Apex Classes Location

All classes retrieved from OldOrg:
```
/home/john/Projects/Salesforce/force-app/main/default/classes/
├── rlcsJobService.cls (41,558 lines) ← PRIMARY FILE
├── rlcsJobService.cls-meta.xml
├── rlcsJobServiceTest.cls (84,118 lines) ← TEST FILE
├── rlcsJobServiceTest.cls-meta.xml
├── RLCSChargeService.cls (4,849 lines)
├── RLCSChargeService.cls-meta.xml
├── RLCSChargeServiceTest.cls (18,681 lines)
├── RLCSChargeServiceTest.cls-meta.xml
├── rlcsJobTriggerHandler.cls (4,081 lines)
└── rlcsJobTriggerHandler.cls-meta.xml
```

**Total**: 10 files (5 classes * 2 files each)

### Trigger Location

```
/home/john/Projects/Salesforce/force-app/main/default/triggers/
├── rlcsJobTrigger.trigger
└── rlcsJobTrigger.trigger-meta.xml
```

---

## Known Issues and Limitations

### Issue: High Deployment Frequency During Implementation

**Context**: 75 deployments over Oct 7-15 (7 days)
**Reason**: Iterative development, testing in production, quick fixes
**Impact**: Multiple rapid deployments may have introduced temporary instabilities
**Resolution**: All issues resolved by Oct 15, system stable

### Issue: Manual Backfill Required for Oct 8-10 Jobs

**Context**: 289 jobs missing transport charges due to Oct 10 bug
**Resolution**: Backfill script executed Oct 15
**Future Prevention**: Automated monitoring for missing charges

### Limitation: CSV Column Positions Fixed

**Current**: Columns 14-15 hard-coded for weight/units
**Impact**: CSV format cannot change without code update
**Recommendation**: Consider making column mappings configurable

---

## Migration Considerations

### Critical Pre-Migration Steps

1. **Verify Custom Fields**: Ensure all Job__c and Job_Charge__c fields exist in NewOrg
2. **Test Data**: Prepare test CSV files with columns 14-15 populated
3. **Backup**: Export existing Job_Charge__c records for rollback

### What Deploys Automatically

- ✅ All 5 Apex classes
- ✅ Trigger (rlcsJobTrigger)
- ✅ Custom field definitions (if not in NewOrg)

### What Requires Manual Configuration

- ⚠️ CSV upload pages (Visualforce, may need separate deployment)
- ⚠️ Permission sets (access to fields)
- ⚠️ Validation rules (if any)

### Post-Deployment Testing Priority

1. **HIGH**: Test CSV upload creates charges (V2 functionality)
2. **HIGH**: Test dual charges created (V1 functionality)
3. **CRITICAL**: Verify no missing charges (V4 bug fix)
4. **MEDIUM**: Test charge recalculation on update

---

## Risk Assessment

### Overall Risk: MEDIUM-HIGH

**Complexity Factors**:
- 41K+ lines in primary class (rlcsJobService.cls)
- 84K+ lines in test class (comprehensive testing)
- 4 sequential versions (V1→V2→V3→V4)
- Known bug in V3 that was fixed in V4
- 75 deployments during implementation period
- CSV upload integration (external process)

**Mitigation Strategies**:
- Deploy V4 (latest) to avoid V3 bug
- Comprehensive test suite (84K lines of tests)
- Test CSV upload thoroughly
- Monitor for missing charges in first week
- Have backfill script ready if needed

**Success Probability**: HIGH (V4 stable in OldOrg production, all bugs fixed)

---

## Contact Information

**Implementation Lead**: John Shintu
**Implementation Dates**: October 7-15, 2025
**Current System Owner**: [To be confirmed]
**Support Team**: RLCS Technical Team

---

## Version History

| Version | Date | Changes | Deploy ID |
|---------|------|---------|-----------|
| V1 | Oct 7, 2025 | Secondary transport feature | 0AfSj000000yDbtKAE |
| V2 | Oct 8, 2025 | CSV upload fix (columns 14-15) | 0AfSj000000yGbNKAU |
| V3 | Oct 10, 2025 | Description fields (bug introduced) | 0AfSj000000yVDpKAM |
| V4 | Oct 15, 2025 | Bug fixes (map + OrderItem) | 0AfSj000000yp2rKAA |

---

**END OF OLDORG STATE DOCUMENTATION**
