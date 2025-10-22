# Quote to Order Process - User Training Documentation (OldOrg)

⚠️ **SCENARIO TYPE: PROCESS DOCUMENTATION/USER TRAINING - NOT A DEPLOYMENT SCENARIO**

## ⚠️ Important: This is Process Documentation Only

**What This Document Is**:
- User training documentation for Quote-to-Order process
- Troubleshooting guide for common user errors
- Process clarification for adding new line items to existing Orders
- Step-by-step guide for using "Generate Order" button correctly

**What This Is NOT**:
- NOT new code deployment
- NOT a bug fix implementation
- NOT system changes or enhancements

**Issue Type**: User error - Selected wrong Purchase Order in Flow dropdown

---

## Executive Summary

### Reported Issue

**Date**: October 10, 2025
**Reporter**: Lorna Barsby
**Affected Quote**: Olive Grove Fridges (Quote #00055065)
**Problem Description**: "New Quote Line Item was not appearing on Order after using Generate Order process"

### Root Cause

**NOT a technical issue** - User selected the wrong Purchase Order (PO) when prompted by the Flow.

**What Happened**:
1. User added new Quote Line Item to existing Quote (4th line item)
2. User clicked "Generate Order" button
3. Flow presented dropdown asking which PO to add items to
4. User accidentally selected **wrong PO** from dropdown
5. Flow successfully added Quote Line Item to that incorrect Order
6. User expected item on different Order (correct PO)

### Resolution

**Immediate Fix**: Manually added the missing Quote Line Item to correct Order

**Long-term Solution**: User training on proper PO selection process

---

## Problem Details

### Quote Information

- **Quote ID**: 0Q0Sj000000b7XCKAY
- **Quote Number**: 00055065
- **Account**: Olive Grove (Sheffield City Council)
- **Quote Line Items**: 4 total (all "Scheme WEEE Collection")

### Quote Line Items Timeline

| Line # | Created Date | Created By | Status |
|--------|--------------|------------|--------|
| 1 | 2025-07-14 15:24:55 | Charlot Podmore-Nappin | Generated ✅ |
| 2 | 2025-07-14 15:24:55 | Charlot Podmore-Nappin | Generated ✅ |
| 3 | 2025-07-14 15:24:55 | Charlot Podmore-Nappin | Generated ✅ |
| **4** | **2025-10-10 08:29:39** | **Lorna Barsby** | **Generated ✅** |

### Order Information

- **Order ID**: 801Sj00000K0ESaIAN
- **Order Number**: 00056747
- **Created**: 2025-07-14 15:25:19 (same day as first 3 Quote Line Items)
- **Order Products**: Only 3 items (missing the 4th)

### What User Expected

User expected all 4 Quote Line Items (including the newly added one) to appear on Order #00056747.

### What Actually Happened

Line #4 was successfully added to a **different Order** because user selected wrong PO in Flow dropdown.

---

## Root Cause Analysis

### Investigation Steps

1. **Initial Suspicion**: Flow automation bug (recent Flow modifications on Oct 7)
2. **Expanded Investigation**: Checked 11 Quotes modified by Lorna on Oct 10
3. **Pattern Analysis**: Similar patterns across multiple Quotes
4. **User Clarification**: Confirmed actual process being used

### User's Process (Actual)

1. Add new Quote Line Item to existing Quote ✅
2. Click **"Generate Order"** button on Quote ✅
3. Flow presents screen: **"Select existing PO"** dropdown
4. User selects a PO from dropdown **← WRONG PO SELECTED**
5. Flow proceeds and adds Quote Line Item to selected Order ✅
6. User looks at different Order expecting to see new item ❌

### Why It Failed

**User Error**: Selected incorrect PO from dropdown when multiple POs exist for the Account.

**Common Scenario**: Account has multiple Purchase Orders:
- ES (Environmental Services) POs
- CS (Commercial Services) POs
- Other department-specific POs

**User must carefully verify** correct PO selected before proceeding.

---

## The Correct Process

### Step-by-Step Guide: Adding Quote Line Items to Existing Orders

#### Step 1: Add Quote Line Item to Quote

1. Navigate to Quote record
2. Click "Add Product" or use custom Quote Line Item editor
3. Add new product(s) with pricing, quantity, etc.
4. **Save** the Quote Line Item

#### Step 2: Use "Generate Order" Button

1. From Quote page, click **"Generate Order"** button
   - Location: Top-right action buttons on Quote page
   - This triggers the `Quote_To_Order_New` Flow

#### Step 3: Select Existing PO (⚠️ CRITICAL STEP)

**Flow Screen: "Quote Details"**

Shows existing Orders related to Quote or Account with dropdown of available PO Numbers.

**⚠️ CRITICAL**: Verify you're selecting the CORRECT PO

**How to Identify Correct PO**:
1. Check the PO Number on the Order you want to update
2. Match it with the PO shown in the dropdown
3. If multiple POs exist for same Account:
   - ES (Environmental Services) POs
   - CS (Commercial Services) POs
   - Other department-specific POs
4. **Double-check** before proceeding

**Example**:
```
Dropdown Options:
- PO-001234 (ES - Environmental Services)
- PO-005678 (CS - Commercial Services)  ← User needs THIS one
- PO-009876 (LS - Logistics)

User must select: PO-005678
```

#### Step 4: Select Quote Line Items

Flow may present screen to:
- Choose which Quote Line Items to add to Order
- Shows available Quote Line Items not yet added
- Select items you want to add
- Click Next/Finish

#### Step 5: Review and Complete

1. Flow shows summary of changes
2. Verify Order Products will be added to **correct Order**
3. Click Finish
4. Flow redirects to Order

#### Step 6: Verify on Order

1. Navigate to Order record
2. Scroll to "Order Products" related list
3. **Verify** new product(s) appear
4. Check quantities and prices are correct

---

## Common Mistakes to Avoid

### ❌ Mistake #1: Selecting Wrong PO

**Problem**: Multiple PO options, selected incorrect one

**How to Avoid**:
1. Write down or remember the correct PO Number BEFORE clicking "Generate Order"
2. Match PO Number exactly in dropdown
3. If unsure, cancel Flow and verify PO Number first
4. Double-check PO Number before clicking Next

**Recovery**: If wrong PO selected, manually move Order Products to correct Order

### ❌ Mistake #2: Not Verifying After Completion

**Problem**: Assume Flow worked correctly without checking

**How to Avoid**:
1. Always navigate to Order after Flow completes
2. Verify new products appear in Order Products list
3. Check quantities match Quote Line Items
4. Verify prices are correct

**Recovery**: If items missing, check other Orders for same Account

### ❌ Mistake #3: Confusing ES vs CS POs

**Problem**: Similar PO numbers, different departments

**How to Avoid**:
1. Note the department prefix (ES, CS, LS, etc.)
2. Verify Account department matches Order department
3. Consult with team if unsure which PO to use

**Recovery**: Contact supervisor if unsure which PO should be used

---

## Flow Behavior (Technical Details)

### Quote_To_Order_New Flow

**Flow Name**: Quote_To_Order_New
**Type**: Screen Flow
**Triggered By**: "Generate Order" button on Quote page

**Flow Logic**:
1. Query existing Orders for Quote's Account
2. Present dropdown with available PO Numbers
3. User selects PO
4. Query available Quote Line Items (not yet "Generated")
5. User selects which Quote Line Items to add
6. Create Order Products from selected Quote Line Items
7. Mark Quote Line Items as "Generated"
8. Redirect to Order

**Key Point**: Flow adds items to **whichever Order the user selects** - it's user's responsibility to select correct PO.

---

## Training Recommendations

### For Sales Representatives

**Before Using "Generate Order"**:
1. Know which Order you want to update (have PO Number ready)
2. Understand Account's PO structure (ES vs CS vs other)
3. If unsure, ask supervisor which PO to use

**During Flow**:
1. Carefully read PO dropdown options
2. Match PO Number exactly
3. Don't rush - take time to verify
4. If dropdown unclear, cancel and verify first

**After Flow**:
1. Navigate to Order
2. Verify products added successfully
3. Report any issues immediately

### For Supervisors

**Provide**:
1. Clear guidance on when to use ES vs CS POs
2. Account-specific PO rules (if any)
3. Troubleshooting contact for issues

**Monitor**:
1. New users during first few uses
2. Accounts with complex PO structures
3. Common error patterns

---

## Resolution Applied (Oct 10, 2025)

### For Quote #00055065

**Issue**: Line Item #00111641 missing from Order #00056747

**Action Taken**: Manually added Quote Line Item to correct Order

**How**:
1. Navigated to Order #00056747
2. Clicked "Add Products"
3. Selected matching product from Quote Line Item #4
4. Added to Order Products
5. Verified quantities and pricing match Quote

**Status**: ✅ Resolved

---

## Related Components (No Changes Made)

### Flows (Unchanged)

- Quote_To_Order_New (existing functionality, no modifications)
- Quote_Process_1 (not involved in this issue)

### Quote/Order Objects (Unchanged)

- Quote__c (standard object)
- Order (standard object)
- QuoteLine__c (custom object)
- OrderProduct (standard object)

**No Code Changes Required**: This was user training issue, not system bug.

---

## Verification Evidence

### Quote Line Item Status

All 4 Quote Line Items correctly marked as "Generated":

```
Line #1: Generated = TRUE
Line #2: Generated = TRUE
Line #3: Generated = TRUE
Line #4: Generated = TRUE (added manually after issue resolved)
```

### Order Products Verification

Order #00056747 now has 4 Order Products matching all 4 Quote Line Items.

### Flow Logs

No errors in Flow Interview logs - Flow functioned correctly, user selected wrong PO.

---

## Related Documentation

**Primary Source**: `/home/john/Projects/Salesforce/Documentation/QUOTE_TO_ORDER_PROCESS_ADDING_NEW_LINE_ITEMS.md`

**Issue Type**: User training / process clarification

**No Related Deployments**: No code changes required

---

**Document Version**: 1.0
**Last Updated**: October 22, 2025
**Maintained By**: Migration Team
