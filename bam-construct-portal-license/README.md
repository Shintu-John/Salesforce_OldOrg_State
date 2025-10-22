# BAM Construct Portal License Visibility Fix - OldOrg State

**Deployment Date**: October 15, 2025
**Deployed By**: Technical Team
**Status**: ✅ DEPLOYED & ACTIVE
**Org**: OldOrg (recyclinglives.my.salesforce.com)

---

## Overview

This scenario documents the implementation that enables supplier license and permit visibility in the customer portal for HQ users. The solution allows portal users (like BAM Construct UK) to view waste carrier license information for their suppliers.

### Business Problem Solved

**Reported By**: Katie
**Affected Customer**: BAM Construct UK (Portal User: Ruth Beavers)

**Issue**: Portal users could not see supplier waste carrier license numbers and expiry dates when viewing jobs in the portal.

**Business Need**: Customers need to verify their suppliers' licenses are valid for compliance and audit purposes.

**Impact**: All HQ users (137 users) can now see supplier license information in the portal.

---

## Components Deployed

### 1. Formula Field: Waste_Carrier_License_Expiry__c

**Object**: Job__c
**API Name**: Waste_Carrier_License_Expiry__c
**Type**: Formula (Date)
**Formula**: `Depot_Dispose__r.Waste_Carrier_License_Expiry_Date__c`

**Purpose**: Surfaces the depot's waste carrier license expiry date on the Job record for portal visibility.

**File**: `objects/Job__c/fields/Waste_Carrier_License_Expiry__c.field-meta.xml`

**Deploy ID**: 0AfSj000000yqlJKAQ

---

### 2. Layout: Customer Community Job Layout

**Object**: Job__c
**Layout Name**: Customer Community Job Layout
**API Name**: Job__c-Customer Community Job Layout

**Changes Made**:
Added license fields to "Supplier Details" section:
- Waste_Carrier_License_Number__c (existing field)
- Waste_Carrier_License_Expiry__c (new formula field)

**Location in Layout**: Supplier Details section, left column

**File**: `layouts/Job__c-Customer Community Job Layout.layout-meta.xml`

**Deploy ID**: 0AfSj000000yqlJKAQ

---

### 3. Apex Class: Utility_Community.cls

**Purpose**: Utility class for Community portal data retrieval

**Modifications Made** (October 15, 2025):

**Added License Fields to SOQL Query** (line ~21):

Before:
```apex
for(Job__c jobRec : [SELECT Id, Name, Delivery_Date__c, Supplier__c,
                     Supplier__r.Name, Depot_Dispose__c, Depot_Dispose__r.Name,
                     Waste_Type_2__c, EWC_Code_2__c, Site__c, Site__r.Name
                     FROM Job__c
                     WHERE Site__c IN :siteIds ...]) {
```

After:
```apex
for(Job__c jobRec : [SELECT Id, Name, Delivery_Date__c, Supplier__c,
                     Supplier__r.Name, Depot_Dispose__c, Depot_Dispose__r.Name,
                     Waste_Type_2__c, EWC_Code_2__c, Site__c, Site__r.Name,
                     Waste_Carrier_License_Number__c,
                     Waste_Carrier_License_Expiry__c
                     FROM Job__c
                     WHERE Site__c IN :siteIds ...]) {
```

**Added License Fields to Return Map**:
```apex
outputs.add(new Map<String, object>{
    // ... existing fields ...
    'licenseNumber' => jobRec.Waste_Carrier_License_Number__c,
    'licenseExpiry' => jobRec.Waste_Carrier_License_Expiry__c
});
```

**File**: `classes/Utility_Community.cls`

**Deploy ID**: 0AfSj000000yqtNKAQ

---

### 4. Lightning Web Component: depotViewCommunity

**Component Type**: LWC (Lightning Web Component)
**Purpose**: Displays depot/supplier information in Compliance tab

**Files Modified**:

**A. JavaScript** (`depotViewCommunity.js`):
- Added licenseNumber and licenseExpiry to grouping logic
- Included license data in supplier records array

**B. HTML** (`depotViewCommunity.html`):
- Added "License Number" column to data table
- Added "License Expiry" column to data table

**Deploy ID**: 0AfSj000000yqtNKAQ

---

### 5. Data Changes (Configuration)

**Contact Update**:
- Contact: Ruth Beavers (BAM Construct UK portal user)
- Field: Community_Role__c
- Value: Changed to "HQ"
- Purpose: Enables visibility of supplier information

**Sharing Records Created**:
- 4 AccountShare records (BAM Construct UK + 3 suppliers)
- 2 Site__Share records (2 sites)
- 1 Contact sharing rule

**Note**: These are data changes, not metadata deployments.

---

## Architecture

### Data Flow

```
1. User Views Job in Portal
   └─> Customer Community Job Layout
       └─> Shows Waste_Carrier_License_Number__c (existing)
       └─> Shows Waste_Carrier_License_Expiry__c (new formula)
           └─> Formula pulls from Depot_Dispose__r.Waste_Carrier_License_Expiry_Date__c

2. User Views Compliance Tab
   └─> depotViewCommunity LWC
       └─> Calls Utility_Community.getComplianceDetails()
           └─> SOQL retrieves license fields
           └─> Returns to LWC
       └─> LWC displays in table columns
```

---

## Testing Results (October 15, 2025)

**Test User**: Ruth Beavers (BAM Construct UK)

**Test 1: Job Detail Page** ✅
- Navigated to Job in portal
- Verified "Supplier Details" section shows license fields
- License Number: Displayed correctly
- License Expiry: Displayed correctly (from formula field)

**Test 2: Compliance Tab** ✅
- Navigated to Compliance tab
- Verified supplier table shows license columns
- License Number column: Visible and populated
- License Expiry column: Visible and populated
- Data matches Job Detail page

**Test 3: Other Users Not Affected** ✅
- Verified non-HQ users do not see additional data
- Sharing rules working as expected
- No unintended visibility changes

---

## Deployment History

**Deployment 1: Portal Layout** (October 15, 2025)
- Deploy ID: 0AfSj000000yqlJKAQ
- Components: Formula field + Layout
- Status: Success

**Deployment 2: Compliance Components** (October 15, 2025)
- Deploy ID: 0AfSj000000yqtNKAQ
- Components: Apex class + LWC
- Status: Success

**Total Time**: 45 minutes

---

## Migration Notes for NewOrg

**Components Required**:
1. Formula field: Waste_Carrier_License_Expiry__c on Job__c
2. Updated layout: Customer Community Job Layout
3. Modified Apex: Utility_Community.cls
4. Modified LWC: depotViewCommunity (JS + HTML)

**Dependencies**:
- Job__c object (must exist)
- Depot_Dispose__c lookup field (must exist)
- Depot__c object with Waste_Carrier_License_Expiry_Date__c field
- Customer Community portal setup
- Community_Role__c field on Contact

**Deployment Complexity**: Low-Medium
- Formula field: Simple
- Layout: Simple
- Apex: Minor query changes
- LWC: Minor display changes

**Estimated Migration Time**: 1-2 hours

---

## Related Documentation

- **Complete Implementation Guide**: [BAM_CONSTRUCT_PORTAL_LICENSE_VISIBILITY_FIX.md](../../Documentation/BAM_CONSTRUCT_PORTAL_LICENSE_VISIBILITY_FIX.md)

---

**Document Version**: 1.0
**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Status**: Complete
