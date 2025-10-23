# Nathan Blake ADOC Permission Issue - Resolution

**Created**: 2025-10-17
**Last Updated**: 2025-10-17
**Org**: OldOrg (Current Production)
**Requested by**: Shintu John
**Status**: ✅ RESOLVED

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Issue Details](#issue-details)
3. [Root Cause Analysis](#root-cause-analysis)
4. [Investigation Process](#investigation-process)
5. [Solution Implemented](#solution-implemented)
6. [Verification Results](#verification-results)
7. [Package License Management](#package-license-management)
8. [Key Learnings](#key-learnings)
9. [Related Information](#related-information)

---

## Executive Summary

**Problem**: Nathan Blake from Customer Service team could not create ADOC (Annual Duty of Care) documents for bins.

**Root Cause**: Nathan was missing the Opero Documents package license required to use the ADOC creation functionality.

**Solution**: Transferred package license from Darren Garrido (last working day) to Nathan Blake.

**Impact**: Nathan can now successfully create ADOCs for bins like the rest of the Customer Service team.

**Timeline**: Issue identified and resolved on 2025-10-17

---

## Issue Details

### Reported Issue

**Date**: 2025-10-17
**Reported by**: Shintu John
**Affected User**: Nathan Blake (nathan.blake@recyclinglives-services.com)
**User ID**: 005Sj000003QosIIAS
**Profile**: 2.0 Customer Service

### Symptoms

1. Nathan could SEE the "Create ADOC" button on Job records
2. When clicking the button, received error:
   ```
   License Required
   The Visualforce Page GenerateDocument is part of the AppExchange Package
   Opero Documents, and requires a license to use.
   For more information, see Insufficient Privileges Errors.
   ```
3. Rest of Customer Service team could create ADOCs without issues

### What is ADOC?

**ADOC** = **Annual Duty of Care** document for waste bins
- Created from Job records that have a Schedule
- Uses Opero Documents (formerly RSign Documents) package
- Visualforce page: `/apex/rsdoc__GenerateDocument`
- Template ID: GDT-000052
- Flow name: Create_ADOC

---

## Root Cause Analysis

### Package License Investigation

**Opero Documents Package:**
- Package Namespace: `rsdoc`
- Package License ID: 0504H0000004nfqQAA
- Total Licenses Available: 17
- Licenses Used: 17/17 (at capacity)

### The Problem

Nathan Blake was **NOT assigned** the Opero Documents package license, while all other active Customer Service team members had it assigned.

**Customer Service Team License Status (Before Fix):**

| User | Email | Has License | Last Login |
|------|-------|-------------|------------|
| Ashleigh Taylor | ashleigh.taylor@recyclinglives-services.com | ✅ Yes | 2025-10-17 07:16:41 |
| Darren Garrido | darren.garrido@recyclinglives-services.com | ✅ Yes | 2025-10-17 06:56:58 |
| Dennis Dadey | dennis.dadey@recyclinglives-services.com | ✅ Yes | 2025-10-17 07:08:38 |
| Joanne Parry | joanne.parry@recyclinglives-services.com | ✅ Yes | 2025-10-17 06:17:44 |
| Kaylie Morris | kaylie.morris@recyclinglives-services.com | ✅ Yes | 2025-10-17 06:56:10 |
| Laura Baron | laura.baron@recyclinglives-services.com | ✅ Yes | 2025-10-17 07:00:59 |
| Supriya Chaterjee | supriya.chaterjee@recyclinglives-services.com | ✅ Yes | 2025-10-17 09:19:53 |
| **Nathan Blake** | nathan.blake@recyclinglives-services.com | ❌ **NO** | N/A |

### Why Nathan Didn't Have It

Nathan was assigned only 2 permission sets:
1. X00eSj000000NBZ3IAO (Profile-based permission set)
2. NBVC BasicUser PermissionSet

**Missing**: Opero Documents package license (not a permission set, but a package license assignment)

---

## Investigation Process

### Step 1: Initial Investigation

**Query used to find Nathan Blake:**
```sql
SELECT Id, Name, Email, ProfileId, Profile.Name, IsActive
FROM User
WHERE Name LIKE '%Nathan Blake%'
```

**Result:**
- User ID: 005Sj000003QosIIAS
- Profile: 2.0 Customer Service
- Active: true

### Step 2: Permission Set Comparison

**Nathan's Permission Sets (2 total):**
```sql
SELECT PermissionSet.Name, PermissionSet.Label
FROM PermissionSetAssignment
WHERE AssigneeId = '005Sj000003QosIIAS'
```

**Other CS Users (e.g., Ashleigh Taylor - 9 permission sets):**
- Included additional sets like Five9_Open_CTI_user, Access_Converted_Leads, etc.

### Step 3: Package License Discovery

**Found Opero Documents permission sets:**
```sql
SELECT Id, Name, Label, Description
FROM PermissionSet
WHERE (Name LIKE '%Opero%' OR Label LIKE '%Opero%')
```

**Results:**
1. Opero Documents Administrator Permissions (0PSSj0000000crhOAA)
2. Opero Documents User Permissions (0PSSj0000000criOAA)
3. Opero Signature Standard User Permissions (0PS8e000000g0jCGAQ)

### Step 4: Package License Check

**Verified package license assignments:**
```sql
SELECT User.Name, User.Email, User.Profile.Name
FROM UserPackageLicense
WHERE PackageLicenseId = '0504H0000004nfqQAA'
  AND User.Profile.Name = '2.0 Customer Service'
```

**Discovery**: Nathan Blake was NOT in this list - he didn't have the package license!

### Step 5: License Capacity Check

```sql
SELECT AllowedLicenses, UsedLicenses, Status
FROM PackageLicense
WHERE Id = '0504H0000004nfqQAA'
```

**Result:**
- AllowedLicenses: 17
- UsedLicenses: 17
- Status: Active
- **Conclusion**: At full capacity, need to free up a license

---

## Solution Implemented

### Original Plan

Remove license from **"Odaseva Service User"** (integration account, never logged in)

### Actual Solution

**User decision**: Remove license from **Darren Garrido** (last working day: 2025-10-17)

### Implementation Steps

**Via Salesforce UI:**

1. **Setup → Installed Packages**
2. Found **Opero Documents** (or RSign Documents)
3. Clicked **Manage Licenses**
4. **Removed** license from: Darren Garrido
5. Clicked **Add Users**
6. Searched for: Nathan Blake
7. Selected Nathan Blake and clicked **Add**

### Result

**New License Assignment:**
- License ID: 051Sj00000NC8uEIAT
- User: Nathan Blake (005Sj000003QosIIAS)
- Assigned: 2025-10-17

**Removed License:**
- User: Darren Garrido (005Sj000002jN7OIAU)
- Reason: Last working day (2025-10-17)

---

## Verification Results

### Verification Query - Nathan Has License

```sql
SELECT User.Name, User.Email
FROM UserPackageLicense
WHERE PackageLicenseId = '0504H0000004nfqQAA'
  AND UserId = '005Sj000003QosIIAS'
```

**Result**: ✅ 1 record found
- User: Nathan Blake
- Email: nathan.blake@recyclinglives-services.com

### Verification Query - Darren License Removed

```sql
SELECT User.Name, User.Email
FROM UserPackageLicense
WHERE PackageLicenseId = '0504H0000004nfqQAA'
  AND UserId = '005Sj000002jN7OIAU'
```

**Result**: ✅ 0 records found (license successfully removed)

### Expected Behavior

Nathan Blake can now:
1. ✅ See the "Create ADOC" button on Job records
2. ✅ Click the button without error
3. ✅ Successfully generate Annual Duty of Care documents
4. ✅ No "License Required" error message

---

## Package License Management

### Current License Status (After Fix)

**Package**: Opero Documents (rsdoc)
- **Total Licenses**: 17
- **Used Licenses**: 17/17 (still at capacity)
- **Available**: 0

### All Current License Holders (17 users)

| # | User | Profile | Last Login | Notes |
|---|------|---------|------------|-------|
| 1 | Ashleigh Taylor | 2.0 Customer Service | 2025-10-17 07:16:41 | Active |
| 2 | Dennis Dadey | 2.0 Customer Service | 2025-10-17 07:08:38 | Active |
| 3 | Joanne Parry | 2.0 Customer Service | 2025-10-17 06:17:44 | Active |
| 4 | Kaylie Morris | 2.0 Customer Service | 2025-10-17 06:56:10 | Active |
| 5 | Laura Baron | 2.0 Customer Service | 2025-10-17 07:00:59 | Active |
| 6 | **Nathan Blake** | **2.0 Customer Service** | **N/A** | **✅ NEWLY ADDED** |
| 7 | Supriya Chaterjee | 2.0 Customer Service | 2025-10-17 09:19:53 | Active |
| 8 | Chantal Cooke | 1.0 Finance Manager | 2025-10-09 07:19:47 | Active |
| 9 | Louise Painter | 1.0 Finance | 2025-10-16 07:31:39 | Active |
| 10 | Natalie Cooke | 1.0 Finance Manager | 2025-10-17 06:47:40 | Active |
| 11 | Fatima Ouarbiaa | 1.0 Finance | 2025-10-17 07:06:44 | Active |
| 12 | Olivia Singleton | 1.0 Finance | 2025-10-17 07:11:33 | Active |
| 13 | George Williams | 1.0 Finance | 2025-10-17 07:12:00 | Active |
| 14 | Glen Bagshaw | System Administrator | 2025-10-17 07:41:00 | Active |
| 15 | Alisha Miller | 2.0 Contracts Manager | 2025-10-17 07:56:49 | Active |
| 16 | Stacey Doyle | 1.0 Finance Manager | 2025-10-17 08:11:02 | Active |
| 17 | Odaseva Service User | Data Analytics API Integration | Never | Integration account |

### Potential Future License Optimization

**User who has license but never logged in:**
- **Odaseva Service User** (Integration account, LastLoginDate: null)
- Could potentially free this up if another user needs it

---

## Key Learnings

### 1. Package Licenses vs Permission Sets

**Important Distinction:**
- **Permission Sets**: Grant specific permissions/access within Salesforce
- **Package Licenses**: Required to use AppExchange package functionality
- Both may be needed for full access to third-party app features

### 2. Diagnosing Package License Issues

**When user gets "License Required" error:**

✅ **Check these in order:**
1. Does the button/page use a managed package? (namespace prefix like `rsdoc__`)
2. Find the package in Setup → Installed Packages
3. Check Manage Licenses to see who has access
4. Verify the user is in the license assignment list
5. Check if licenses are available (Used vs Allowed)

### 3. How to Assign Package Licenses

**Two methods:**

**Method 1: From Installed Packages (Recommended)**
```
Setup → Installed Packages → [Package Name] → Manage Licenses → Add Users
```

**Method 2: From User Record**
```
Setup → Users → [User Name] → Package License Assignments → Assign Package Licenses
```

### 4. License Capacity Management

**When at capacity (17/17):**
- Cannot assign new licenses without removing existing ones
- Review users who:
  - Never logged in (service accounts)
  - Haven't logged in recently (inactive users)
  - Left the organization (like Darren Garrido)

---

## Related Information

### ADOC Creation Process

**Flow**: Create_ADOC
- Location: `/force-app/main/default/flows/Create_ADOC.flow-meta.xml`
- Requires: Job record with Schedule attached
- Collects: ADOC Activation Date and Expiration Date
- Generates: PDF document using Opero Documents

### Web Link Button

**Create ADOC Button**:
- Location: Job object
- Type: Web Link Button
- URL: `/apex/rsdoc__GenerateDocument`
- Template ID: GDT-000052
- Package: Opero Documents (rsdoc)

### Related Fields

**Job Object:**
- ADOC_Required__c
- ADOC_Created__c
- May_Require_ADOC__c

**Schedule Object:**
- ADOC_Activation_Date__c
- ADOC_Expiration_Date__c
- ADOC_Email__c
- ADOC_Expiration_Date__c
- ADOC_Request_Email__c
- ADOC_Send_To__c
- ADOC_Status__c
- No_ADOC_Required__c

### Useful Queries

**Check who has Opero Documents license:**
```sql
SELECT User.Name, User.Email, User.Profile.Name, User.LastLoginDate
FROM UserPackageLicense
WHERE PackageLicenseId = '0504H0000004nfqQAA'
ORDER BY User.LastLoginDate DESC NULLS FIRST
```

**Check package license capacity:**
```sql
SELECT Id, NamespacePrefix, AllowedLicenses, UsedLicenses, Status
FROM PackageLicense
WHERE NamespacePrefix = 'rsdoc'
```

**Find all Customer Service users:**
```sql
SELECT Id, Name, Email, Profile.Name, IsActive
FROM User
WHERE Profile.Name = '2.0 Customer Service'
  AND IsActive = true
ORDER BY Name
```

---

## Appendix: Complete Investigation Commands

### All Commands Used

```bash
# 1. Find Nathan Blake
sf data query --query "SELECT Id, Name, Email, ProfileId, Profile.Name, IsActive FROM User WHERE Name LIKE '%Nathan Blake%'" --target-org OldOrg

# 2. Get Nathan's permission sets
sf data query --query "SELECT PermissionSet.Name, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = '005Sj000003QosIIAS'" --target-org OldOrg

# 3. Get all Customer Service users
sf data query --query "SELECT Id, Name, Email, Profile.Name FROM User WHERE Profile.Name = '2.0 Customer Service' AND IsActive = true" --target-org OldOrg

# 4. Find Opero permission sets
sf data query --query "SELECT Id, Name, Label, Description FROM PermissionSet WHERE (Name LIKE '%Opero%' OR Label LIKE '%Opero%')" --target-org OldOrg

# 5. Find package license
sf data query --query "SELECT Id, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix = 'rsdoc'" --target-org OldOrg

# 6. Check CS users with package license
sf data query --query "SELECT User.Name, User.Email FROM UserPackageLicense WHERE PackageLicenseId = '0504H0000004nfqQAA' AND User.Profile.Name = '2.0 Customer Service'" --target-org OldOrg

# 7. Check license capacity
sf data query --query "SELECT AllowedLicenses, UsedLicenses, Status FROM PackageLicense WHERE Id = '0504H0000004nfqQAA'" --target-org OldOrg

# 8. Check all license holders with activity
sf data query --query "SELECT User.Name, User.Email, User.Profile.Name, User.IsActive, User.LastLoginDate FROM UserPackageLicense WHERE PackageLicenseId = '0504H0000004nfqQAA' ORDER BY User.LastLoginDate NULLS FIRST" --target-org OldOrg

# 9. Verify Nathan has license (after fix)
sf data query --query "SELECT User.Name, User.Email FROM UserPackageLicense WHERE PackageLicenseId = '0504H0000004nfqQAA' AND UserId = '005Sj000003QosIIAS'" --target-org OldOrg

# 10. Verify Darren license removed (after fix)
sf data query --query "SELECT User.Name, User.Email FROM UserPackageLicense WHERE PackageLicenseId = '0504H0000004nfqQAA' AND UserId = '005Sj000002jN7OIAU'" --target-org OldOrg
```

---

## Resolution Summary

**Issue**: Nathan Blake couldn't create ADOCs - "License Required" error
**Root Cause**: Missing Opero Documents package license
**Solution**: Transferred license from Darren Garrido to Nathan Blake
**Status**: ✅ **RESOLVED**
**Date**: 2025-10-17
**Verified**: Nathan now has package license (051Sj00000NC8uEIAT)

---

*Resolution completed by: Claude (Shintu John)*
*Org: OldOrg (recyclinglives.my.salesforce.com)*
*Documentation saved: 2025-10-17*
