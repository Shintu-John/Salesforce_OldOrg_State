# BAM Construct Portal License Visibility - OldOrg State Documentation

**Scenario**: bam-construct-portal-license
**Implementation Date**: October 15, 2025
**Deployed To**: OldOrg (recyclinglives.my.salesforce.com)
**Issue**: Customer portal users could not see supplier waste carrier licenses and permit expiry dates
**NewOrg Migration Package**: [View Migration Package](https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/bam-construct-portal-license)

---

## Executive Summary

This deployment enables customer portal users with "HQ" role to view supplier waste carrier license numbers and expiry dates in both Job detail pages and the Compliance tab. This is critical for UK waste management compliance verification.

**Problem**: Ruth Beavers (BAM Construct UK) reported that suppliers' licenses and permits were not showing on the customer portal.

**Solution Implemented**:
1. Created formula field `Waste_Carrier_License_Expiry__c` on Job object
2. Updated Job portal layout to show license fields
3. Modified `Utility_Community` Apex class to query license fields
4. Updated `depotViewCommunity` LWC component to display license columns in Compliance tab

**Impact**: All 137 HQ-level portal users can now see supplier license information for compliance verification.

---

## Table of Contents

1. [Source Documentation](#source-documentation)
2. [Components Deployed](#components-deployed)
3. [Code Changes - Line-by-Line Verification](#code-changes---line-by-line-verification)
4. [Deployment Details](#deployment-details)
5. [Configuration Changes (Not Code)](#configuration-changes-not-code)
6. [Testing & Verification](#testing--verification)
7. [Known Limitations](#known-limitations)
8. [Related Information](#related-information)

---

## Source Documentation

**Primary Documentation**:
- Location: `/home/john/Projects/Salesforce/Documentation/BAM_CONSTRUCT_PORTAL_LICENSE_VISIBILITY_FIX.md`
- Saved in this repo: `source-docs/BAM_CONSTRUCT_PORTAL_LICENSE_VISIBILITY_FIX.md`
- Last Updated: October 15, 2025
- Reported By: Katie
- Affected Customer: BAM Construct UK (Portal User: Ruth Beavers)

**Key Documentation Sections**:
- Complete implementation steps with CLI commands
- Root cause analysis (5 issues identified)
- Testing procedures
- Rollback procedures
- Deployment checklist for NewOrg
- Future prevention recommendations

---

## Components Deployed

### Metadata Files (4 files)

| Component | Type | File | Lines | Deploy ID |
|-----------|------|------|-------|-----------|
| Formula Field | CustomField | `Waste_Carrier_License_Expiry__c.field-meta.xml` | 11 | 0AfSj000000yqlJKAQ (with layout) |
| Portal Layout | Layout | `Job__c-Customer Community Job Layout.layout-meta.xml` | 401 | 0AfSj000000yqlJKAQ |
| Apex Class | ApexClass | `Utility_Community.cls` | 296 | 0AfSj000000yqtNKAQ |
| LWC Component | LightningComponentBundle | `depotViewCommunity/` | 291 total | 0AfSj000000yqtNKAQ |

**LWC Component Files**:
- `depotViewCommunity.js` - 178 lines
- `depotViewCommunity.html` - 113 lines
- `depotViewCommunity.css` - (styling only, no changes)
- `depotViewCommunity.js-meta.xml` - (metadata only, no changes)

**Total Code**: 999 lines across 5 metadata files

---

## Code Changes - Line-by-Line Verification

### 1. Formula Field: Waste_Carrier_License_Expiry__c

**File**: `code/Waste_Carrier_License_Expiry__c.field-meta.xml`

**Purpose**: Display supplier's waste carrier license expiry date from Account object on Job records.

**Formula** (Line 5):
```xml
<formula>Supplier__r.Waste_Carriers_License_Date__c</formula>
```

**Verification Command**:
```bash
grep -n "formula" code/Waste_Carrier_License_Expiry__c.field-meta.xml
```

**Expected Output**:
```
5:    <formula>Supplier__r.Waste_Carriers_License_Date__c</formula>
```

**Field Properties**:
- Type: Date (formula)
- Label: "Waste Carrier License Expiry"
- Required: false
- Description: "Formula field to display supplier's waste carrier license expiry date in portal"

✅ **Verified**: Formula correctly references `Supplier__r.Waste_Carriers_License_Date__c` to display supplier license expiry.

---

### 2. Job Portal Layout

**File**: `code/Job__c-Customer Community Job Layout.layout-meta.xml` (401 lines)

**Purpose**: Add license number and expiry date fields to Supplier Details section of portal Job layout.

**License Fields Added** (Lines 96-100):
```xml
<layoutItems>
    <behavior>Readonly</behavior>
    <field>Waste_Carrier_License_Number__c</field>
</layoutItems>
<layoutItems>
    <behavior>Readonly</behavior>
    <field>Waste_Carrier_License_Expiry__c</field>
</layoutItems>
```

**Verification Command**:
```bash
grep -n -A3 -B3 "Waste_Carrier_License" code/Job__c-Customer\ Community\ Job\ Layout.layout-meta.xml | head -20
```

**Expected Output**:
```
93-            </layoutItems>
94-            <layoutItems>
95-                <behavior>Readonly</behavior>
96:                <field>Waste_Carrier_License_Number__c</field>
97-            </layoutItems>
98-            <layoutItems>
99-                <behavior>Readonly</behavior>
100:                <field>Waste_Carrier_License_Expiry__c</field>
101-            </layoutItems>
102-        </layoutColumns>
103-        <layoutColumns>
```

**Layout Section**: Supplier Details (left column)
- Field 1: Supplier_Name__c
- **Field 2**: **Waste_Carrier_License_Number__c** ✅ ADDED
- **Field 3**: **Waste_Carrier_License_Expiry__c** ✅ ADDED

✅ **Verified**: Both license fields added to Supplier Details section in readonly mode for portal users.

---

### 3. Apex Class: Utility_Community.cls

**File**: `code/Utility_Community.cls` (296 lines)

**Purpose**: Add license fields to SOQL query and return map for Compliance tab LWC component.

**Method Modified**: `getDepotInformations()` (Lines 16-46)

**SOQL Query Enhancement** (Lines 21-23):
```apex
for(Job__c jobRec : [SELECT Id, Name, Delivery_Date__c, Supplier__c, Supplier__r.Name, Depot_Dispose__c, Depot_Dispose__r.Name,
                     Waste_Type_2__c, EWC_Code_2__c, Site__c, Site__r.Name,
                     Waste_Carrier_License_Number__c, Waste_Carrier_License_Expiry__c
                     FROM Job__c
```

**Return Map Enhancement** (Lines 40-41):
```apex
                                         'ewcCode' => jobRec.EWC_Code_2__c,
                                         'licenseNumber' => jobRec.Waste_Carrier_License_Number__c,
                                         'licenseExpiry' => jobRec.Waste_Carrier_License_Expiry__c
                                         });
```

**Verification Command**:
```bash
grep -n "Waste_Carrier_License_Expiry__c" code/Utility_Community.cls
```

**Expected Output**:
```
23:                             Waste_Carrier_License_Number__c, Waste_Carrier_License_Expiry__c
41:                                         'licenseExpiry' => jobRec.Waste_Carrier_License_Expiry__c
```

**Changes Summary**:
- Line 23: Added `Waste_Carrier_License_Number__c, Waste_Carrier_License_Expiry__c` to SOQL SELECT
- Line 40: Added `'licenseNumber' => jobRec.Waste_Carrier_License_Number__c` to return map
- Line 41: Added `'licenseExpiry' => jobRec.Waste_Carrier_License_Expiry__c` to return map

✅ **Verified**: License fields queried and included in return map for LWC consumption.

---

### 4. LWC JavaScript: depotViewCommunity.js

**File**: `code/depotViewCommunity/depotViewCommunity.js` (178 lines)

**Purpose**: Extract license data from Apex response and include in supplier grouping logic.

**Method Modified**: `groupData()` (Lines 97-167)

**Data Destructuring** (Line 99):
```javascript
const { supplierName, depotDispose, wasteType, ewcCode, deliveryDate, licenseNumber, licenseExpiry } = item;
```

**Supplier Object Creation** (Line 106):
```javascript
acc[supplierName] = { supplierName, link : '/' + item.supplierId, depots: {}, rowspan: 0, firstService: null, lastService: null, licenseNumber, licenseExpiry };
```

**Verification Command**:
```bash
grep -n "licenseNumber\|licenseExpiry" code/depotViewCommunity/depotViewCommunity.js
```

**Expected Output**:
```
99:        const { supplierName, depotDispose, wasteType, ewcCode, deliveryDate, licenseNumber, licenseExpiry } = item;
106:            acc[supplierName] = { supplierName, link : '/' + item.supplierId, depots: {}, rowspan: 0, firstService: null, lastService: null, licenseNumber, licenseExpiry };
```

**Changes Summary**:
- Line 99: Added `licenseNumber, licenseExpiry` to destructuring assignment
- Line 106: Added `licenseNumber, licenseExpiry` to supplier object (ES6 shorthand property)

✅ **Verified**: License data extracted from Apex response and stored in supplier grouping object.

---

### 5. LWC HTML: depotViewCommunity.html

**File**: `code/depotViewCommunity/depotViewCommunity.html` (113 lines)

**Purpose**: Display license number and expiry date columns in Compliance tab table.

**Table Header Enhancement** (Lines 39-41):
```html
<thead>
    <tr>
        <th>Waste Carrier</th>
        <th>License Number</th>
        <th>License Expiry</th>
        <th>Waste Destination</th>
```

**Table Body Enhancement** (Lines 64-72):
```html
<td class="slds-cell-wrap" title={supplier.value.licenseNumber} rowspan={supplier.value.rowspan}>
    <span class="sticky-cell-span">{supplier.value.licenseNumber}</span>
</td>
<td class="slds-cell-wrap" rowspan={supplier.value.rowspan}>
    <span class="sticky-cell-span">
        <lightning-formatted-date-time value={supplier.value.licenseExpiry} year="numeric" month="2-digit" day="2-digit">
        </lightning-formatted-date-time>
    </span>
</td>
```

**Verification Command**:
```bash
grep -n "License Number\|License Expiry" code/depotViewCommunity/depotViewCommunity.html
```

**Expected Output**:
```
40:                                    <th>License Number</th>
41:                                    <th>License Expiry</th>
```

**Changes Summary**:
- Lines 40-41: Added "License Number" and "License Expiry" columns to table header
- Lines 64-66: Added license number cell with `rowspan={supplier.value.rowspan}` (one cell per supplier)
- Lines 67-72: Added license expiry cell with formatted date display

**Column Order** (after changes):
1. Waste Carrier (supplier name)
2. **License Number** ✅ ADDED
3. **License Expiry** ✅ ADDED
4. Waste Destination (depot)
5. Waste Type
6. EWC Code
7. First Service
8. Last Service

✅ **Verified**: Two new columns added to Compliance tab table with proper rowspan grouping by supplier.

---

## Deployment Details

### Deployment IDs

**Deploy #1: Portal Layout & Formula Field**
- Deploy ID: `0AfSj000000yqlJKAQ`
- Date: October 15, 2025
- Status: Succeeded
- Components:
  - `CustomField:Job__c.Waste_Carrier_License_Expiry__c`
  - `Layout:Job__c-Customer Community Job Layout`

**Deploy #2: Compliance Tab Components**
- Deploy ID: `0AfSj000000yqtNKAQ`
- Date: October 15, 2025
- Status: Succeeded
- Test Class: `Utility_CommunityTest`
- Components:
  - `ApexClass:Utility_Community`
  - `LightningComponentBundle:depotViewCommunity`

### Field-Level Security

**Permission Sets/Profiles Granted Access**:
- All community profiles with access to `Job__c.Waste_Carrier_License_Number__c` automatically received READ access to `Waste_Carrier_License_Expiry__c`
- Granted via Apex Anonymous script (see source documentation)
- Approximately 17 profiles/permission sets updated

**Query to Verify FLS**:
```bash
sf data query --query "SELECT Parent.Profile.Name, Field, PermissionsRead FROM FieldPermissions WHERE Field = 'Job__c.Waste_Carrier_License_Expiry__c' AND Parent.Profile.Name LIKE '%Community%'" --target-org OldOrg
```

### Field Dependencies

**New Formula Field Dependencies**:
- `Job__c.Waste_Carrier_License_Expiry__c` depends on:
  - `Job__c.Supplier__c` (lookup to Account)
  - `Account.Waste_Carriers_License_Date__c` (Date field on Account object)

**Existing Field Dependencies** (already deployed):
- `Job__c.Waste_Carrier_License_Number__c` (formula field, depends on `Supplier__r.Waste_Carriers_License_number__c`)
- `Account.Waste_Carriers_License_number__c` (Text field)
- `Account.Waste_Carriers_License_Date__c` (Date field)

**Total Field Dependencies**: 3 Job fields + 2 Account fields = 5 fields

---

## Configuration Changes (Not Code)

These are Manual UI configuration changes made for the specific user (Ruth Beavers). They are documented here for reference but are **NOT included in the code deployment**.

### User Access Configuration

**Contact Record Updated**:
- Contact: Ruth Beavers (0032400000rtDPzAAM)
- Account: BAM Construct UK (0012400000RIcTpAAL)
- User: rbeavers@bam.co.uk (005Sj000002aZAzIAM)
- **Change**: `Community_Role__c` set from `null` to `'HQ'`

**Purpose**: Setting `Community_Role__c = 'HQ'` enables automatic AccountShare creation for suppliers via `CommunityAccessHelper` trigger.

### Sharing Records Created (Manual)

**7 Manual Sharing Records Created** (one-time fix for Ruth Beavers):

| Type | Record | Purpose | Share ID |
|------|--------|---------|----------|
| AccountShare | BAM Construct UK (own account) | Edit access | 00rSj00000UcwwkIAB |
| AccountShare | BAGNALL & MORRIS | Supplier Read access | 00rSj00000UdEoLIAV |
| AccountShare | JWS WASTE & RECYCLING | Supplier Read access | 00rSj00000Ud92VIAR |
| AccountShare | Safety-Kleen | Supplier Read access | 00rSj00000UdBVaIAN |
| Site__Share | The Salesian Academy | Site Edit access | 02cSj00000dNm33IAC |
| Site__Share | Historic Data Import | Site Edit access | 02cSj00000dNm34IAC |
| Total | 7 records | - | - |

**Note**: Future suppliers will automatically get AccountShare records via `CommunityAccessHelper.cls` trigger (no manual creation needed).

---

## Testing & Verification

### Portal User Testing (Completed)

**Test User**: Ruth Beavers (rbeavers@bam.co.uk)

✅ **Test 1: Job Detail Page**
- Navigate: Sites → The Salesian Academy → Jobs → Select any job
- Verified "Supplier Details" section shows:
  - Supplier Name
  - Waste Carrier License Number (e.g., CBDU180923)
  - Waste Carrier License Expiry (e.g., 25/06/2026)
  - Depot Supply Name
  - Depot Dispose Name

✅ **Test 2: Compliance Tab**
- Navigate: Compliance tab
- Select Site: The Salesian Academy
- Click "Search"
- Verified table displays 8 columns including:
  - Waste Carrier
  - **License Number** (e.g., CBDU180923)
  - **License Expiry** (e.g., 25/06/2026)
  - Waste Destination, Waste Type, EWC Code, First Service, Last Service

✅ **Test 3: HQ User Count**
- Query: `SELECT COUNT() FROM Contact WHERE Community_Role__c = 'HQ'`
- Result: 137 HQ users in system
- All 137 users can now see supplier license information

### Backend Verification Queries

**Verify Formula Field Exists**:
```bash
sf data query --query "SELECT DeveloperName, TableEnumOrId FROM CustomField WHERE DeveloperName = 'Waste_Carrier_License_Expiry' LIMIT 1" --use-tooling-api --target-org OldOrg
```

**Verify Field-Level Security**:
```bash
sf data query --query "SELECT Parent.Profile.Name, Field, PermissionsRead FROM FieldPermissions WHERE Field = 'Job__c.Waste_Carrier_License_Expiry__c' AND Parent.Profile.Name LIKE '%Community%' LIMIT 10" --target-org OldOrg
```

**Verify Community_Role__c Distribution**:
```bash
sf data query --query "SELECT Community_Role__c, COUNT(Id) cnt FROM Contact WHERE Id IN (SELECT ContactId FROM User WHERE IsActive = true) GROUP BY Community_Role__c" --target-org OldOrg
```

**Expected Results**:
- 137 users with `Community_Role__c = 'HQ'` (15%)
- 183 users with `Community_Role__c = 'Site'` (20%)
- 594 users with `Community_Role__c = null` (65% - data quality issue)

---

## Known Limitations

### Compliance Tab Filtering

**Issue**: Some suppliers with valid licenses may not appear in the Compliance tab grouping.

**Root Cause**: The `Utility_Community.getDepotInformations()` query includes filter:
```apex
WHERE Site__c IN :siteIds
AND Status__c NOT IN ('Pending Cancellation', 'Cancelled', 'Failed')
AND Supplier__c != NULL
AND Supplier__r.Name != NULL
AND Depot_Dispose__c != NULL  // <-- Filters out jobs without disposal location
```

**Impact**:
- Jobs without `Depot_Dispose__c` (Waste Destination) will NOT appear in Compliance tab
- These jobs ARE still visible when navigating to individual Job detail pages
- License information IS displayed on individual Job records

**Example - Safety-Kleen at BAM Construct**:
- Supplier: Safety-Kleen U.K. Limited
- License: CBDU89939 (valid until 02/04/2028)
- 5 jobs at The Salesian Academy (all have `Depot_Dispose__c = null`)
- **Result**: Safety-Kleen does NOT appear in Compliance tab grouping
- **Workaround**: Users can still view license details by navigating to Sites → Jobs → Individual Job records

**Visibility Breakdown**:
| Location | Visibility | License Info Displayed |
|----------|-----------|----------------------|
| Individual Job Detail Pages | ✅ Visible | ✅ Yes (CBDU89939, 02/04/2028) |
| Compliance Tab Grouping | ❌ Not Visible | N/A (filtered out by query) |

**This is existing business logic** - the Compliance tab was designed to show grouped supplier/depot compliance views, requiring both supplier AND depot to be assigned.

**No action taken** - this behavior matches the original system design and business requirements.

---

## Related Information

### Related Classes & Components

**Trigger for Automatic Sharing**:
- `CommunityAccessHelper.cls` - Automatically creates AccountShare records for suppliers when HQ users have access to sites
- Logic (Line 37): Only creates shares for users with `Contact.Community_Role__c = 'HQ'`

**Test Classes**:
- `Utility_CommunityTest.cls` - Test class for Utility_Community (used in deployment)

**Other Portal Layouts**:
- `Account-RLES Supplier - Customer Community.layout-meta.xml` - Portal layout for Account records
- `Depot__c-Portal Layout.layout-meta.xml` - Portal layout for Depot records

### Community Role Distribution

**System-Wide Portal Users** (914 active):
- **137 users** (15%) have `Community_Role__c = 'HQ'` - Can see supplier licenses ✅
- **183 users** (20%) have `Community_Role__c = 'Site'` - Site-level access only
- **594 users** (65%) have `Community_Role__c = null` - Not configured (data quality issue)

### Community Role Guidelines

**When to set Community_Role__c = 'HQ'**:
- Head office users
- Procurement staff
- Facilities management
- Senior site management
- Anyone who needs to verify supplier compliance

**When to set Community_Role__c = 'Site'**:
- On-site workers
- Day-to-day operations staff
- Users who don't need supplier compliance visibility

**When to leave Community_Role__c = null**:
- **Never** - this should always be set (currently 594 users need review)

---

## Migration to NewOrg

**NewOrg Migration Package**: [View Here](https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/bam-construct-portal-license)

**Deployment Order for NewOrg**:
1. Deploy formula field `Waste_Carrier_License_Expiry__c`
2. Grant field-level security to all community profiles (Apex script)
3. Deploy Job portal layout
4. Deploy Apex class and LWC components (with test class)
5. Configure Community_Role__c for HQ users
6. Create manual sharing records for existing users/suppliers (or use bulk script)
7. Test with actual portal users

**Estimated Deployment Time**: 1.5-2 hours (including testing)

---

## GitHub Repository Links

**This Document (OldOrg State)**:
https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/bam-construct-portal-license

**NewOrg Migration Package**:
https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/bam-construct-portal-license

---

**OldOrg State Documentation Complete** ✅
**Documented By**: Claude
**Date**: October 23, 2025
**Next Step**: Create NewOrg migration package with gap analysis
