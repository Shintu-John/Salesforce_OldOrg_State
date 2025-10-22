# Job Charge Credit on Account Fix - Complete Documentation

**Date:** October 22, 2025
**Reporter:** Louise Painter
**Issue:** Credit on Account charges getting incorrect Cost values on save
**Status:** ✅ RESOLVED

---

## Issue Summary

When users created "Credit on Account" Job Charges and entered correct negative values for both Cost and Sales Price fields (as displayed in the UI), upon clicking Save, the values were being automatically changed incorrectly by a flow that should only run on Rebate charges.

### Understanding the Field Structure

⚠️ **IMPORTANT:** Job Charges have TWO sets of Cost/Sales Price fields:

1. **Database Fields:** `Cost__c` and `Sales_Price__c` (actual stored values)
2. **Formula Display Fields:** `Cost_Rebate__c` and `Sales_Price_Rebate__c` (what users see in UI, labeled "Cost." and "Sales Price.")

**Why?** For Rebate charges, money flows in reverse (supplier pays us, we pay customer), so:
- **Database maintains accounting consistency:** `Cost__c` = money out, `Sales_Price__c` = money in
- **Formula fields swap display for Rebates:** to match user mental model

**Result:** What users enter in UI (using formula fields) gets stored swapped in database fields for Rebate-related charges.

### Example of the Issue

**Job:** [Job-000609890](https://recyclinglives.lightning.force.com/lightning/r/Job__c/a26Sj000001xRRqIAM/view)

**Related Rebate Charge (Database Fields):**
- Cost__c = 318.98
- Sales_Price__c = 396.78

**Related Rebate Charge (What Users See in UI via Formula Fields):**
- Cost (Cost_Rebate__c) = £396.78 (displays Sales_Price__c for Rebates)
- Sales Price (Sales_Price_Rebate__c) = £318.98 (displays Cost__c for Rebates)

**What Louise Entered for Credit on Account (in UI):**
- Cost = -£396.78 ✓ (correct - negative of displayed Rebate Cost)
- Sales Price = -£318.98 ✓ (correct - negative of displayed Rebate Sales Price)

**What Should Get Stored in Database (swapped from UI):**
- Cost__c = -396.78 (negative of Rebate's Sales_Price__c)
- Sales_Price__c = -318.98 (negative of Rebate's Cost__c)

**What Actually Happened After Save (BUG):**
- Cost__c = **318.98** ✗ (flow overwrote it - became positive and wrong!)
- Sales_Price__c = -318.98 ✓ (stayed correct)

**After Our Fix:**
- Cost__c = **-396.78** ✓ (corrected)
- Sales_Price__c = **-318.98** ✓ (correct)

#### Visual Summary of Field Relationship

```
REBATE CHARGE:
┌─────────────────────────────────────────────────────────────────┐
│ Database Storage          Formula Display (UI)                 │
│ ─────────────────         ───────────────────                  │
│ Cost__c = 318.98    ───►  Sales_Price_Rebate__c = £318.98     │
│ Sales_Price__c = 396.78 ─► Cost_Rebate__c = £396.78           │
└─────────────────────────────────────────────────────────────────┘
                                    ▼
                          User sees: Cost £396.78, Sales £318.98
                                    ▼
                          User enters for Credit: -£396.78, -£318.98
                                    ▼
CREDIT ON ACCOUNT:
┌─────────────────────────────────────────────────────────────────┐
│ Database Storage          Formula Display (UI)                 │
│ ─────────────────         ───────────────────                  │
│ Cost__c = -396.78   ───►  Cost_Rebate__c = -£396.78           │
│ Sales_Price__c = -318.98 ─► Sales_Price_Rebate__c = -£318.98  │
└─────────────────────────────────────────────────────────────────┘

KEY INSIGHT: Database fields are SWAPPED for Rebate charges only!
```

---

## Root Cause Analysis

### The Flow

The issue was caused by the flow `Job_Charge_Minimum_20_Gross_on_Rebate` which was incorrectly configured to run on both "Rebate" AND "Credit on Account" charge types.

**Flow Purpose:** Enforce a minimum 20% gross margin on Rebate charges by auto-adjusting Cost__c and Job Sales_Price__c if the margin is too low.

**The Bug:** The flow's entry criteria included "Credit on Account" charges using an OR condition:
```
filterLogic: 1 AND (2 OR 3) AND 4 AND 5 AND 6
Filter 2: Charge_Type__c = "Rebate"
Filter 3: Charge_Type__c = "Credit on Account"  ← SHOULD NOT BE HERE!
```

### When the Bug Triggered

The flow only executed when **ALL** these conditions were met:

1. ✅ CreatedDate > January 15, 2025
2. ✅ Charge_Type = "Rebate" **OR** "Credit on Account"
3. ✅ Vendor Account NOT in excluded list (BT, BG, JLP)
4. ✅ Sales Account.Account_Uses_Ratecard = false
5. ✅ **Job Margin < 20%** ← KEY CONDITION
6. ✅ Don_t_Apply_Auto_Margin__c = false
7. ✅ Vendor_Account.Don_t_Apply_Rebate_Margin__c = false

### Why It "Worked" Most of the Time

**Statistics since January 15, 2025:**
- Total Credit on Account charges created: **279**
- Charges affected by the bug: **3 (1.08%)**
- Charges that worked correctly: **276 (98.92%)**

**Most charges avoided the bug because:**
- Most Jobs naturally have 20% margin or higher (standard pricing practice)
- Only Jobs with margin < 20% triggered the flow
- The combination of all conditions being met was very rare

### Detailed Analysis

**Working Example - Job-000606871:**
- Job Margin: (100 - 80) / 100 = **20.00%**
- Flow Condition: Margin < 20%? **FALSE**
- Result: Flow did NOT execute ✓
- Credit on Account values preserved correctly ✓

**Broken Example - Job-000609890:**
- Job Margin: (51 - 41) / 51 = **19.61%**
- Flow Condition: Margin < 20%? **TRUE**
- Result: Flow EXECUTED ✗
- Cost__c overwritten with calculated value: 318.98 ✗

### What the Flow Did Wrong

When the flow executed on Credit on Account charges, it:

1. Calculated: `Remove_20p_Margin_Full_Weight = ROUND(Job.Supplier_Price * 0.8, 0) * Job.Weight`
2. For Job-000609890: ROUND(51 * 0.8, 0) * 7.78 = 41 * 7.78 = **318.98**
3. **OVERWROTE** the user's Cost__c value (-396.78) with the calculated value (318.98)
4. Also updated the parent Job's Sales_Price__c (not the Job Charge)

---

## The Fix

### Changes Made

**File:** `force-app/main/default/flows/Job_Charge_Minimum_20_Gross_on_Rebate.flow-meta.xml`

**Change 1 - Removed "Credit on Account" from filter:**
```xml
<!-- BEFORE -->
<filterLogic>1 AND (2 OR 3) AND 4 AND 5 AND 6</filterLogic>
<filters>
    <field>Charge_Type__c</field>
    <operator>EqualTo</operator>
    <value>
        <stringValue>Rebate</stringValue>
    </value>
</filters>
<filters>
    <field>Charge_Type__c</field>
    <operator>EqualTo</operator>
    <value>
        <stringValue>Credit on Account</stringValue>  ← REMOVED
    </value>
</filters>

<!-- AFTER -->
<filterLogic>1 AND 2 AND 3 AND 4 AND 5</filterLogic>
<filters>
    <field>Charge_Type__c</field>
    <operator>EqualTo</operator>
    <value>
        <stringValue>Rebate</stringValue>
    </value>
</filters>
<!-- Credit on Account filter removed -->
```

**Change 2 - Updated description:**
```xml
<description>22/10/2025: Removed Credit on Account from filter - should only run on Rebate charges
15/01/2025: Bypassed for BT, BG and JLP</description>
```

### Deployment Details

- **Deployed:** October 22, 2025 at 11:18 UTC
- **Flow Version:** v6 (activated)
- **Previous Version:** v5 (now obsolete)
- **Backup Location:** `/home/john/Projects/Salesforce/Backup/2025-10-22_job_charge_credit_on_account_fix/`

### Fixed Broken Records

Updated 3 existing broken Credit on Account charges:

| Charge ID | Charge Name | Job | Sales_Price (Fixed) | Cost (Fixed) |
|-----------|-------------|-----|---------------------|--------------|
| a29Sj000000r2LRIAY | Chrg-00834822 | a26Sj000001ZXOjIAO | -196.62 | -158.2 |
| a29Sj000000ybr8IAA | Chrg-00852223 | a26Sj000001xRRqIAM | -318.98 | -396.78 |
| a29Sj000000ye5pIAA | Chrg-00852233 | a26Sj000001xRRqIAM | -318.98 | -396.78 |

---

## Technical Details

### Complete Automation Chain for Job Charge Creation

When a Job Charge is created and saved, the following automations execute in order:

**1. BEFORE SAVE (Synchronous):**
- `Job_Charge_Before_Save` flow
  - Updates In_Query_Date__c if needed
  - Updates Parent_Job__c for mixed jobs

**2. RECORD IS SAVED**

**3. AFTER SAVE (Synchronous):**
- `JobChargeTrigger` (Apex)
  - Sets account lookups
  - Handles rollups to invoices

- `Job_Charge_Minimum_20_Gross_on_Rebate` flow (NOW FIXED - only runs on Rebate)
  - Entry criteria: Rebate charges only
  - Enforces 20% minimum margin
  - Updates Cost__c if margin < 20%
  - Updates parent Job's Sales_Price__c

- `Job_Charge_Minimum_Gross_Consumable_Charges` flow
  - Entry criteria: Wasted Journey, Rental, or Contamination only
  - Enforces 30% minimum margin

- `Job_Charge_Populate_Customer_and_Supplier_Account_ID_s` flow
  - Populates Customer_Account_ID__c and Supplier_Account_ID__c

**4. AFTER COMMIT (Asynchronous):**
- Other flows for dates, paperwork, etc.

### Field Mapping for Credit on Account Charges - CRITICAL UNDERSTANDING

#### Quick Summary

**TL;DR:** Rebate charges have inverted money flow (supplier pays us, we pay customer), so the database maintains accounting consistency by storing values "backwards" from business terminology. Formula display fields (`Cost_Rebate__c`, `Sales_Price_Rebate__c`) swap them for user-friendly display. This is why Credit on Account database values appear swapped compared to what users enter in the UI.

---

⚠️ **There are TWO sets of Cost/Sales Price fields on Job Charge records:**

1. **Database Fields:** `Cost__c` and `Sales_Price__c` (actual stored values)
2. **Formula Display Fields:** `Cost_Rebate__c` (labeled "Cost.") and `Sales_Price_Rebate__c` (labeled "Sales Price.")

#### Why Two Sets of Fields?

**For Rebate charges, the accounts and money flow are inverted:**

**Normal Charges (Job, Tonnage, etc.):**
- Customer pays Recycling Lives → Recycling Lives pays Supplier
- Sales_Account = Customer, Vendor_Account = Supplier
- Database fields match business meaning

**Rebate Charges:**
- Supplier pays Recycling Lives (rebate) → Recycling Lives pays Customer (passing rebate)
- Sales_Account = **Supplier**, Vendor_Account = **Customer** (SWAPPED!)
- Database fields maintain accounting consistency (debit/credit perspective)

#### Database Structure (Accounting Perspective)

From Recycling Lives' accounting viewpoint:
- **Cost__c** = Money OUT (what we pay)
- **Sales_Price__c** = Money IN (what we receive)

**For Rebate charges:**
- We receive £220 from supplier (rebate) → stored in **Sales_Price__c**
- We pay £176 to customer (rebate pass-through) → stored in **Cost__c**

**For Credit on Account charges (reversing the Rebate):**
- Database: Cost__c = -220, Sales_Price__c = -176
- Pattern: **Swapped AND Negated** (from database perspective)

#### Formula Display Fields (User Perspective)

Users think in business terms, not accounting terms, so formula fields swap the display:

**`Cost_Rebate__c` formula:**
```
IF(Charge_Type = "Rebate", Sales_Price__c, Cost__c)
```

**`Sales_Price_Rebate__c` formula:**
```
IF(Charge_Type = "Rebate", Cost__c, Sales_Price__c)
```

**What users see in the UI:**
- Rebate: Cost = £220 (from Sales_Price__c), Sales Price = £176 (from Cost__c)
- Credit: Cost = -£220 (from Cost__c), Sales Price = -£176 (from Sales_Price__c)
- Pattern: **Simple Negation** (from UI perspective)

#### Complete Mapping Table

| Charge Type | Database Field | Database Value | Formula Display Field | Display Value | What User Sees |
|-------------|----------------|----------------|-----------------------|---------------|----------------|
| **Rebate** | Cost__c | 176 | Cost_Rebate__c | 220 | Cost = £220 |
| **Rebate** | Sales_Price__c | 220 | Sales_Price_Rebate__c | 176 | Sales Price = £176 |
| **Credit on Account** | Cost__c | -220 | Cost_Rebate__c | -220 | Cost = -£220 |
| **Credit on Account** | Sales_Price__c | -176 | Sales_Price_Rebate__c | -176 | Sales Price = -£176 |

#### For Developers/Admins

When creating Credit on Account charges programmatically or via data loader:
- Database pattern: **Swap AND Negate**
- Credit.Cost__c = -(Rebate.Sales_Price__c)
- Credit.Sales_Price__c = -(Rebate.Cost__c)

When users create Credit on Account charges via UI:
- UI pattern: **Simple Negation**
- Users enter negative of what they see in formula fields
- System stores them in swapped database fields

**This is why our fix swaps the values** - to maintain database consistency!

---

## Testing Instructions

### Test Case 1: Create New Credit on Account

1. Navigate to Job [Job-000609890](https://recyclinglives.lightning.force.com/lightning/r/Job__c/a26Sj000001xRRqIAM/view)
2. Go to Job Charges related list
3. Click **New**
4. Fill in:
   - Charge Type: Credit on Account
   - Sales Account: AMEY HIGHWAYS LIMITED
   - Vendor Account: ENVA ENGLAND LIMITED
   - Sales_Price__c: -318.98
   - Cost__c: -396.78
5. Click **Save**

**Expected Result:**
- ✅ Sales_Price__c remains: -318.98
- ✅ Cost__c remains: -396.78
- ✅ Rebate__c shows: -318.98

### Test Case 2: Verify Flow Doesn't Fire

After creating the Credit on Account charge:

1. Check the debug logs (if accessible)
2. Verify `Job_Charge_Minimum_20_Gross_on_Rebate` flow did NOT execute
3. Verify field history shows no automated changes to Cost__c

### Test Case 3: Verify Rebate Charges Still Work

1. Create a new Rebate charge on a different job
2. Verify the flow DOES execute on Rebate charges with margin < 20%
3. Verify Cost__c is adjusted appropriately for Rebate charges

---

## Impact Assessment

### What Changed
- ✅ Credit on Account charges now preserve user-entered values
- ✅ Flow only runs on Rebate charges (as originally intended)
- ✅ No impact on existing working functionality

### What Didn't Change
- ✅ Rebate charge margin enforcement still works
- ✅ All other Job Charge flows unaffected
- ✅ All other Job Charge automation unchanged

### Risk Level
**LOW** - The fix removes incorrect behavior that affected only 1.08% of Credit on Account charges. No functionality was broken by this fix.

---

## Related Files

### Modified
- `force-app/main/default/flows/Job_Charge_Minimum_20_Gross_on_Rebate.flow-meta.xml`

### Backup
- `/home/john/Projects/Salesforce/Backup/2025-10-22_job_charge_credit_on_account_fix/Job_Charge_Minimum_20_Gross_on_Rebate.flow-meta.xml.ORIGINAL`

### Documentation
- `/tmp/BATCH1_CONTINUATION_NOTES.md` (if any additional notes)
- `/home/john/Projects/Salesforce/Documentation/CLAUDE_WORKFLOW_RULES.md`

---

## Lessons Learned

1. **Entry Criteria Matter:** Flows should have precise entry criteria. Using OR conditions on Charge_Type can cause unintended behavior.

2. **Hidden Bugs:** Low-frequency bugs can exist for months if they only trigger under specific rare conditions (in this case: margin < 20%).

3. **Field History is Crucial:** Field tracking helped identify that Sales_Price__c was never changed (user entry issue vs automation issue).

4. **Testing Edge Cases:** Always test automations with edge case data (low margins, high margins, zero values, etc.).

5. **Flow Naming Conventions:** The flow name "Job_Charge_Minimum_20_Gross_on_**Rebate**" clearly indicated its intent - should only run on Rebate charges.

---

## Future Recommendations

1. **Add Flow Comments:** Document why certain charge types are excluded from automation
2. **Create Test Data:** Maintain test Jobs with various margin scenarios
3. **Monitor Job Charge Creation:** Set up alerts for Credit on Account charges with positive Cost values
4. **Review Similar Flows:** Check if other flows have similar OR conditions on Charge_Type that could cause issues

---

## Contact

**Issue Reported By:** Louise Painter
**Fixed By:** John Shintu (via Claude)
**Date Resolved:** October 22, 2025

---

## Appendix: Complete Flow Analysis

### All Flows Running on Job_Charge__c

| Flow Name | Trigger Type | Runs on Credit on Account? | Updates Cost__c? | Updates Sales_Price__c? |
|-----------|--------------|---------------------------|------------------|------------------------|
| Job_Charge_Before_Save | RecordBeforeSave | Yes (all charges) | No | No |
| Job_Charge_Minimum_20_Gross_on_Rebate | RecordAfterSave | ~~Yes~~ **NO (FIXED)** | ~~Yes~~ **NO (FIXED)** | Yes (on Job, not charge) |
| Job_Charge_Minimum_Gross_Consumable_Charges | RecordAfterSave | No | No | Yes (consumable charges only) |
| Job_Charge_Populate_Customer_and_Supplier_Account_ID_s | RecordAfterSave | Yes (all charges) | No | No |
| Update_Job_Charge_Date_from_Job | RecordAfterSave (on Job__c) | N/A | No | No |
| Update_Job_Date_on_Job_Charge | RecordAfterSave | Yes (Automatic RT only) | No | No |

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-22 | John Shintu | Initial documentation of issue and fix |

---

**END OF DOCUMENTATION**
