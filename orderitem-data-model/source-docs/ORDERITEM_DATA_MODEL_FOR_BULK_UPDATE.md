# OrderItem Data Model - For Your Bulk Update

**Created**: 2025-10-13
**Purpose**: Understanding Salesforce objects and relationships for bulk transport price updates

---

## 🎯 Answer to Your Question

### **What is the Salesforce Object?**
**`OrderItem`** (also called "Order Product" in the UI)

### **What is the Relationship?**
OrderItem has a **Master-Detail relationship** to Order

### **What is the Related Object?**
**`Order`** (parent object)

### **What is the Lookup Field?**
**`OrderId`** (links OrderItem to its parent Order)

### **In Your Case:**
- **Primary Object**: `OrderItem` (what you're updating)
- **Unique Identifier**: `Id` (the 18-char Order Product ID in column 20 of your CSV)
- **Parent Object**: `Order` (contains order-level info like Order Number)
- **Operation**: **UPDATE** (modifying existing OrderItem records)

---

## Data Model Hierarchy

```
Account (Customer)
  ↓ (has many)
Order
  ↓ (has many)
OrderItem ← YOU ARE UPDATING THIS
  ↓ (can have many)
Job__c (jobs created from this Order Product)
```

---

## Your CSV Structure Mapped to Salesforce

### CSV File Structure (What You Have)

```
Column 1:  Account Name → Info only (OrderItem is already linked to Account via Order)
Column 2:  Site → Info only
Column 3:  Haulier → Reference data
Column 4:  Supplier Name → Reference data
Column 17: Order Number → Parent Order identifier
Column 18: Order ID → Parent Order Salesforce ID
Column 19: Order Product Number → OrderItem.OrderItemNumber (10-digit)
Column 20: Order Product ID → OrderItem.Id (18-char) ← THIS IS YOUR KEY!
```

### Salesforce Object: OrderItem

**API Name**: `OrderItem`
**Label**: Order Product
**Type**: Standard object with custom fields

---

## Key OrderItem Fields for Your Update

| Your CSV Column | CSV Header | OrderItem Field API Name | Field Type | Notes |
|-----------------|------------|-------------------------|------------|-------|
| **20** | Order Product ID | **Id** | ID (18-char) | **Primary Key - DO NOT UPDATE THIS!** |
| 19 | Order Product Number | OrderItemNumber | Auto-Number | Read-only, system managed |
| 6 | Pricing method | Pricing_method__c | Picklist | Variable, Rebate, Fixed |
| 7 | Transport | Transport__c | Currency | Supplier transport cost |
| 8 | Transport Per Unit | Transport_Per_Unit__c | Checkbox | TRUE/FALSE |
| 9 | Transport Per Tonne | Transport_Per_Tonne__c | Checkbox | TRUE/FALSE |
| 10 | Supplier price | Supplier_price__c | Currency | Cost from supplier |
| 11 | Partner Tonnage Incl | Partner_Tonnage_Incl__c | Number | Tonnage included |
| 12 | Partner Tonnage charge thereafter | Partner_Tonnage_charge_thereafter__c | Currency | Additional tonnage charge |
| 13 | Sales Transport | Sales_Transport__c | Currency | **FORMULA FIELD** (calculated) |
| 14 | Sales Price | Sales_Price__c | Currency | Price to customer |
| 15 | Sales Tonnage incl | Sales_Tonnage_incl__c | Number | Customer tonnage included |
| 16 | Sales Tonnage charge thereafter | Sales_Tonnage_charge_thereafter__c | Currency | Customer tonnage charge |

---

## IMPORTANT: Formula Field Warning

### ⚠️ Sales_Transport__c is a FORMULA FIELD

**Formula**:
```
UnitPrice - (Partner_Tonnage_Incl__c * Sales_Tonnage_charge_thereafter__c)
```

**What this means**:
- ❌ **You CANNOT update this field directly via Data Loader**
- ✅ It will automatically calculate when you update UnitPrice, Partner_Tonnage_Incl__c, or Sales_Tonnage_charge_thereafter__c
- ❌ **Remove Sales_Transport__c from your Data Loader CSV** if it's there

**Alternative**: If you want to update the sales transport value, you need to update **`UnitPrice`** instead!

---

## Updated Field Mapping for Data Loader

### Fields You CAN Update (Not Formulas)

| CSV Column | CSV Header | OrderItem Field | Can Update? |
|------------|------------|----------------|-------------|
| 20 | Order Product ID | Id | ✅ Required (identifier) |
| 6 | Pricing method | Pricing_method__c | ✅ Yes |
| 7 | Transport | Transport__c | ✅ Yes |
| 8 | Transport Per Unit | Transport_Per_Unit__c | ✅ Yes |
| 9 | Transport Per Tonne | Transport_Per_Tonne__c | ✅ Yes |
| 10 | Supplier price | Supplier_price__c | ✅ Yes |
| 11 | Partner Tonnage Incl | Partner_Tonnage_Incl__c | ✅ Yes |
| 12 | Partner Tonnage charge thereafter | Partner_Tonnage_charge_thereafter__c | ✅ Yes |
| 13 | Sales Transport | Sales_Transport__c | ❌ **FORMULA - Cannot update** |
| 14 | Sales Price | Sales_Price__c | ✅ Yes |
| 15 | Sales Tonnage incl | Sales_Tonnage_incl__c | ✅ Yes |
| 16 | Sales Tonnage charge thereafter | Sales_Tonnage_charge_thereafter__c | ✅ Yes |

---

## Correct Data Loader Configuration

### Operation Type
**UPDATE** (not Insert, not Upsert)

### Object Selection
**OrderItem**

### CSV Structure for Data Loader

```csv
Id,Pricing_method__c,Transport__c,Transport_Per_Unit__c,Transport_Per_Tonne__c,Supplier_price__c,Partner_Tonnage_Incl__c,Partner_Tonnage_charge_thereafter__c,Sales_Price__c,Sales_Tonnage_incl__c,Sales_Tonnage_charge_thereafter__c
802Sj000008tR4d,Variable,136,FALSE,TRUE,,0,20,,,,
802Sj00000B8m7b,Variable,136,FALSE,TRUE,,,20,,,,
```

**Notice**:
- ✅ `Id` is included (identifies which record to update)
- ✅ Updateable fields only
- ❌ `Sales_Transport__c` is NOT included (formula field)
- ❌ `OrderItemNumber` is NOT included (auto-number, read-only)

---

## Relationships in Your Scenario

### Parent-Child Relationships

```
Order (Parent)
  └─ OrderItem (Child) ← YOU ARE HERE
       └─ Job__c (Child of OrderItem)
```

**Field**: `OrderId` (on OrderItem)
**Type**: Master-Detail
**Cascade Delete**: Yes (if Order is deleted, OrderItems are deleted)

### Lookup Relationships

**OrderItem → Account** (Supplier):
- Field: `Partner__c`
- Label: "Supplier Name"
- Type: Lookup to Account

---

## Data Loader Field Mapping in UI

When you use Data Loader UPDATE:

1. **Select Object**: OrderItem
2. **Map CSV Column → Salesforce Field**:

| CSV Column Header | Salesforce Field | Mapping Type |
|-------------------|-----------------|--------------|
| Id | Id | Required (External ID) |
| Pricing_method__c | Pricing_method__c | Direct |
| Transport__c | Transport__c | Direct |
| Transport_Per_Unit__c | Transport_Per_Unit__c | Direct |
| Transport_Per_Tonne__c | Transport_Per_Tonne__c | Direct |
| Supplier_price__c | Supplier_price__c | Direct |
| Partner_Tonnage_Incl__c | Partner_Tonnage_Incl__c | Direct |
| Partner_Tonnage_charge_thereafter__c | Partner_Tonnage_charge_thereafter__c | Direct |
| Sales_Price__c | Sales_Price__c | Direct |
| Sales_Tonnage_incl__c | Sales_Tonnage_incl__c | Direct |
| Sales_Tonnage_charge_thereafter__c | Sales_Tonnage_charge_thereafter__c | Direct |

---

## What Happens When You Update OrderItem?

### Immediate Effects:
1. ✅ OrderItem fields updated with new values
2. ✅ Formula field `Sales_Transport__c` recalculates automatically
3. ✅ `LastModifiedDate` and `LastModifiedBy` updated
4. ⚠️ May trigger automation (workflows, process builder, flows, triggers)

### Potential Downstream Effects:
1. **Job__c records** using this OrderItem may need price updates
2. **Quotes** related to the Order may show different pricing
3. **Reports/Dashboards** will reflect new values
4. **Price_Increase__c** records (if any exist) may become out of sync

---

## Querying Your Data After Update

### Check Individual OrderItem

```sql
SELECT Id, OrderItemNumber, Transport__c, Supplier_price__c,
       Partner_Tonnage_charge_thereafter__c, Sales_Transport__c,
       LastModifiedDate, LastModifiedBy.Name
FROM OrderItem
WHERE Id = '802Sj000008tR4d'
```

### Check All Your Updated Records

```sql
SELECT Id, OrderItemNumber, Transport__c, Supplier_price__c,
       Order.OrderNumber, Order.Site__r.Name
FROM OrderItem
WHERE Id IN (
  '802Sj000008tR4d',
  '802Sj00000B8m7b',
  '802Sj00000B8m7c'
)
```

### Count Today's Updates

```sql
SELECT COUNT(Id)
FROM OrderItem
WHERE LastModifiedDate = TODAY
AND LastModifiedById = '0051o000008F1qaAAC'
```
(Replace with your User ID)

---

## Summary for Your Scenario

### What You're Doing:
- **Updating**: OrderItem records (Order Products)
- **Using**: Order Product ID (column 20) as unique identifier
- **Method**: Data Loader UPDATE operation
- **Records**: 1,636 OrderItem records (103 + 1,533)

### Key Relationships:
- OrderItem belongs to Order (Master-Detail via OrderId)
- OrderItem links to Account/Supplier (Lookup via Partner__c)
- OrderItem can have many Job__c records

### Critical Fields:
- **Id**: Your unique identifier (column 20)
- **Transport__c**: Supplier transport (column 7)
- **Supplier_price__c**: Supplier price (column 10)
- **Partner_Tonnage_charge_thereafter__c**: Partner charge (column 12)
- **Sales_Transport__c**: FORMULA - don't update directly!

### Data Loader Settings:
- **Object**: OrderItem
- **Operation**: UPDATE
- **External ID**: Id (Order Product ID)
- **Fields**: 11 updateable fields (exclude formula field)

---

## Visual: Your CSV → Salesforce Mapping

```
Your CSV Row:
┌────────────────────────────────────────────────────────┐
│ Col 20: 802Sj000008tR4d (Order Product ID)            │ ← Identifies which OrderItem
│ Col 7:  136 (Transport)                                │ → Transport__c
│ Col 10: (blank) (Supplier price)                       │ → Supplier_price__c
│ Col 12: 20 (Partner Tonnage charge)                    │ → Partner_Tonnage_charge_thereafter__c
└────────────────────────────────────────────────────────┘
                      ↓
              Data Loader UPDATE
                      ↓
┌────────────────────────────────────────────────────────┐
│ Salesforce OrderItem Record: 802Sj000008tR4d          │
│   Transport__c: 136                                     │ ✅ Updated
│   Supplier_price__c: (blank)                            │ ✅ Updated
│   Partner_Tonnage_charge_thereafter__c: 20             │ ✅ Updated
│   Sales_Transport__c: [calculated automatically]        │ ✅ Auto-calculated
└────────────────────────────────────────────────────────┘
```

---

## Next Steps

1. ✅ Understand the data model (this document)
2. ✅ Prepare your CSV with correct field API names
3. ✅ Exclude `Sales_Transport__c` (formula field)
4. ✅ Use Data Loader UPDATE operation
5. ✅ Map `Id` field correctly (column 20)
6. ✅ Verify updates in Salesforce after import

---

**Document Created**: 2025-10-13
**For**: Understanding OrderItem data model for bulk price updates
**Object**: OrderItem (Order Product)
**Operation**: UPDATE via Data Loader
**Records**: 1,636 Order Products across 2 CSV files
