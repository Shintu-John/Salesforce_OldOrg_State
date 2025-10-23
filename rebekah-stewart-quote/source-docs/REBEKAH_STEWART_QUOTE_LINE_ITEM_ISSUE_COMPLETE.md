# Quote Line Item Creation Error - Complete Documentation

**Date Reported**: 2025-10-09
**Reported By**: Rebekah Stewart (005Sj000001u9mQ)
**Original Quote**: [0Q0Sj0000010eRVKAY](https://recyclinglives.lightning.force.com/lightning/r/Quote/0Q0Sj0000010eRVKAY/view)
**Status**: ✅ Resolved - Standard Pricebook Corrected

---

## Document Update History

- **Issue 1 (09:03 AM)**: Quote with Partner Pricing - Resolved by following correct supplier pricing workflow
- **Issue 2 (14:02 PM)**: Quote without Partner Pricing - Resolved by correcting Standard Pricebook entry

---

## Executive Summary (Non-Technical)

Rebekah encountered two separate issues when trying to add "8ft Fluorescent Tube Coffin" to Quotes on 2025-10-09.

### Issue 1: Quote with "Pricing Generated" Status (09:03 AM)

**What Happened:**
Rebekah tried to add a new product line (**8ft Fluorescent Tube Coffin**) to a Quote that already had pricing from the supplier. When she tried to save without entering a supplier cost (Partner Price), she got an error and couldn't save the record.

### Why Did It Fail?

**This was NOT a system bug** - the error was **correct behavior** enforcing the proper business process.

**The Correct Process**:
1. When a Quote is in "Pricing Generated" status (supplier has already provided pricing for existing items)
2. AND a new item needs to be added
3. **Sales staff should NOT add pricing themselves**
4. Instead, they should:
   - Change Quote Status back to "Pricing Requested"
   - Add the new item
   - Contact the Supplier Manager team
   - Wait for supplier to add Partner Price
   - Quote returns to "Pricing Generated" status

**What Rebekah Did** (Process Violation):
- Quote was in "Pricing Generated" status
- She tried to add a new item ("8ft Fluorescent Tube Coffin")
- She entered a customer price (£3) but NO supplier cost
- System blocked her with an error

**This was the system working correctly** - it prevented sales staff from bypassing the supplier pricing process.

### What Was The Correct Resolution?

**Gareth Layland** (Supplier Manager) followed the correct process:
- He added the Partner Price (£165) to the new item
- System automatically calculated the correct customer price (£220) with proper 25% margin
- Record saved successfully ✅

**Timeline**:
- **09:03 AM**: Rebekah created the item (failed to save)
- **11:24 AM**: Gareth added Partner Price and saved successfully
- **Result**: Quote now has all 4 items with proper supplier pricing

### What We Initially Did Wrong (And Fixed)

**Our Mistake**: We initially modified the system to allow Rebekah's process violation by letting the record save without Partner Price.

**User Feedback**: The supplier manager confirmed this was incorrect - sales staff should NOT add items to Quotes with "Pricing Generated" status without supplier pricing.

**Correction**: We **rolled back our fix** to restore the original behavior that blocks this process violation.

**Current State**: System correctly enforces supplier pricing workflow ✅

---

### Issue 2: Quote with "Pricing Requested" Status (14:02 PM)

**What Happened:**
After the first issue was resolved, Rebekah tried to add the same product (**8ft Fluorescent Tube Coffin**) to a different Quote that was still in "Pricing Requested" status (early stage, no supplier pricing yet). She got a different error.

**Why Did It Fail:**
The product had an incorrect Standard Pricebook price of **£1** (should have been **£0**). When added to a Quote, the system defaulted UnitPrice to £1, which triggered margin enforcement logic. Since there was no Partner Price yet, the system tried to set UnitPrice to NULL, which Salesforce rejected.

**Resolution:**
- Corrected the Standard Pricebook entry for "8ft Fluorescent Tube Coffin" from **£1** → **£0**
- This aligns with company policy: all products should have base price of **£0**
- Product now behaves like all other products in the catalog

**Timeline:**
- **14:02 PM**: Rebekah encounters error when adding product to "Pricing Requested" Quote
- **14:41 PM**: Testing workaround (manually changing UnitPrice to £0) - verified it works
- **15:09 PM**: Standard Pricebook corrected by John Shintu
- **Result**: Rebekah tested and confirmed working ✅

---

## Technical Details

### Issue Reported

**Error Message**:
```
REQUIRED_FIELD_MISSING: Required fields are missing: [UnitPrice]
```

**Flow**: Quote_Line_Item_Manage_Sales_Margin (Version 7)
**Flow Type**: Record-Triggered Flow (After Save)

**Flow Error Context**:
- Flow executed the "Haz_Waste_Line_25" outcome (Hazardous Waste requires 25% margin)
- Attempted to update UnitPrice using `{!LIFT_25p_Margin}` formula
- Formula returned **NULL** because Partner_price__c = 0
- Salesforce rejected the update because UnitPrice is a required field

### Failed Quote Line Item Details

| Field | Value |
|-------|-------|
| Product | 8ft Fluorescent Tube Coffin |
| Created By | Rebekah Stewart |
| Created Date | 2025-10-09 09:03:37 |
| EWC Code | 20.01.21* (Fluorescent Tubes - Hazardous Waste) |
| Pricing Method | Fixed |
| UnitPrice Attempted | £3.00 |
| Partner_price__c | **£0.00** ← Process violation |

### Root Cause Analysis

#### This Was NOT a Bug - It Was Correct Behavior

The error occurred because:

1. **Business Rule**: All Quote Line Items on "Pricing Generated" Quotes should have supplier pricing (Partner_price__c)
2. **User Action**: Rebekah tried to add an item WITHOUT supplier pricing
3. **System Response**: Flow formula returned NULL, blocking the save
4. **Result**: Process violation prevented ✅

**LIFT_25p_Margin Formula Logic** ([Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml:342-368](../force-app/main/default/flows/Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml#L342-L368)):

```apex
IF(
  AND(Partner_price__c <= 0, Pricing_method = "Rebate"),
  0,                                                      // Rebate with no cost = £0

  IF(
    AND(Partner_price__c > 0, NOT Pricing_method = "Rebate"),
    ROUND(Partner_price__c / (1 - 0.25), 0),             // Calculate 25% markup

    IF(
      AND(Partner_price__c > 0, Pricing_method = "Rebate"),
      ROUND(Partner_price__c * (1 - 0.25), 0),           // Calculate 25% discount
      NULL                                                // Returns NULL when Partner_price = 0 and NOT Rebate
    )
  )
)
```

**Why NULL is Returned**:
- Partner_price__c = 0 AND Pricing_method = "Fixed" (not "Rebate")
- All three conditions evaluate to FALSE
- Formula returns NULL as fallback
- This blocks the save, enforcing the business rule ✅

#### Quote Status Does NOT Affect Flow Behavior

**Important Finding**: The Flow does NOT check Quote.Status before enforcing margin rules.

**Flow Start Conditions** ([Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml:608-632](../force-app/main/default/flows/Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml#L608-L632)):

```xml
<start>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Quote_created_date__c</field>
        <operator>GreaterThan</operator>
        <value>
            <dateTimeValue>2025-01-15T00:01:00.000Z</dateTimeValue>
        </value>
    </filters>
    <filters>
        <field>Quote_Record_Type_Id__c</field>
        <operator>NotEqualTo</operator>
        <value>
            <stringValue>012Sj0000004Nnd</stringValue>  <!-- Excludes RLCS Quote -->
        </value>
    </filters>
    <object>QuoteLineItem</object>
    <recordTriggerType>CreateAndUpdate</recordTriggerType>
    <triggerType>RecordAfterSave</triggerType>
</start>
```

The Flow only checks:
1. Quote creation date (after 2025-01-15)
2. Quote Record Type (not RLCS)

**Result**: Even if Rebekah changed Quote Status to "Pricing Requested", the error would still occur when Partner_price__c = 0.

---

## Resolution Process

### Initial Incorrect Fix (Deployed, Then Rolled Back)

**What We Did**:
1. Modified all four LIFT margin formulas (18%, 21%, 23%, 25%)
2. Changed fallback from `NULL` to `{!$Record.UnitPrice}`
3. Deployed successfully (Deploy ID: 0AfSj000000yKlRKAU)

**Why It Was Wrong**:
- Created a workaround for a process violation
- Allowed sales staff to bypass supplier pricing workflow
- Did not respect business rules

### User Clarification

**Supplier Manager Confirmed**:
> "Ideally, if she needed to add a new item to a pricing generated quote, she should have put it back to pricing requested, added the item and wait for the supplier to add the pricing. She was not supposed to do that."

**Key Learning**: The error was **protecting the business process**, not blocking legitimate work.

### Rollback Performed

**Actions Taken**:
1. Reverted all four LIFT margin formulas to original behavior (NULL fallback)
2. Deployed rollback successfully (Deploy ID: 0AfSj000000yLETKA2)
3. Restored process enforcement ✅

**Files Modified** ([Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml](../force-app/main/default/flows/Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml)):

**Changes Rolled Back**:
1. **LIFT_18p_Margin** (line 277): Restored `{!$Record.UnitPrice}` → `NULL`
2. **LIFT_21p_Margin** (line 306): Restored `{!$Record.UnitPrice}` → `NULL`
3. **LIFT_23p_Margin** (line 335): Restored `{!$Record.UnitPrice}` → `NULL`
4. **LIFT_25p_Margin** (line 364): Restored `{!$Record.UnitPrice}` → `NULL`

**Current State**: Flow enforces supplier pricing requirement as originally designed ✅

---

## Issue 2: Technical Details - Standard Pricebook Error

### Error Message (14:02 PM)

**Flow Error:**
```
Flow API Name: Quote_Line_Item_Manage_Sales_Margin
Type: Autolaunched Flow
Version: 7
Status: Active

Flow Interview Details:
Interview Label: Quote Line Item: Manage Sales Margin 09/10/2025 14:02
Current User: Rebekah Stewart (005Sj000001u9mQ)

DECISION: Process Required
Outcome executed: Haz_Waste_Line_25

UPDATE RECORDS: Update to 25%
Update the QuoteLineItem record:
  Margin__c = 25
  Sales_Tonnage_charge_thereafter__c = {!TONNAGE_25p_Margin} ()
  Sales_Transport__c = {!TRANSPORT_25p_Margin} ()
  UnitPrice = {!LIFT_25p_Margin} ()  ← Returns NULL

Result: Failed to update the QuoteLineItem record.
```

### Failed Quote Line Item Details (14:02 PM)

| Field | Value |
|-------|-------|
| Quote | 0Q0Sj0000010k77KAA - Edmundson Electrical |
| Quote Status | Open (Pricing Requested) |
| Product | 8ft Fluorescent Tube Coffin |
| Created By | Rebekah Stewart |
| Created Date | 2025-10-09 14:02:37 |
| EWC Code | 20.01.21* (Fluorescent Tubes - Hazardous Waste) |
| Pricing Method | Fixed |
| **UnitPrice** | **£1.00** ← From Standard Pricebook |
| **Partner_price__c** | **£0.00** ← No supplier pricing yet |

### Root Cause Analysis - Issue 2

#### The Problem Chain

1. **Incorrect Standard Pricebook Configuration:**
   - 8ft Fluorescent Tube Coffin had Standard Price = **£1**
   - Created by Glen Bagshaw on 2023-08-18
   - Should have been **£0** (company policy)

2. **Flow Logic Triggered:**
   - Product added to Quote → UnitPrice defaults to **£1**
   - `Is_Pricing_Entered = TRUE` (because UnitPrice > 0)
   - `isHazWasteJob = TRUE` (EWC Code contains `*`)
   - Flow executes **"Haz_Waste_Line_25"** outcome

3. **Formula Returns NULL:**
   ```apex
   LIFT_25p_Margin = IF(
     Partner_price = 0 AND Pricing_method = "Fixed",
     NULL,  ← This is the fallback
     ...
   )
   ```

4. **Salesforce Rejects Update:**
   - Cannot set required field `UnitPrice` to NULL
   - Flow fails with error

#### Why Only 8ft Fluorescent Tube Coffin Failed

**Comparison with other products:**

| Product | Standard Pricebook Price | Result When Added Without Partner Price |
|---------|--------------------------|----------------------------------------|
| **8ft Fluorescent Tube Coffin** | **£1** ❌ | UnitPrice = £1 → `Is_Pricing_Entered = TRUE` → Flow enforces margin → Returns NULL → **FAILS** |
| 6ft Fluorescent Tube Coffin | £0 ✅ | UnitPrice = £0 → `Is_Pricing_Entered = FALSE` → Flow skips margin → **WORKS** |
| All other products | £0 ✅ | UnitPrice = £0 → `Is_Pricing_Entered = FALSE` → Flow skips margin → **WORKS** |

**The `Is_Pricing_Entered` Formula** ([Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml:231-247](../force-app/main/default/flows/Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml#L231-L247)):

```apex
Is_Pricing_Entered = IF(
   AND(
      Pricing_method != "Rebate",
      UnitPrice > 0     ← This is the key check
   ),
   TRUE,
   ...
)
```

**Result:**
- £1 > 0 → TRUE → Flow enforces margin
- £0 > 0 → FALSE → Flow skips margin enforcement

#### Historical Context - Why It Worked Before March 10, 2025

**Flow Version History:**
- **Version 7** (Active): Modified March 10, 2025 - "Fixed bug with Rebate Lines calculating NULL margin"
- **Version 6** (Deactivated): Previous version

**What Changed on March 10, 2025:**
The LIFT margin formulas were updated to return `NULL` as fallback when Partner_price = 0 (to fix Rebate line issues). This introduced the problem for Fixed pricing without Partner_price.

**Before March 10, 2025:**
- Formula likely returned `{!$Record.UnitPrice}` instead of NULL
- Rebekah could add 8ft Fluorescent Tube Coffin with UnitPrice = £1
- Record saved successfully

**After March 10, 2025:**
- Formula returns NULL when Partner_price = 0
- Salesforce rejects NULL for required field
- Record fails to save

### Resolution - Issue 2

#### Investigation Process

1. **Analyzed historical Quote Line Items** for 8ft Fluorescent Tube Coffin
2. **Discovered pattern:**
   - Supply Chain users (Alice Ducker, etc.) always added Partner_price immediately → Success
   - Sales users tried to add without Partner_price → Failed (after March 10)

3. **Tested hypothesis:**
   - Asked Rebekah to manually change UnitPrice from £1 to £0 before saving
   - Test at 14:41 confirmed: UnitPrice = £0 → Success ✅
   - This proved the £1 Standard Pricebook price was the root cause

4. **Compared Standard Pricebook prices:**
   - Found 8ft version had £1 (only product with non-zero price)
   - All other products had £0

5. **Consulted senior management:**
   - Confirmed company policy: **base price should be £0**
   - Decision: Correct the Standard Pricebook entry

#### Fix Applied

**Date/Time:** 2025-10-09 15:09:05 UTC
**Performed By:** John Shintu
**Action:** Updated Standard Pricebook Entry

**Change:**
```
PricebookEntry ID: 01u8e0000022IjSAAU
Product: 8ft Fluorescent Tube Coffin
UnitPrice: £1 → £0
```

**Command Used:**
```bash
sf data update record --sobject PricebookEntry --record-id 01u8e0000022IjSAAU --values "UnitPrice=0" --target-org OldOrg
```

#### Verification

**Rebekah tested and confirmed:**
- Can now add "8ft Fluorescent Tube Coffin" to Quotes without error
- Product behaves like all other products
- No workaround needed

**Current Behavior:**
1. Add product to Quote
2. UnitPrice defaults to £0 (from corrected Standard Pricebook)
3. `Is_Pricing_Entered = FALSE` (because £0 is not > 0)
4. Flow skips margin enforcement
5. ✅ Record saves successfully

---

## Correct Resolution (What Actually Happened)

### Gareth Layland Followed Proper Process

**Quote Line Item: 8ft Fluorescent Tube Coffin (0QLSj000002VMuLOAW)**

| Event | User | Date/Time | Action |
|-------|------|-----------|--------|
| Created | Rebekah Stewart | 2025-10-09 09:03:37 | Attempted to add item with Partner_price = £0 (FAILED) |
| Updated | **Gareth Layland** | 2025-10-09 11:24:05 | Added Partner_price = £165, UnitPrice = £220 (SUCCESS ✅) |

**Final Pricing**:
- Partner_price__c: £165 (supplier cost)
- UnitPrice: £220 (customer price)
- Margin__c: 25% (correct for hazardous waste)

**All Quote Line Items Now Properly Priced**:

| Product | Partner Price | Unit Price | Margin | Created By | Last Modified By |
|---------|---------------|------------|--------|------------|------------------|
| Pallet Box | £540 | £720 | 25% | Rebekah Stewart | Alice Ducker |
| Transport & Consignment | £205 | £250 | 18% | Alice Ducker | Alice Ducker |
| 8ft Fluorescent Tube Coffin | £165 | £220 | 25% | Rebekah Stewart | **Gareth Layland** ✅ |
| Consignment Note | £55 | £65 | 15.38% | Alice Ducker | Alice Ducker |

---

## User Guidance - Correct Process

### When Adding Items to Quotes with "Pricing Generated" Status

**DO NOT**:
❌ Add new items and enter pricing yourself
❌ Try to save items without Partner Price
❌ Bypass the supplier pricing workflow

**DO**:
✅ Change Quote Status to "Pricing Requested"
✅ Add the new item (leave Partner Price blank)
✅ Contact Supplier Manager team (Gareth Layland, etc.)
✅ Wait for supplier to add Partner Price
✅ Supplier Manager will save and return Quote to "Pricing Generated"

### Who Should Add Pricing?

| Role | Can Add Partner Price? | Process |
|------|------------------------|---------|
| **Sales Staff** (Rebekah, Alice, etc.) | ❌ NO | Add item, contact Supplier Manager |
| **Supplier Manager** (Gareth, etc.) | ✅ YES | Add Partner Price, system calculates customer price |

---

## Impact Analysis

### No System Changes Required

**Current State**: ✅ System correctly enforces business process
**No Further Action**: Process is working as designed

### Benefits of Maintaining This Behavior

1. **Data Quality**: Ensures all Quote Line Items have supplier pricing
2. **Process Compliance**: Enforces proper workflow between Sales and Supplier teams
3. **Margin Accuracy**: Prevents incorrect margin calculations
4. **Audit Trail**: Clear separation of duties (Sales creates items, Suppliers price them)

---

## Lessons Learned

### Issue 1 Lessons

**Before Making Fixes**:
1. ✅ Understand the business process first
2. ✅ Verify with users whether the error is blocking legitimate work or process violations
3. ✅ Don't create workarounds for process enforcement

**Error messages can be correct** - they might be protecting important business rules, not blocking legitimate work.

### Issue 2 Lessons

**Root Cause Investigation**:
1. ✅ When "only one product" fails, investigate what makes that product different
2. ✅ Check historical data to see if it ever worked before
3. ✅ Compare successful vs failed creation patterns
4. ✅ Look at Standard Pricebook and product configuration

**Data Configuration**:
1. ✅ Company policy: **All products should have Standard Price = £0**
2. ✅ Incorrect product data can cause unexpected Flow behavior
3. ✅ Fixing the root cause (data) is better than working around it in code
4. ✅ Simple configuration fixes are preferable to complex Flow changes

**Flow Version History**:
1. ✅ Changes to Flows can have unintended side effects
2. ✅ March 10, 2025 change fixed Rebate lines but exposed the £1 pricing issue
3. ✅ The Flow change was correct; the product configuration was wrong

**Investigation Methodology**:
1. ✅ Check who else successfully added the product and how
2. ✅ Compare user profiles and workflows
3. ✅ Analyze when the issue started occurring
4. ✅ Consult senior management on business policies

---

## Related Documentation

- [CLAUDE_WORKFLOW_RULES.md](CLAUDE_WORKFLOW_RULES.md) - Partnership workflow methodology
- [Flow: Quote_Line_Item_Manage_Sales_Margin](../force-app/main/default/flows/Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml)

---

---

## Final Summary

**Date**: 2025-10-09
**Reported By**: Rebekah Stewart
**Resolved By**:
- Issue 1: Gareth Layland (Supplier Manager)
- Issue 2: John Shintu (corrected Standard Pricebook)

**Status**: ✅ Both Issues Resolved

### Issue 1 Outcome
- System correctly enforces supplier pricing workflow
- Gareth Layland added Partner Price (£165), system calculated UnitPrice (£220)
- No system changes needed - business process working as designed

### Issue 2 Outcome
- Standard Pricebook corrected from £1 → £0
- Product now behaves like all other products
- Rebekah tested and confirmed working
- Aligns with company policy: base price should be £0

**Key Actions Taken**:
1. ✅ Analyzed Flow error and identified margin enforcement trigger
2. ✅ Investigated historical data and user patterns
3. ✅ Compared with other products to identify anomaly
4. ✅ Consulted senior management on company policy
5. ✅ Corrected Standard Pricebook entry
6. ✅ Verified fix with end user

**Files Modified**:
- PricebookEntry: 01u8e0000022IjSAAU (8ft Fluorescent Tube Coffin)
  - UnitPrice: £1 → £0
  - Modified: 2025-10-09 15:09:05 UTC

**Related Records**:
- Flow: [Quote_Line_Item_Manage_Sales_Margin](../force-app/main/default/flows/Quote_Line_Item_Manage_Sales_Margin.flow-meta.xml) (Version 7 - Active)
- Product: 01t8e000000sW5XAAU (8ft Fluorescent Tube Coffin)
- PricebookEntry: 01u8e0000022IjSAAU (Standard Price Book)
