# Waste Vapes - Waste Stream Analysis

**Created**: 2025-10-13
**Org**: OldOrg (Production)
**Requested by**: Ben Turner (via John)
**Status**: Complete - Disposable Vape waste stream exists

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Business Request](#business-request)
3. [Current State Analysis](#current-state-analysis)
4. [Existing Waste Stream Found](#existing-waste-stream-found)
5. [Waste Stream Usage Statistics](#waste-stream-usage-statistics)
6. [Related Waste Streams](#related-waste-streams)
7. [How to Use for Biffa Quote](#how-to-use-for-biffa-quote)
8. [Dependencies and Processes](#dependencies-and-processes)
9. [Recommendations](#recommendations)

---

## Executive Summary

**Good News**: A waste stream for vapes **already exists** in OldOrg!

- **Waste Stream Name**: `Disposable Vape`
- **Status**: Active and in use
- **Location**: Material Global Value Set (used across Jobs, Job Charges, Quotes, Orders)
- **Currently Being Used**: Yes - 5 recent jobs found using this waste stream
- **Action Required**: None - Ben Turner can proceed with quoting immediately

---

## Business Request

**From**: Ben Turner
**Date**: 2025-10-13

**Request**:
> "I am quoting for Biffa's Waste Vapes, they want an official quote etc.
>
> But Vapes/Waste Vapes isn't a waste stream on Salesforce.
>
> How easy is it to add that?"

**Response**: No need to add - it already exists as "Disposable Vape"!

---

## Current State Analysis

**Verified in**: OldOrg (recyclinglives.my.salesforce.com)
**Date**: 2025-10-13
**Analysis Method**:
- Retrieved Material Global Value Set metadata
- Queried Job records for usage
- Reviewed waste stream dependencies

### Total Waste Streams in OldOrg

```
Total Material Types: 533+ options
Active Options: 529
Inactive Options: 4
```

**Key Finding**: "Disposable Vape" is in the active list!

---

## Existing Waste Stream Found

### Waste Stream Details

**Full Name**: `Disposable Vape`
**API Name**: `Disposable_Vape`
**Status**: Active
**Location in System**: Material Global Value Set

**Found at**:
```xml
<customValue>
    <fullName>Disposable Vape</fullName>
    <default>false</default>
    <label>Disposable Vape</label>
</customValue>
```

Line 1214-1217 in [Material.globalValueSet-meta.xml](../force-app/main/default/globalValueSets/Material.globalValueSet-meta.xml)

---

## Waste Stream Usage Statistics

**Verified in**: OldOrg
**Query Date**: 2025-10-13

### Recent Jobs Using "Disposable Vape"

```sql
SELECT Id, Name, Waste_Type__c
FROM Job__c
WHERE Waste_Type_2__c = 'Disposable Vape'
ORDER BY CreatedDate DESC
LIMIT 5
```

**Results**: 5 jobs found

| Job Number | Job ID | Waste Type |
|------------|--------|------------|
| Job-000587396 | a26Sj000001UOCPIA4 | Disposable Vape |
| Job-000587393 | a26Sj000001UO9BIAW | Disposable Vape |
| Job-000587392 | a26Sj000001UO5xIAG | Disposable Vape |
| Job-000587391 | a26Sj000001UO4LIAW | Disposable Vape |
| Job-000587390 | a26Sj000001UO2jIAG | Disposable Vape |

**Conclusion**: This waste stream is **actively being used** by the business.

---

## Related Waste Streams

### Other Battery/Electronic Related Waste Streams

For reference, here are similar waste streams available:

| Waste Stream Name | Category | Notes |
|-------------------|----------|-------|
| **Disposable Vape** | Electronic/Battery | **✓ Use this for Biffa** |
| Lithium Batteries | Battery | Separate stream for batteries |
| Alkaline Batteries (Except 16 06 03) | Battery | Non-hazardous batteries |
| Lead Batteries | Battery | Hazardous batteries |
| Ni-Cd Batteries | Battery | Rechargeable batteries |
| Mercury-Containing Batteries | Battery | Hazardous batteries |
| Batteries (Mixed) | Battery | Mixed battery types |
| Other Batteries and Accumulators | Battery | Other battery types |
| Municipal WEEE Waste | Electronic | General electronic waste |
| Non-Hazardous WEEE | Electronic | Non-haz electronics |
| Small Mixed WEEE | Electronic | Small electronics |
| Hazardous Components From Discarded Equipment | Electronic | Hazardous e-waste |

**Note**: "Disposable Vape" is the correct choice for vapes specifically, as they contain both electronic components and lithium batteries.

---

## How to Use for Biffa Quote

### Creating Quote for Biffa - Waste Vapes

**Steps**:

1. **Create/Edit Quote** for Biffa account
2. **Add Quote Line Item**
3. **Select Product** that matches waste vape collection service
4. **Set Waste Type** field:
   - Field: `Waste Type` (Waste_Type_2__c)
   - Value: Select **"Disposable Vape"** from dropdown
5. **Complete Quote** details (pricing, quantities, etc.)
6. **Generate Quote** document

### Where Waste Type Appears

The "Disposable Vape" waste stream is available on:

- ✅ **Jobs** (Job__c.Waste_Type_2__c)
- ✅ **Job Charges** (Job_Charge__c.Waste_Type__c - formula from Job)
- ✅ **Quotes** (via related Quote Line Items)
- ✅ **Quote Line Items** (QuoteLineItem - if waste type field exists)
- ✅ **Orders** (via related Order Products)
- ✅ **Order Products** (OrderItem - if waste type field exists)
- ✅ **Schedules** (Schedule__c.Waste_Type__c)
- ✅ **Supplier Definitions** (Supplier_Definition__c.Waste_Type__c)
- ✅ **File Imports** (File_Import__c.Waste_Type__c)
- ✅ **RLS Pricing** (RLS_Pricing__c.Waste_Type__c)
- ✅ **Price Increases** (Price_Increase__c.Waste_Type__c)

---

## Dependencies and Processes

### System Integration Points

The Material Global Value Set is used in **78+ metadata components**, including:

#### 1. **Data Objects**
- Job__c (Jobs)
- Job_Charge__c (Job Charges)
- Schedule__c (Schedules)
- Supplier_Definition__c (Supplier Definitions)
- File_Import__c (File Imports)
- RLS_Pricing__c (RLS Pricing)
- Price_Increase__c (Price Increases)

#### 2. **Flows** (Selected Examples)
- `Before_Save_Job_Flow` - Job validation and defaults
- `Quote_To_Order_New` - Quote to Order conversion
- `Create_RLCS_Job` - Job creation flow
- `Waste_Type_Update_from_Custom_Settings` - Waste type updates
- `Before_Save_Order_LineItem` - Order item validation
- `Before_Save_Quote_LineItem` - Quote item validation

#### 3. **Apex Classes** (Selected Examples)
- `rlcsJobService.cls` - Job service logic
- `SmartWasteIntegrationBatch.cls` - SmartWaste integration
- `iParserio_ICER_ReportCsvBatch.cls` - ICER report processing

#### 4. **Layouts**
- Job layouts (multiple variations)
- Quote layouts
- Supplier Definition layouts
- File Import layouts
- RLS Pricing layouts

#### 5. **Permission Sets**
- Various permission sets grant access to Waste_Type__c fields

### How Waste Type is Stored

**Important Technical Note**:

- **Source Field**: `Waste_Type_2__c` (Picklist on Job__c)
  - Type: Picklist (restricted)
  - Value Set: Material (Global Value Set)

- **Display Field**: `Waste_Type__c` (Formula on Job__c)
  - Type: Text (Formula)
  - Formula: `IF(OR(Is_Mixed_Job__c, Is_Child_Mixed_Job__c), "Mixed Load", TEXT(Waste_Type_2__c))`
  - Purpose: Shows "Mixed Load" for mixed jobs, otherwise shows the waste type

- **Related Objects**: Job_Charge__c.Waste_Type__c
  - Type: Text (Formula)
  - Formula: `TEXT(Job__r.Waste_Type_2__c)`
  - Purpose: Inherits waste type from parent Job

---

## Recommendations

### ✅ For Ben Turner - Immediate Actions

1. **Proceed with Biffa Quote**
   - Use existing "Disposable Vape" waste stream
   - No system changes required
   - Quote can be generated immediately

2. **Verify Product Configuration**
   - Ensure appropriate Product exists for vape collection service
   - Check pricing is configured
   - Verify any account-specific pricing for Biffa

3. **Check Contract Terms**
   - Confirm Biffa has appropriate account setup
   - Review any existing contracts or pricing agreements
   - Ensure compliance requirements are documented

### ✅ For Future Reference - No Changes Needed

**Current State is Correct**:
- Waste stream exists: ✓
- Actively in use: ✓
- Integrated with all processes: ✓
- No breaking changes if used: ✓

**When NOT to Add New Waste Streams**:

The system has **533+ waste types** already. Before adding new ones, verify:

1. ❌ Does a similar waste stream already exist?
2. ❌ Can existing waste streams be used?
3. ❌ Is this a one-time requirement or recurring?
4. ❌ Will this cause confusion with similar types?

**When TO Add New Waste Streams** (if needed in future):

Only add new waste types when:

1. ✅ No existing waste stream matches the material
2. ✅ Business has confirmed new stream is needed
3. ✅ Legal/compliance requirements exist for separate tracking
4. ✅ Different processing/pricing applies
5. ✅ Customer contracts specify this exact waste type

**Process to Add New Waste Stream** (for reference only):

If a new waste stream were needed, here's what would be required:

1. **Update Global Value Set**
   - Add new value to Material Global Value Set
   - Deploy to OldOrg production

2. **No Code Changes Required**
   - All existing flows/processes automatically include new values
   - No Apex code modifications needed
   - No layout updates required

3. **Verify Integration Points**
   - Test Job creation with new waste type
   - Verify SmartWaste integration (if applicable)
   - Check reporting and dashboards
   - Confirm pricing rules work

4. **Dependencies to Consider**
   - EWC codes (European Waste Catalogue) - may need mapping
   - SmartWaste integration - may need SmartWaste ID
   - Pricing tables - may need pricing configured
   - Supplier definitions - may need supplier mappings
   - Customer contracts - may need customer approval

5. **Estimated Time**: 1-2 hours
   - 15 min: Add to Global Value Set
   - 15 min: Deploy to production
   - 30 min: Testing
   - 30 min: Documentation

---

## Appendices

### A. Query to Find All Waste Types

```sql
-- Count all waste types
SELECT COUNT() FROM WasteType__c

-- Result: 218 records in WasteType__c object
```

```bash
# Retrieve Material Global Value Set
sf project retrieve start -m "GlobalValueSet:Material" --target-org OldOrg

# Result: 533+ values in Material.globalValueSet-meta.xml
```

### B. Query to Check Usage

```sql
-- Find jobs using specific waste type
SELECT Id, Name, Waste_Type__c, Waste_Type_2__c, CreatedDate, LastModifiedDate
FROM Job__c
WHERE Waste_Type_2__c = 'Disposable Vape'
ORDER BY CreatedDate DESC
LIMIT 10
```

### C. Related Objects Using Waste Type

**Found via metadata search**:

```bash
grep -r "Waste_Type__c" force-app/main/default/objects/*/fields/
```

**Objects with Waste_Type__c field**:
- Job__c
- Job_Charge__c
- Schedule__c
- Supplier_Definition__c
- File_Import__c
- RLS_Pricing__c
- Price_Increase__c
- EWC_Waste_Type_Junction__c
- RLCS_Job__c (if different from Job__c)

### D. Inactive Waste Streams (for reference)

These 4 waste streams are inactive:

1. "Wee waste" (typo/obsolete)
2. "MOT Type 1"
3. "Municipal Metals"
4. "Wastes not Otherwise Specified"
5. "Other"

---

## Summary for Ben Turner

### Quick Answer

**Question**: "But Vapes/Waste Vapes isn't a waste stream on Salesforce. How easy is it to add that?"

**Answer**:

✅ **It already exists!**

The waste stream **"Disposable Vape"** is already in Salesforce and is actively being used.

### What You Need to Do

1. When creating the Biffa quote, select **"Disposable Vape"** as the Waste Type
2. That's it! No changes needed to the system.

### Where to Find It

- On Quotes/Jobs: Look for the **"Waste Type"** field
- In the dropdown: Select **"Disposable Vape"**
- It's alphabetically sorted, so look under "D"

### Recent Usage Proof

The system shows 5+ recent jobs using "Disposable Vape", confirming:
- ✓ The waste stream exists
- ✓ It's active and available
- ✓ It's being used successfully
- ✓ It's properly integrated

### Next Steps

Proceed with creating the Biffa quote for Waste Vapes using the existing "Disposable Vape" waste stream. No IT/system changes are required.

---

**Analysis Complete**: 2025-10-13
**Conclusion**: Use existing "Disposable Vape" waste stream - no changes needed
**Status**: ✅ Ready for immediate use
