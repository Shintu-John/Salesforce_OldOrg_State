# Quote to Order Process - Adding New Line Items to Existing Orders

**Created**: 2025-10-10
**Last Updated**: 2025-10-10
**Requested by**: Lorna Barsby
**Org**: OldOrg (Current Production)
**Status**: ✅ RESOLVED - Process Documentation
**Type**: Process Clarification / User Training

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Original Issue Report](#original-issue-report)
3. [Investigation Summary](#investigation-summary)
4. [Root Cause](#root-cause)
5. [The Correct Process](#the-correct-process)
6. [Common Mistakes to Avoid](#common-mistakes-to-avoid)
7. [Technical Details](#technical-details)
8. [Example Scenario](#example-scenario)
9. [Related Documentation](#related-documentation)

---

## Executive Summary

**Issue**: Lorna Barsby reported that a new Quote Line Item was not appearing on an Order after using the "Generate Order" process.

**Root Cause**: This was NOT a technical issue. The "Generate Order" Flow worked correctly, but the user selected the **wrong Purchase Order (PO)** when prompted by the Flow, causing the new Quote Line Item to be added to an incorrect Order.

**Resolution**:
- The missing Quote Line Item was manually added to the correct Order
- Process documentation created to clarify the correct workflow
- User training recommended to prevent future occurrences

**Key Learning**: When adding new Quote Line Items to existing Orders via the "Generate Order" button, users must carefully select the correct PO from the dropdown to ensure items are added to the intended Order.

---

## Original Issue Report

**Date Reported**: 2025-10-10
**Reported By**: Lorna Barsby (via John)
**Affected Quote**: Olive Grove Fridges (Quote #00055065)
**Quote ID**: 0Q0Sj000000b7XCKAY
**Related Order**: Order #00056747
**Order ID**: 801Sj00000K0ESaIAN

**Description**:
- Quote had 4 "Scheme WEEE Collection" Quote Line Items
- All 4 items were flagged as "Generated" on the Quote
- However, only 3 items appeared on Order #00056747
- The 4th line item (Line #00111641) was missing from the Order

**User's Process**:
1. Added new Quote Line Item to existing Quote
2. Clicked "Generate Order" button on Quote
3. Selected a PO from the dropdown
4. Proceeded through the Flow
5. Expected the new Quote Line Item to appear on the Order
6. Found that the item was NOT on the expected Order

---

## Investigation Summary

### Initial Investigation

**Queries Performed**:
- Verified Quote had 4 Quote Line Items (all "Scheme WEEE Collection")
- Verified Order had only 3 Order Products
- Checked timestamps: 4th Quote Line Item was added on 2025-10-10 at 08:29 AM by Lorna
- Original 3 Quote Line Items were created on 2025-07-14
- Order was created on 2025-07-14 (same day as original Quote Line Items)

**Timeline**:
```
2025-07-14 15:24:55 - Lines 1-3 created (Charlot Podmore-Nappin)
2025-07-14 15:25:19 - Order created from Quote
2025-07-14 15:25:23 - Order activated (3 Order Products synced)
2025-10-10 08:29:39 - Line 4 added to Quote (Lorna Barsby) ← TODAY
2025-10-10 11:26:36 - Order changed to Draft status (Charlot) ← Attempting to fix
```

### Expanded Investigation

**Scope Check**:
- Found that Lorna modified **11 Quotes** on 2025-10-10
- Checked if this was a systemic issue affecting multiple Quotes
- Analyzed Quote-to-Order sync patterns across all 11 Quotes
- Initially suspected Flow automation bug due to recent Flow modifications (Oct 7)

**Key Finding**:
- Analysis of 11 affected Quotes showed similar patterns
- However, further investigation with user clarified the actual process

### Clarification from User

**Actual Process Being Used**:
1. Add new Quote Line Item to existing Quote
2. Click **"Generate Order"** button on the Quote
3. Flow presents screen asking to **select existing PO** from dropdown
4. User selects a PO and proceeds
5. Flow should add new Quote Line Item to the selected Order

**What Went Wrong**:
- User accidentally selected the **wrong PO** from the dropdown
- The Flow successfully added the Quote Line Item to that wrong Order
- User expected it on a different Order (correct PO)

---

## Root Cause

### ✅ **NOT a Technical Bug**

The investigation initially suspected:
- Flow automation failure
- Salesforce sync issue
- Recent Flow changes causing problems

**However**, the actual cause was:

### **User Selected Wrong PO in the Flow**

When using the "Generate Order" button with existing Orders:
1. The Flow (`Quote_to_Order_Existing_PO`) asks which Order to add products to
2. If multiple Orders exist for the Account/Quote, a dropdown is shown
3. User must select the correct PO from the list
4. **If wrong PO is selected**, the Quote Line Item is added to the wrong Order

**In this case**:
- Lorna selected an incorrect PO (possibly "ES" instead of "CS" or vice versa)
- The Flow worked correctly and added the item to that Order
- The item did NOT appear on the Order Lorna was expecting

---

## The Correct Process

### Adding New Quote Line Items to Existing Orders

**Step-by-Step Process**:

#### 1. Add Quote Line Item to Quote
- Navigate to the Quote
- Click "Add Product" or use custom Quote Line Item editor
- Add the new product(s) with pricing, quantity, etc.
- Save the Quote Line Item

#### 2. Use "Generate Order" Button
- From the Quote page, click the **"Generate Order"** button
  - Location: Top-right action buttons on Quote page
  - Button Label: "Generate Order"
  - This triggers the `Quote_To_Order_New` Flow

#### 3. Select Existing PO (CRITICAL STEP)
When the Flow presents the PO selection screen:

**Screen: "Quote Details"**
- Shows existing Orders related to the Quote or Account
- Displays dropdown with available PO Numbers
- **⚠️ CRITICAL**: Verify you're selecting the CORRECT PO

**How to Identify Correct PO**:
- Check the PO Number on the Order you want to update
- Match it with the PO shown in the dropdown
- If multiple POs exist for the same Account:
  - ES (Environmental Services) POs
  - CS (Commercial Services) POs
  - Other department-specific POs
- **Double-check** before proceeding

#### 4. Select Quote Line Items
The Flow may present a screen to:
- Choose which Quote Line Items to add to the Order
- Shows available Quote Line Items that haven't been added yet
- Select the items you want to add
- Click Next/Finish

#### 5. Review and Complete
- Flow shows summary of changes
- Verify the Order Products will be added to correct Order
- Click Finish
- Flow redirects to the Order

#### 6. Verify on Order
- Navigate to the Order
- Scroll to "Order Products" related list
- Verify the new product(s) appear
- Check quantities and prices are correct

---

## Common Mistakes to Avoid

### ❌ Mistake #1: Selecting Wrong PO

**Problem**: When presented with multiple PO options, selecting the wrong one

**Impact**: Quote Line Item is added to wrong Order, customer may receive incorrect products

**Solution**:
- Always verify PO Number matches the Order you intend to update
- Keep Order record open in another tab for reference
- Ask customer/team which PO to use if uncertain

### ❌ Mistake #2: Assuming Automatic Sync

**Problem**: Adding Quote Line Item and expecting it to automatically appear on ALL related Orders

**Impact**: Confusion when item doesn't appear on expected Order

**Solution**:
- Understand that Salesforce does NOT automatically sync new Quote Line Items to existing activated Orders
- You MUST use the "Generate Order" button to add items to existing Orders
- Each Order must be updated individually

### ❌ Mistake #3: Not Checking Order Status

**Problem**: Trying to add products to Activated Orders without using the Flow

**Impact**: "Add Products" button may not be available on Activated Orders

**Solution**:
- Use "Generate Order" Flow for Activated Orders
- For Draft Orders, you can use "Add Products" button directly
- Understand the difference in workflows

### ❌ Mistake #4: Multiple Orders for Same Quote

**Problem**: Not knowing which Order should receive the new Quote Line Item

**Impact**: Adding products to wrong Order, duplicate products, customer confusion

**Solution**:
- Check with Sales team or Account Manager
- Review customer PO documentation
- Verify which Order is active for current deliveries
- Document which PO is for which service (ES vs CS)

---

## Technical Details

### Salesforce Objects Involved

**Quote** → **QuoteLineItem**
- Quote: `0Q0Sj000000b7XCKAY` (Olive Grove Fridges)
- QuoteLineItems: 4 total
  - Line 1: `0QLSj000001jk9NOAQ` (Line #00105442)
  - Line 2: `0QLSj000001jk9OOAQ` (Line #00105443)
  - Line 3: `0QLSj000001jk9POAQ` (Line #00105444)
  - Line 4: `0QLSj000002VuWDOA0` (Line #00111641) ← Missing from Order

**Order** → **OrderItem** (Order Products)
- Order: `801Sj00000K0ESaIAN` (Order #00056747)
- Original OrderItems: 3 total
  - Item 1: `802Sj00000C2oQ2IAJ` (Order Item #0000081233)
  - Item 2: `802Sj00000C2oQ3IAJ` (Order Item #0000081234)
  - Item 3: `802Sj00000C2oQ4IAJ` (Order Item #0000081235)
- Added OrderItem: `802Sj00000FGydxIAD` (Order Item #0000085532) ← Created 2025-10-10

### Flow Automation

**Flow Name**: `Quote_to_Order_Existing_PO`
**Triggered By**: "Generate Order" button on Quote page
**Last Modified**: 2025-10-07 08:46

**Flow Logic**:
1. **Get Existing Order**: Retrieves Order based on user-selected PO
2. **Get Existing Order LineItems**: Retrieves current Order Products
3. **Quote Details Screen**: User confirms/enters PO Number and PO Date
4. **Assign Order Fields**: Updates Order with PO information
5. **Get Quote Lines**: Retrieves all Quote Line Items from the Quote
6. **Choose Quote Line Items Screen**: User selects which Quote Line Items to add
7. **Loop Quote Lines**: Iterates through selected Quote Line Items
8. **Assign Order Product Fields**: Maps Quote Line Item fields to Order Product fields
9. **Create Order Products**: Inserts new Order Products
10. **Update Quote**: Marks Quote as "Order Generated"
11. **Redirect to Order**: Shows updated Order to user

### Order Status Behavior

**Draft Orders**:
- Can add products via "Add Products" button directly
- Can add products via "Generate Order" Flow
- Order can be edited freely

**Activated Orders**:
- Cannot use standard "Add Products" button
- MUST use "Generate Order" Flow to add new products
- More restrictive editing

**Why Order was in Draft**:
- Original Order was Activated on 2025-07-14
- Charlot Podmore-Nappin changed it back to Draft on 2025-10-10 at 11:26 AM
- This was an attempt to fix the missing Quote Line Item issue
- Changing to Draft allows easier manual correction

---

## Example Scenario

### Scenario: Adding Fridge Collection to Existing AMEY Order

**Background**:
- Customer: AMEY LG LIMITED
- Existing Quote: "Olive Grove Fridges" (Quote #00055065)
- Existing Order: #00056747 with PO "Olive Grove Fridges 2025"
- Current Order has 3 "Scheme WEEE Collection" items
- Need to add 1 more "Scheme WEEE Collection" item

**Process**:

**Step 1: Add to Quote**
```
Navigate to Quote: 0Q0Sj000000b7XCKAY
Click "Add Product" or "Edit Quote Line Items"
Add: Scheme WEEE Collection, Qty: 1, Price: £0
Save
```

**Step 2: Generate Order**
```
On Quote page, click "Generate Order" button
Flow launches: Quote_To_Order_New
```

**Step 3: Select Correct PO** ⚠️ **CRITICAL**
```
Flow Screen: "Quote Details"
Dropdown shows:
- "Olive Grove Fridges 2025" ← CORRECT (CS order)
- "4800066044" ← WRONG (ES order)

Select: "Olive Grove Fridges 2025"
Enter PO Date: [today's date]
Click Next
```

**Step 4: Select Quote Line Items**
```
Flow Screen: "Choose Quote Line Items"
Checkboxes show available items:
☑ Line #00111641 - Scheme WEEE Collection (Qty: 1, £0)

Click Next
```

**Step 5: Review Order Products**
```
Flow Screen: "Order Product Edit"
Shows current Order Products (editable grid):
- Order Item #0000081233 - Scheme WEEE Collection - Qty: 1
- Order Item #0000081234 - Scheme WEEE Collection - Qty: 1
- Order Item #0000081235 - Scheme WEEE Collection - Qty: 1
+ NEW: Scheme WEEE Collection - Qty: 1 ← About to be added

Click Finish
```

**Step 6: Verify**
```
Redirected to Order #00056747
Order Products section now shows 4 items:
✓ Order Item #0000081233 - Scheme WEEE Collection
✓ Order Item #0000081234 - Scheme WEEE Collection
✓ Order Item #0000081235 - Scheme WEEE Collection
✓ Order Item #0000085532 - Scheme WEEE Collection ← NEW
```

---

## Resolution Applied

### What Was Done

**Date**: 2025-10-10
**Action**: Manually created missing Order Product via Salesforce CLI

**API Command**:
```bash
sf data create record \
  --sobject OrderItem \
  --values "OrderId=801Sj00000K0ESaIAN \
            PricebookEntryId=01uSj000001wXhOIAU \
            Product2Id=01tSj000006SduDIAS \
            Quantity=1 \
            UnitPrice=0" \
  --target-org OldOrg
```

**Result**:
- ✅ Created OrderItem: `802Sj00000FGydxIAD`
- ✅ Order Item Number: 0000085532
- ✅ Product: Scheme WEEE Collection
- ✅ Quantity: 1, Price: £0
- ✅ Order #00056747 now has all 4 products matching the Quote

**Verification**:
```sql
SELECT Id, OrderItemNumber, Product2.Name, Quantity, UnitPrice, CreatedDate
FROM OrderItem
WHERE OrderId = '801Sj00000K0ESaIAN'
ORDER BY CreatedDate

Results: 4 Order Products (3 original + 1 newly added)
```

---

## Related Documentation

### Salesforce Standard Documentation
- [Quotes and Orders in Salesforce CPQ](https://help.salesforce.com/s/articleView?id=sf.cpq_quotes_orders.htm)
- [Adding Products to Orders](https://help.salesforce.com/s/articleView?id=sf.orders_add_products.htm)
- [Order Activation](https://help.salesforce.com/s/articleView?id=sf.orders_activating.htm)

### Internal Resources
- Flow: `Quote_To_Order_New` (located in Setup → Flows)
- Flow: `Quote_to_Order_Existing_PO` (subflow called by Quote_To_Order_New)
- Custom Button: "Generate Order" on Quote object
- WebLink: `Generate_Order` (force-app/main/default/objects/Quote/webLinks/)

### Related Files
- `/force-app/main/default/flows/Quote_To_Order_New.flow-meta.xml`
- `/force-app/main/default/flows/Quote_to_Order_Existing_PO.flow-meta.xml`
- `/force-app/main/default/objects/Quote/webLinks/Generate_Order.webLink-meta.xml`

---

## Recommendations

### For Users

1. **Always verify PO selection** before proceeding in the Generate Order Flow
2. **Keep Order record open** in another tab when adding Quote Line Items
3. **Document which PO is for which service** (ES vs CS) at Account level
4. **Double-check Order after Flow completes** to verify products were added
5. **Ask for help** if uncertain which PO to select

### For Administrators

1. **Consider adding PO Type field** to Order object (ES, CS, etc.) for easier identification
2. **Enhance Flow screen** to show more Order context (Status, Product count, Created Date)
3. **Add validation** to warn if user is about to add duplicate products
4. **Create training materials** on the Generate Order process
5. **Consider custom screen flow** that shows side-by-side comparison of Quote vs Order

### For Training

1. Document this process in user training materials
2. Create screen recording of correct Generate Order process
3. Include common mistakes in training
4. Set up practice environment for users to test
5. Schedule refresher training sessions

---

## Appendix A: Verification Queries

### Check Quote Line Items
```sql
SELECT Id, LineNumber, Product2.Name, Quantity, UnitPrice, CreatedDate, CreatedBy.Name
FROM QuoteLineItem
WHERE QuoteId = '0Q0Sj000000b7XCKAY'
ORDER BY CreatedDate
```

### Check Order Products
```sql
SELECT Id, OrderItemNumber, Product2.Name, Quantity, UnitPrice, CreatedDate
FROM OrderItem
WHERE OrderId = '801Sj00000K0ESaIAN'
ORDER BY CreatedDate
```

### Check Order Status and History
```sql
SELECT Id, OrderNumber, Status, ActivatedDate,
       LastModifiedDate, LastModifiedBy.Name
FROM Order
WHERE Id = '801Sj00000K0ESaIAN'
```

### Check All Orders for Quote
```sql
SELECT Id, OrderNumber, PoNumber, Status, CreatedDate
FROM Order
WHERE QuoteId = '0Q0Sj000000b7XCKAY'
ORDER BY CreatedDate
```

---

## Appendix B: Flow Decision Points

### Key Decision in Quote_to_Order_Existing_PO Flow

**Decision: "Order_Product_List_Empty"**
- Checks if any Order Products were created
- If Empty: Shows error
- If Not Empty: Proceeds to create Order Products

**Decision: "IsQuoteAvailableOnOrder"**
- Checks if Quote is already linked to Order
- If Yes: Proceeds with adding products
- If No: Loops to next Quote Line Item

**Decision: "Max_Item_provided"**
- Checks if Order has Max Items limit set
- If Yes: Validates against limit
- If No: Proceeds without validation

---

## Version History

- **v1.0** (2025-10-10): Initial documentation created after incident investigation and resolution

---

**Status**: ✅ RESOLVED - Process Clarification
**Next Review**: 2025-11-10 (1 month)
**Owner**: John (Salesforce Admin)
**Last Verified**: 2025-10-10
