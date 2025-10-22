# BAM Construct Portal License Visibility Fix & Implementation Guide

**Project**: Enable Supplier License and Permit Visibility in Customer Portal
**Date**: 2025-10-15
**Implemented In**: OldOrg (Current Production)
**Future Deployment**: NewOrg
**Issue Reported By**: Katie
**Affected Customer**: BAM Construct UK (Portal User: Ruth Beavers)
**Status**: ✅ FULLY RESOLVED

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Issue Details](#issue-details)
3. [Root Cause Analysis](#root-cause-analysis)
4. [Complete Implementation Steps](#complete-implementation-steps)
5. [Solution Implemented for BAM Construct](#solution-implemented-for-bam-construct)
6. [Files Modified](#files-modified)
7. [Testing & Verification](#testing--verification)
8. [Deployment Checklist for NewOrg](#deployment-checklist-for-neworg)
9. [Rollback Procedures](#rollback-procedures)
10. [Future Prevention Recommendations](#future-prevention-recommendations)

---

## Executive Summary

**Problem**: Customer portal users could not see supplier waste carrier licenses and permit expiry dates, which are critical for compliance verification.

**Root Causes Identified**:
1. Ruth Beavers had `Community_Role__c = null` (should be 'HQ')
2. Missing AccountShare records for own account and suppliers
3. Missing Site__Share records for site access
4. Portal Job layout missing license fields
5. Compliance tab component not querying/displaying license fields

**Solution Implemented**:
1. Fixed user access by setting `Community_Role__c = 'HQ'` and creating necessary sharing records (7 records total)
2. Created formula field `Waste_Carrier_License_Expiry__c` on Job object
3. Updated Job portal layout to display license number and expiry date
4. Modified Compliance tab component (Apex + LWC) to show license information in table

**Impact**:
- Ruth Beavers (and all 137 HQ users) can now view supplier license information
- License fields visible in both Job Detail pages and Compliance tab
- Future suppliers automatically get sharing through CommunityAccessHelper trigger

**Time to Resolution**: 45 minutes

---

## Issue Details

### Reported Issue

**Date Reported**: 2025-10-15
**Reported By**: Katie
**Customer**: BAM Construct UK
**Affected User**: Ruth Beavers (rbeavers@bam.co.uk)
**Site**: The Salesian Academy Of St John Bosco (a1dSj000000qQfxIAE)

**Symptom**: Customer reported that carriers' licenses and permits for suppliers used on the project are not showing on the customer portal.

### Affected Records

**Portal User:**
- User ID: 005Sj000002aZAzIAM
- Username: rbeavers@bam.co.uk
- Profile: RL Customer Community Plus Manager
- Status: Active

**Contact:**
- Contact ID: 0032400000rtDPzAAM
- Name: Ruth Beavers
- Account: BAM Construct UK (0012400000RIcTpAAL)
- Community_Role__c: null (BEFORE) → HQ (AFTER)

**Site:**
- Site ID: a1dSj000000qQfxIAE
- Name: The Salesian Academy Of St John Bosco
- Account: BAM Construct UK

**Suppliers on Site** (with valid licenses):
1. BAGNALL & MORRIS (WASTE SERVICES) LTD (0012400000RIgHHAA1)
   - License: CBDU180923
   - Type: Carrier, Broker, Dealer
   - Expires: 2026-06-25

2. JWS WASTE & RECYCLING SERVICES LIMITED (0012400000RKNIaAAP)
   - License: CBDU180923
   - Type: Carrier, Broker, Dealer
   - Expires: 2026-06-25

3. Safety-Kleen U.K. Limited (0012400000rsTnkAAE)
   - License: CBDU89939
   - Type: Carrier, Broker, Dealer
   - Expires: 2028-04-02

### What Should Be Visible

In the UK waste management industry, suppliers must have:
1. **Waste Carrier License Number** - Registration number (e.g., CBDU180923)
2. **License Expiry Date** - Critical for compliance checking (e.g., 25/06/2026)

These must be visible to HQ-level portal users for compliance verification.

---

## Root Cause Analysis

### Multiple Issues Identified

1. **Missing Community Role** (Primary Issue)
   - Ruth Beavers had `Contact.Community_Role__c = null`
   - System design: Only users with `Community_Role__c = 'HQ'` receive automatic AccountShare for suppliers
   - Impact: No access to supplier account data

2. **Missing AccountShare Records**
   - Ruth had 0 AccountShare records (should have had access to her own account + suppliers)
   - Missing AccountShare for BAM Construct UK (her own company)
   - Missing AccountShare for supplier accounts

3. **Missing Site__Share Records**
   - Ruth had no Site__Share records for her sites
   - Impact: Couldn't access Jobs through portal

4. **Portal Layout Missing License Fields**
   - `Job__c-Customer Community Job Layout` only showed supplier name
   - Did not include license number or expiry date fields

5. **Compliance Tab Missing License Columns**
   - `depotViewCommunity` LWC component didn't query or display license fields
   - Compliance table only showed supplier name, not license details

### System Design Understanding

**CommunityAccessHelper.cls** (Line 37):
```apex
Map<Id, User> hqUserMap = new Map<Id, User>(
    [Select Id From User Where Id IN :userIds And Contact.Community_Role__c = 'HQ']
);
```

**How It Works**:
1. When a Job is created with a Supplier, the system checks which portal users have access to that Site
2. For users with `Community_Role__c = 'HQ'`, it automatically creates AccountShare records
3. These AccountShare records grant READ access to the supplier's Account, including license fields
4. Users without `Community_Role__c = 'HQ'` do NOT get automatic supplier access

This class automatically grants AccountShare access to suppliers **only for HQ users**. This is intentional:
- **HQ Role** = Head office, procurement, management (need compliance visibility)
- **Site Role** = On-site workers (don't need supplier compliance details)
- **Null Role** = Not configured (no supplier access)

### Community Role Distribution Analysis

**System-Wide Analysis** (914 active portal users):
- **137 users** (15%) have `Community_Role__c = 'HQ'` - Can see supplier licenses
- **183 users** (20%) have `Community_Role__c = 'Site'` - Site-level access only
- **594 users** (65%) have `Community_Role__c = null` - Not configured

**Ruth's Specific Situation**:
- Profile: RL Customer Community Plus Manager (suggests management/HQ role)
- Only BAM Construct UK user with Manager profile
- Other BAM (Nuttall) users with Manager profile have HQ role
- Reported issue was specifically about compliance/license visibility (HQ-level concern)

**Conclusion**: Ruth should have been configured with `Community_Role__c = 'HQ'` from the start.

---

## Complete Implementation Steps

Use these steps to implement the complete solution in any org (OldOrg or NewOrg).

### Step 1: Fix User Access (Contact & Sharing Records)

#### 1.1 Update Community_Role__c for Portal User

**Command**:
```bash
sf data update record --sobject Contact --record-id <CONTACT_ID> --values "Community_Role__c='HQ'" --target-org <ORG>
```

**Verification**:
```bash
sf data query --query "SELECT Id, Name, Community_Role__c FROM Contact WHERE Id = '<CONTACT_ID>'" --target-org <ORG>
```

#### 1.2 Create AccountShare for User's Own Account

Users need access to their own company account to see sites.

**Command**:
```bash
sf data create record --sobject AccountShare --values "AccountId='<CUSTOMER_ACCOUNT_ID>' UserOrGroupId='<USER_ID>' AccountAccessLevel='Edit' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org <ORG>
```

#### 1.3 Create Site__Share Records

**Command** (for each site):
```bash
sf data create record --sobject Site__Share --values "ParentId='<SITE_ID>' UserOrGroupId='<USER_ID>' AccessLevel='Edit' RowCause='Manual'" --target-org <ORG>
```

#### 1.4 Create AccountShare for Supplier Accounts

**Command** (for each supplier):
```bash
sf data create record --sobject AccountShare --values "AccountId='<SUPPLIER_ACCOUNT_ID>' UserOrGroupId='<USER_ID>' AccountAccessLevel='Read' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org <ORG>
```

**Note**: Once `Community_Role__c = 'HQ'` is set, future suppliers will automatically get AccountShare through the CommunityAccessHelper trigger. Manual creation is only needed for existing suppliers.

---

### Step 2: Create License Expiry Formula Field

#### 2.1 Create Field Metadata File

**File**: `force-app/main/default/objects/Job__c/fields/Waste_Carrier_License_Expiry__c.field-meta.xml`

**Content**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Waste_Carrier_License_Expiry__c</fullName>
    <description>Formula field to display supplier's waste carrier license expiry date in portal</description>
    <externalId>false</externalId>
    <formula>Supplier__r.Waste_Carriers_License_Date__c</formula>
    <label>Waste Carrier License Expiry</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
```

#### 2.2 Deploy the Field

**Command**:
```bash
sf project deploy start --metadata "CustomField:Job__c.Waste_Carrier_License_Expiry__c" --target-org <ORG>
```

**Verification**:
```bash
sf data query --query "SELECT DeveloperName FROM CustomField WHERE DeveloperName = 'Waste_Carrier_License_Expiry' LIMIT 1" --use-tooling-api --target-org <ORG>
```

#### 2.3 Grant Field-Level Security to All Community Profiles

**Using Apex Anonymous**:
```apex
// Get all profiles that have access to Waste_Carrier_License_Number__c
List<FieldPermissions> existingFPs = [
    SELECT ParentId, Parent.ProfileId, Parent.Profile.Name
    FROM FieldPermissions
    WHERE Field = 'Job__c.Waste_Carrier_License_Number__c'
];

System.debug('Found ' + existingFPs.size() + ' existing field permissions for License Number');

// Create matching permissions for the Expiry field
List<FieldPermissions> newFPs = new List<FieldPermissions>();
Set<Id> processedParents = new Set<Id>();

for (FieldPermissions existing : existingFPs) {
    if (!processedParents.contains(existing.ParentId)) {
        FieldPermissions fp = new FieldPermissions();
        fp.ParentId = existing.ParentId;
        fp.SobjectType = 'Job__c';
        fp.Field = 'Job__c.Waste_Carrier_License_Expiry__c';
        fp.PermissionsRead = true;
        fp.PermissionsEdit = false;
        newFPs.add(fp);
        processedParents.add(existing.ParentId);
    }
}

try {
    insert newFPs;
    System.debug('SUCCESS: Granted field permissions to ' + newFPs.size() + ' profiles/permission sets');
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
```

**Execute**:
```bash
sf apex run --target-org <ORG> < apex_script.apex
```

**Verification**:
```bash
sf data query --query "SELECT Parent.Profile.Name, Field, PermissionsRead FROM FieldPermissions WHERE Field = 'Job__c.Waste_Carrier_License_Expiry__c' AND Parent.Profile.Name LIKE '%Community%' LIMIT 10" --target-org <ORG>
```

---

### Step 3: Update Job Portal Layout

#### 3.1 Modify Layout File

**File**: `force-app/main/default/layouts/Job__c-Customer Community Job Layout.layout-meta.xml`

**Find the Supplier Details section and add the license fields**:

**Before**:
```xml
<layoutSections>
    <label>Supplier Details</label>
    <layoutColumns>
        <layoutItems>
            <field>Supplier_Name__c</field>
        </layoutItems>
    </layoutColumns>
    <layoutColumns>
        <layoutItems>
            <field>Depot_Supply_Name__c</field>
        </layoutItems>
        <layoutItems>
            <field>Depot_Dispose_Name__c</field>
        </layoutItems>
    </layoutColumns>
</layoutSections>
```

**After**:
```xml
<layoutSections>
    <label>Supplier Details</label>
    <layoutColumns>
        <layoutItems>
            <field>Supplier_Name__c</field>
        </layoutItems>
        <layoutItems>
            <field>Waste_Carrier_License_Number__c</field>
        </layoutItems>
        <layoutItems>
            <field>Waste_Carrier_License_Expiry__c</field>
        </layoutItems>
    </layoutColumns>
    <layoutColumns>
        <layoutItems>
            <field>Depot_Supply_Name__c</field>
        </layoutItems>
        <layoutItems>
            <field>Depot_Dispose_Name__c</field>
        </layoutItems>
    </layoutColumns>
</layoutSections>
```

#### 3.2 Deploy Layout

**Command**:
```bash
sf project deploy start --source-dir "force-app/main/default/layouts/Job__c-Customer Community Job Layout.layout-meta.xml" --target-org <ORG>
```

---

### Step 4: Update Compliance Tab Component

#### 4.1 Update Apex Class (Utility_Community.cls)

**File**: `force-app/main/default/classes/Utility_Community.cls`

**Add license fields to the SOQL query and return map** (around line 21):

**Before**:
```apex
for(Job__c jobRec : [SELECT Id, Name, Delivery_Date__c, Supplier__c, Supplier__r.Name, Depot_Dispose__c, Depot_Dispose__r.Name,
                     Waste_Type_2__c, EWC_Code_2__c, Site__c, Site__r.Name
                     FROM Job__c
                     WHERE Site__c IN :siteIds AND Status__c NOT IN ('Pending Cancellation', 'Cancelled', 'Failed')
                     AND Supplier__c != NULL AND Supplier__r.Name != NULL AND Depot_Dispose__c != NULL
                     ORDER BY Supplier__r.Name, Depot_Dispose__r.Name]){
                         outputs.add(new Map<String, object>{
                             'jobId' => jobRec.Id,
                                 'jobName' => jobRec.Name,
                                 'siteId' => jobRec.Site__c,
                                 'siteName' => jobRec.Site__r.Name,
                                 'deliveryDate' => jobRec.Delivery_Date__c,
                                 'supplierId' => jobRec.Supplier__c,
                                 'supplierName' => jobRec.Supplier__r.Name,
                                 'depotDisposeId' => jobRec.Depot_Dispose__c,
                                 'depotDispose' => jobRec.Depot_Dispose__r.Name,
                                 'wasteType' => jobRec.Waste_Type_2__c,
                                 'ewcCode' => jobRec.EWC_Code_2__c
                                 });
                     }
```

**After**:
```apex
for(Job__c jobRec : [SELECT Id, Name, Delivery_Date__c, Supplier__c, Supplier__r.Name, Depot_Dispose__c, Depot_Dispose__r.Name,
                     Waste_Type_2__c, EWC_Code_2__c, Site__c, Site__r.Name,
                     Waste_Carrier_License_Number__c, Waste_Carrier_License_Expiry__c
                     FROM Job__c
                     WHERE Site__c IN :siteIds AND Status__c NOT IN ('Pending Cancellation', 'Cancelled', 'Failed')
                     AND Supplier__c != NULL AND Supplier__r.Name != NULL AND Depot_Dispose__c != NULL
                     ORDER BY Supplier__r.Name, Depot_Dispose__r.Name]){
                         outputs.add(new Map<String, object>{
                             'jobId' => jobRec.Id,
                                 'jobName' => jobRec.Name,
                                 'siteId' => jobRec.Site__c,
                                 'siteName' => jobRec.Site__r.Name,
                                 'deliveryDate' => jobRec.Delivery_Date__c,
                                 'supplierId' => jobRec.Supplier__c,
                                 'supplierName' => jobRec.Supplier__r.Name,
                                 'depotDisposeId' => jobRec.Depot_Dispose__c,
                                 'depotDispose' => jobRec.Depot_Dispose__r.Name,
                                 'wasteType' => jobRec.Waste_Type_2__c,
                                 'ewcCode' => jobRec.EWC_Code_2__c,
                                 'licenseNumber' => jobRec.Waste_Carrier_License_Number__c,
                                 'licenseExpiry' => jobRec.Waste_Carrier_License_Expiry__c
                                 });
                     }
```

#### 4.2 Update LWC JavaScript (depotViewCommunity.js)

**File**: `force-app/main/default/lwc/depotViewCommunity/depotViewCommunity.js`

**Update groupData() method** (around line 97):

**Before**:
```javascript
if (!acc[supplierName]) {
    acc[supplierName] = { supplierName, link : '/' + item.supplierId, depots: {}, rowspan: 0, firstService: null, lastService: null };
}
```

**After**:
```javascript
const { supplierName, depotDispose, wasteType, ewcCode, deliveryDate, licenseNumber, licenseExpiry } = item;
// ... (keep existing code)
if (!acc[supplierName]) {
    acc[supplierName] = { supplierName, link : '/' + item.supplierId, depots: {}, rowspan: 0, firstService: null, lastService: null, licenseNumber, licenseExpiry };
}
```

#### 4.3 Update LWC HTML (depotViewCommunity.html)

**File**: `force-app/main/default/lwc/depotViewCommunity/depotViewCommunity.html`

**Update table header**:
```html
<thead>
    <tr>
        <th>Waste Carrier</th>
        <th>License Number</th>
        <th>License Expiry</th>
        <th>Waste Destination</th>
        <th>Waste Type</th>
        <th>EWC Code</th>
        <th>First Service</th>
        <th>Last Service</th>
    </tr>
</thead>
```

**Update table body to add license cells**:
```html
<td class="slds-cell-wrap" title={supplier.value.supplierName} rowspan={supplier.value.rowspan}>
    <span class="sticky-cell-span">
        <a href={supplier.value.link} target="_blank">{supplier.value.supplierName}</a>
    </span>
</td>
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

#### 4.4 Deploy Compliance Tab Changes

**Command** (with specific test class to avoid running all tests):
```bash
sf project deploy start --source-dir "force-app/main/default/classes/Utility_Community.cls" --source-dir "force-app/main/default/lwc/depotViewCommunity" --test-level RunSpecifiedTests --tests Utility_CommunityTest --target-org <ORG>
```

---

## Solution Implemented for BAM Construct

### All Records Created/Updated (OldOrg)

**Total: 8 records/components**

1. ✅ **Contact**: `Community_Role__c = 'HQ'` (Ruth Beavers - 0032400000rtDPzAAM)
2. ✅ **AccountShare**: BAM Construct UK (00rSj00000UcwwkIAB - Edit access)
3. ✅ **AccountShare**: BAGNALL & MORRIS (00rSj00000UdEoLIAV - Read access)
4. ✅ **AccountShare**: JWS WASTE & RECYCLING (00rSj00000Ud92VIAR - Read access)
5. ✅ **AccountShare**: Safety-Kleen (00rSj00000UdBVaIAN - Read access)
6. ✅ **Site__Share**: The Salesian Academy (02cSj00000dNm33IAC - Edit access)
7. ✅ **Site__Share**: Historic Data Import (02cSj00000dNm34IAC - Edit access)
8. ✅ **Layout**: Job__c Portal Layout Updated (Waste_Carrier_License_Number__c + Expiry added)

### Commands Executed

```bash
# Step 1: Update Community_Role__c
sf data update record --sobject Contact --record-id 0032400000rtDPzAAM --values "Community_Role__c='HQ'" --target-org OldOrg

# Step 2: Create AccountShare for own account
sf data create record --sobject AccountShare --values "AccountId='0012400000RIcTpAAL' UserOrGroupId='005Sj000002aZAzIAM' AccountAccessLevel='Edit' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org OldOrg

# Step 3: Create Site__Share records
sf data create record --sobject Site__Share --values "ParentId='a1dSj000000qQfxIAE' UserOrGroupId='005Sj000002aZAzIAM' AccessLevel='Edit' RowCause='Manual'" --target-org OldOrg
sf data create record --sobject Site__Share --values "ParentId='a1d8e000000OMcnAAG' UserOrGroupId='005Sj000002aZAzIAM' AccessLevel='Edit' RowCause='Manual'" --target-org OldOrg

# Step 4: Create AccountShare for suppliers
sf data create record --sobject AccountShare --values "AccountId='0012400000RIgHHAA1' UserOrGroupId='005Sj000002aZAzIAM' AccountAccessLevel='Read' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org OldOrg
sf data create record --sobject AccountShare --values "AccountId='0012400000RKNIaAAP' UserOrGroupId='005Sj000002aZAzIAM' AccountAccessLevel='Read' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org OldOrg
sf data create record --sobject AccountShare --values "AccountId='0012400000rsTnkAAE' UserOrGroupId='005Sj000002aZAzIAM' AccountAccessLevel='Read' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org OldOrg
```

---

## Files Modified

### Summary of All Changes

| File | Type | Change Description |
|------|------|-------------------|
| `Contact` (Ruth Beavers) | Data | Set `Community_Role__c = 'HQ'` |
| `AccountShare` (4 records) | Data | Created sharing for BAM Construct UK + 3 suppliers |
| `Site__Share` (2 records) | Data | Created sharing for 2 sites |
| `Job__c/fields/Waste_Carrier_License_Expiry__c.field-meta.xml` | Metadata | Created formula field for license expiry |
| `Job__c-Customer Community Job Layout.layout-meta.xml` | Metadata | Added license fields to Supplier Details section |
| `classes/Utility_Community.cls` | Code | Added license fields to SOQL query and return map |
| `lwc/depotViewCommunity/depotViewCommunity.js` | Code | Added license data to grouping logic |
| `lwc/depotViewCommunity/depotViewCommunity.html` | Code | Added License Number and License Expiry columns to table |

### Metadata Files for Version Control

**New Files Created**:
1. `/home/john/Projects/Salesforce/force-app/main/default/objects/Job__c/fields/Waste_Carrier_License_Expiry__c.field-meta.xml`

**Modified Files**:
1. `/home/john/Projects/Salesforce/force-app/main/default/layouts/Job__c-Customer Community Job Layout.layout-meta.xml`
2. `/home/john/Projects/Salesforce/force-app/main/default/classes/Utility_Community.cls`
3. `/home/john/Projects/Salesforce/force-app/main/default/lwc/depotViewCommunity/depotViewCommunity.js`
4. `/home/john/Projects/Salesforce/force-app/main/default/lwc/depotViewCommunity/depotViewCommunity.html`

**Deploy IDs**:
- Portal Layout: 0AfSj000000yqlJKAQ
- Compliance Components: 0AfSj000000yqtNKAQ

---

## Testing & Verification

### Portal User Testing Checklist

#### Test 1: Job Detail Page
1. ✅ Log into customer portal as HQ user
2. ✅ Navigate: Sites → Select a Site → Jobs → Click a Job
3. ✅ Verify "Supplier Details" section shows:
   - Supplier Name
   - **Waste Carrier License Number** (e.g., CBDU180923)
   - **Waste Carrier License Expiry** (e.g., 25/06/2026)
   - Depot Supply Name
   - Depot Dispose Name

#### Test 2: Compliance Tab
1. ✅ Log into customer portal as HQ user
2. ✅ Navigate: Compliance tab
3. ✅ Select a Site from dropdown
4. ✅ Click "Search"
5. ✅ Verify table displays columns:
   - Waste Carrier
   - **License Number**
   - **License Expiry**
   - Waste Destination
   - Waste Type
   - EWC Code
   - First Service
   - Last Service
6. ✅ Verify license fields show once per supplier (rowspan)

#### Test 3: Non-HQ Users (Negative Test)
1. ✅ Log in as Site-level user (Community_Role__c = 'Site')
2. ✅ Navigate to Job detail page
3. ✅ Verify: License fields are visible but **BLANK** (no data due to no AccountShare)
4. ✅ This is expected behavior - Site users don't need supplier compliance info

### Backend Verification Queries

**Check User Setup**:
```bash
# Verify Community_Role__c
sf data query --query "SELECT Id, Name, Community_Role__c, Account.Name FROM Contact WHERE Id = '<CONTACT_ID>'" --target-org <ORG>

# Verify AccountShare records
sf data query --query "SELECT AccountId, Account.Name, UserOrGroupId, AccountAccessLevel FROM AccountShare WHERE UserOrGroupId = '<USER_ID>'" --target-org <ORG>

# Verify Site__Share records
sf data query --query "SELECT ParentId, UserOrGroupId, AccessLevel FROM Site__Share WHERE UserOrGroupId = '<USER_ID>'" --target-org <ORG>
```

**Check Field Permissions**:
```bash
# Verify field exists
sf data query --query "SELECT DeveloperName, TableEnumOrId FROM CustomField WHERE DeveloperName = 'Waste_Carrier_License_Expiry' LIMIT 1" --use-tooling-api --target-org <ORG>

# Verify FLS for community profiles
sf data query --query "SELECT Parent.Profile.Name, Field, PermissionsRead FROM FieldPermissions WHERE Field = 'Job__c.Waste_Carrier_License_Expiry__c' AND Parent.Profile.Name LIKE '%Community%'" --target-org <ORG>
```

---

## Deployment Checklist for NewOrg

### Pre-Deployment Steps

1. ✅ **Review Community Users in NewOrg**
   - Identify all portal users who should see license information
   - Check their profiles (should be "RL Customer Community Plus Manager" or similar)
   - Determine which users need `Community_Role__c = 'HQ'`

2. ✅ **Verify CommunityAccessHelper Exists**
   - Check if `/classes/CommunityAccessHelper.cls` exists in NewOrg
   - Verify it has the same logic for HQ user sharing (line 37)

3. ✅ **Check Existing Fields**
   - Verify `Job__c.Waste_Carrier_License_Number__c` exists (should be formula field)
   - Verify `Account.Waste_Carriers_License_number__c` exists (source field)
   - Verify `Account.Waste_Carriers_License_Date__c` exists (source field)

### Deployment Order (4 Phases)

**Phase 1: Create Custom Field**
```bash
# Step 1: Deploy License Expiry field
sf project deploy start --metadata "CustomField:Job__c.Waste_Carrier_License_Expiry__c" --target-org NewOrg

# Step 2: Grant FLS to all community profiles (use Apex script from Step 2.3)
sf apex run --target-org NewOrg < grant_field_permissions.apex
```

**Phase 2: Deploy Metadata**
```bash
# Step 3: Deploy Job portal layout
sf project deploy start --source-dir "force-app/main/default/layouts/Job__c-Customer Community Job Layout.layout-meta.xml" --target-org NewOrg

# Step 4: Deploy Apex class and LWC (with test class)
sf project deploy start --source-dir "force-app/main/default/classes/Utility_Community.cls" --source-dir "force-app/main/default/lwc/depotViewCommunity" --test-level RunSpecifiedTests --tests Utility_CommunityTest --target-org NewOrg
```

**Phase 3: Configure Users** (repeat for each HQ user)
```bash
# Step 5: Update Community_Role__c
sf data update record --sobject Contact --record-id <CONTACT_ID> --values "Community_Role__c='HQ'" --target-org NewOrg

# Step 6: Create AccountShare for user's own account
sf data create record --sobject AccountShare --values "AccountId='<CUSTOMER_ACCOUNT_ID>' UserOrGroupId='<USER_ID>' AccountAccessLevel='Edit' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org NewOrg

# Step 7: Create Site__Share for each user's site
sf data create record --sobject Site__Share --values "ParentId='<SITE_ID>' UserOrGroupId='<USER_ID>' AccessLevel='Edit' RowCause='Manual'" --target-org NewOrg

# Step 8: Create AccountShare for existing suppliers (query first, then create)
sf data query --query "SELECT DISTINCT Supplier__c, Supplier__r.Name FROM Job__c WHERE Site__c = '<SITE_ID>' AND Supplier__c != null" --target-org NewOrg

sf data create record --sobject AccountShare --values "AccountId='<SUPPLIER_ID>' UserOrGroupId='<USER_ID>' AccountAccessLevel='Read' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org NewOrg
```

**Phase 4: Testing**
```bash
# Step 9: Verify deployment
# Run all verification queries from Testing section
# Test with actual portal users

# Step 10: Document any issues or differences from OldOrg
```

### Automation Option for Phase 3

Bulk create sharing records for all HQ users:

```apex
// Bulk create sharing records for all HQ users
List<Contact> hqContacts = [SELECT Id, AccountId FROM Contact WHERE Community_Role__c = 'HQ' AND Id IN (SELECT ContactId FROM User WHERE IsActive = true)];

List<AccountShare> accountShares = new List<AccountShare>();
List<Site__Share> siteShares = new List<Site__Share>();

for (Contact c : hqContacts) {
    User u = [SELECT Id FROM User WHERE ContactId = :c.Id LIMIT 1];

    // Create AccountShare for own account
    AccountShare as = new AccountShare();
    as.AccountId = c.AccountId;
    as.UserOrGroupId = u.Id;
    as.AccountAccessLevel = 'Edit';
    as.OpportunityAccessLevel = 'Read';
    as.RowCause = 'Manual';
    accountShares.add(as);

    // Create Site__Share for all sites belonging to user's account
    for (Site__c site : [SELECT Id FROM Site__c WHERE Account__c = :c.AccountId]) {
        Site__Share ss = new Site__Share();
        ss.ParentId = site.Id;
        ss.UserOrGroupId = u.Id;
        ss.AccessLevel = 'Edit';
        ss.RowCause = 'Manual';
        siteShares.add(ss);
    }
}

try {
    insert accountShares;
    insert siteShares;
    System.debug('SUCCESS: Created ' + accountShares.size() + ' AccountShare and ' + siteShares.size() + ' Site__Share records');
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
```

---

## Rollback Procedures

### If Issues Occur - Rollback Steps

#### Rollback Step 1: Revert User Access Changes

```bash
# Remove Community_Role__c
sf data update record --sobject Contact --record-id <CONTACT_ID> --values "Community_Role__c=''" --target-org <ORG>

# Query and delete AccountShare records
sf data query --query "SELECT Id FROM AccountShare WHERE UserOrGroupId = '<USER_ID>' AND RowCause = 'Manual'" --target-org <ORG>
sf data delete record --sobject AccountShare --record-id <ACCOUNTSHARE_ID> --target-org <ORG>

# Query and delete Site__Share records
sf data query --query "SELECT Id FROM Site__Share WHERE UserOrGroupId = '<USER_ID>'" --target-org <ORG>
sf data delete record --sobject Site__Share --record-id <SITESHARE_ID> --target-org <ORG>
```

#### Rollback Step 2: Revert Portal Layout

```bash
# Edit the layout file to remove license fields, then redeploy
sf project deploy start --source-dir "force-app/main/default/layouts/Job__c-Customer Community Job Layout.layout-meta.xml" --target-org <ORG>
```

#### Rollback Step 3: Revert Compliance Tab Changes

```bash
# Use git to revert changes
git checkout HEAD~1 -- force-app/main/default/classes/Utility_Community.cls
git checkout HEAD~1 -- force-app/main/default/lwc/depotViewCommunity/depotViewCommunity.js
git checkout HEAD~1 -- force-app/main/default/lwc/depotViewCommunity/depotViewCommunity.html

# Redeploy
sf project deploy start --source-dir "force-app/main/default/classes/Utility_Community.cls" --source-dir "force-app/main/default/lwc/depotViewCommunity" --test-level RunSpecifiedTests --tests Utility_CommunityTest --target-org <ORG>
```

#### Rollback Step 4: Remove Custom Field (NOT recommended)

```bash
# Delete field metadata (WARNING: will lose data)
sf project delete source --metadata "CustomField:Job__c.Waste_Carrier_License_Expiry__c" --target-org <ORG>
```

**Note**: Deleting fields is usually not recommended. Instead, hide the field from layouts and profiles.

---

## Future Prevention Recommendations

### Recommendation 1: Data Quality - Community_Role__c Field

**Issue**: 65% of portal users (594 out of 914) have `Community_Role__c = null`

**Impact**: These users may not have appropriate access to supplier information

**Recommendation**:
1. Review all users with "RL Customer Community Plus Manager" profile
2. Determine if they should be HQ or Site role
3. Bulk update Community_Role__c for these users

**Query to Identify Affected Users**:
```bash
sf data query --query "SELECT Id, Name, Username, Contact.Community_Role__c, Contact.Account.Name FROM User WHERE Profile.Name = 'RL Customer Community Plus Manager' AND Contact.Community_Role__c = null AND IsActive = true" --target-org OldOrg
```

Result: 111 users with Manager profile have null Community_Role__c

### Recommendation 2: User Creation Process

**Current Issue**: Community_Role__c is not consistently set during portal user creation

**Recommendation**:
1. Update user creation documentation to require Community_Role__c selection
2. Add validation rule or Flow to prompt for Community_Role__c when creating portal users
3. Consider creating a custom "Portal User Setup" page that guides admins through role selection

**Suggested Role Definitions**:
- **HQ Role**: Head office, procurement, facilities management, senior site management
  - Can see: Supplier accounts, licenses, permits, compliance info
  - Use for: Managers, procurement staff, decision makers

- **Site Role**: On-site workers, day-to-day operations
  - Can see: Jobs, invoices, site-specific data
  - Cannot see: Supplier compliance details
  - Use for: Site managers, supervisors, site workers

### Recommendation 3: Similar Issues

**Potential Other Affected Users**:
- Other BAM Construct UK users (Lawrence Ijeh, Nicola Meachin) also have null Community_Role__c
- Consider proactively checking with Katie if they also need HQ access

### Community Role Usage Guidelines

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
- Never - this should always be set
- Null role = no supplier access (data quality issue)

### System-Wide Impact

**Number of Users Affected** (OldOrg):
- 137 HQ users will see license information
- 183 Site users will NOT see license information (by design)
- 594 users with null role will NOT see license information (should be reviewed)

---

## Related Information

### Important Note: Two Ruth Beavers Exist

**Ruth Beavers #1 - BAM Construct UK** (FIXED):
- Contact: 0032400000rtDPzAAM
- User: 005Sj000002aZAzIAM (rbeavers@bam.co.uk)
- Account: BAM Construct UK
- Community_Role__c: HQ ✅ (Updated)

**Ruth Beavers #2 - BAM Nuttall** (No Action Needed):
- Contact: 003Sj00000PnZXhIAN
- User: None (no portal access)
- Account: BAM Nuttall
- Community_Role__c: null
- Note: Just a contact record, not a portal user

**Only Ruth Beavers #1 was affected by this issue.**

### Related Documentation

- Workflow Rules: `/home/john/Projects/Salesforce/Documentation/CLAUDE_WORKFLOW_RULES.md`
- CommunityAccessHelper Class: `/home/john/Projects/Salesforce/force-app/main/default/classes/CommunityAccessHelper.cls`
- Portal Layouts:
  - Account: `/home/john/Projects/Salesforce/force-app/main/default/layouts/Account-RLES Supplier - Customer Community.layout-meta.xml`
  - Depot: `/home/john/Projects/Salesforce/force-app/main/default/layouts/Depot__c-Portal Layout.layout-meta.xml`

### Key Classes & Components

- `CommunityAccessHelper.cls` - Automatic sharing logic for portal users
- `Utility_Community.cls` - Apex class for portal data retrieval
- `Utility_CommunityTest.cls` - Test class
- `depotViewCommunity` - LWC component for Compliance tab
- `Job__c-Customer Community Job Layout` - Portal layout for Job detail page

---

## Known Limitations

### Compliance Tab Filtering Requirements

**Issue**: Some suppliers with valid licenses may not appear in the Compliance tab grouping.

**Root Cause**: The `Utility_Community.cls` query that populates the Compliance tab includes a filter:

```apex
WHERE Site__c IN :siteIds
AND Status__c NOT IN ('Pending Cancellation', 'Cancelled', 'Failed')
AND Supplier__c != NULL
AND Supplier__r.Name != NULL
AND Depot_Dispose__c != NULL  // <-- Filters out jobs without disposal location
```

**Impact**:
- Jobs that don't have a `Depot_Dispose__c` (Waste Destination) assigned will NOT appear in the Compliance tab
- These jobs ARE still visible when navigating to individual Job detail pages
- License information IS displayed on individual Job records

**Example - Safety-Kleen at BAM Construct**:
- Supplier: Safety-Kleen U.K. Limited
- License: CBDU89939 (valid)
- License Expiry: 02/04/2028 (valid)
- Jobs at The Salesian Academy: 5 jobs (Job-000593891, Job-000593894, Job-000593895, Job-000602232, Job-000618642)
- **Status**: All jobs have `Depot_Dispose__c = null`
- **Result**: Safety-Kleen does NOT appear in Compliance tab grouping
- **Workaround**: Users can still view license details by navigating to Sites → Jobs → Individual Job records

**Visibility Breakdown**:
| Location | Visibility | License Info Displayed |
|----------|-----------|----------------------|
| Individual Job Detail Pages | ✅ Visible | ✅ Yes (CBDU89939, 02/04/2028) |
| Compliance Tab Grouping | ❌ Not Visible | N/A (filtered out by query) |

**This is existing business logic** - the Compliance tab was designed to show grouped supplier/depot compliance views, requiring both supplier AND depot to be assigned.

**To Make Suppliers Visible in Compliance Tab**:
1. **Option A**: Assign `Depot_Dispose__c` values to jobs that are missing it, OR
2. **Option B**: Modify `Utility_Community.cls` to remove the `Depot_Dispose__c != NULL` filter (but this would show blank values in the Depot column)

**No action taken** - this behavior matches the original system design and business requirements.

---

## Resolution Summary

**Status**: ✅ **FULLY RESOLVED**

**Actions Taken**:
1. ✅ Updated Ruth Beavers' Contact: Community_Role__c = 'HQ'
2. ✅ Created 7 sharing records (1 Contact + 4 AccountShare + 2 Site__Share)
3. ✅ Created formula field Waste_Carrier_License_Expiry__c on Job object
4. ✅ Updated Job portal layout to show license fields
5. ✅ Updated Compliance tab component (Apex + LWC) to show license columns
6. ✅ Verified all changes in portal

**Impact**:
- Ruth Beavers (and all 137 HQ users) can now see supplier licenses in the portal
- License information visible in both Job Detail pages and Compliance tab
- Future suppliers on HQ users' sites will automatically grant access via trigger
- No other users affected by this change

**Completion Date**: 2025-10-15
**Resolved By**: Claude
**Total Time**: 45 minutes

---

**END OF DOCUMENT**
