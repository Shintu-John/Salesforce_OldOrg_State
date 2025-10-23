# Smart Waste Report Access Issue - Rebekah Stewart - Resolution

**Created**: 2025-10-16
**Last Updated**: 2025-10-16
**Org**: OldOrg (recyclinglives.my.salesforce.com)
**Requested by**: Shintu John
**Status**: ✅ Resolved
**User Affected**: Rebekah Stewart (rebekah.stewart@recyclinglives-services.com)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Issue Summary](#issue-summary)
3. [Root Cause Analysis](#root-cause-analysis)
4. [Investigation Process](#investigation-process)
5. [Solution Implemented](#solution-implemented)
6. [Verification](#verification)
7. [Key Learnings](#key-learnings)
8. [Related Information](#related-information)

---

## Executive Summary

**Problem**: User Rebekah Stewart could not access a Smart Waste Integration report despite having access to the report folder.

**Root Cause**: Missing object-level Read permission on `SmartWaste_Integration_Log__c` custom object for the "2.0 Internal Sales" profile.

**Solution**: Granted Read permission on `SmartWaste_Integration_Log__c` object to "2.0 Internal Sales" profile.

**Impact**: Issue resolved immediately - Rebekah can now access all Smart Waste integration reports.

---

## Issue Summary

**Reported**: 2025-10-16
**Reported By**: Shintu John
**User Affected**: Rebekah Stewart (Contact ID: 005Sj000001u9mQIAQ)
**Profile**: 2.0 Internal Sales (00eSj000000MacjIAC)

### Problem Description

Rebekah Stewart was unable to access the report **"Smart Waste Integration Errors - Enable"** despite:
- Having access to the folder where the report was located
- The report being moved to her dedicated folder "RLS) Rebekah Stewart Reports"
- Having "Run Reports" permission on her profile
- Other users with similar roles being able to access the report

### Error Message

```
You don't have sufficient privileges to perform this operation
```

---

## Root Cause Analysis

### The Real Issue

The problem was **NOT**:
- ❌ Report folder permissions (she had folder access)
- ❌ "Run Reports" profile permission (enabled on her profile)
- ❌ Custom Report Type access restrictions (no such setting exists)
- ❌ Report sharing settings

The problem **WAS**:
- ✅ **Missing object-level Read permission** on `SmartWaste_Integration_Log__c` custom object

### Why This Was Confusing

Initially, it appeared to be a report access issue because:
1. The error message was generic: "insufficient privileges"
2. She had access to the report folder
3. The report could be moved to different folders (suggesting folder permissions worked)
4. As admin, the report worked fine (admins bypass object permissions)

### The Key Discovery

Comparing access across similar users revealed the pattern:

| User | Profile | Has SmartWaste Access? | Report Works? |
|------|---------|------------------------|---------------|
| **Rebekah Stewart** | 2.0 Internal Sales | ❌ NO | ❌ NO |
| **Phillip Ryan** | 2.0 Commercial Sales | ✅ YES | ✅ YES |
| **Jan Ward** | 2.0 Key Account Manager | ✅ YES | ✅ YES |

This confirmed that the issue was profile-specific object permissions.

---

## Investigation Process

### Step 1: Initial Investigation

**Checked**:
- User profile: "2.0 Internal Sales"
- "Run Reports" permission: ✅ Enabled
- Report folder: "Misc" (00lSj000000iiJtIAI) - Hidden folder

**Initial Theory**: Folder access issue
**Result**: ❌ Incorrect - she could access other reports in the same folder

---

### Step 2: Report Comparison

**Discovered**:
- Report ID: 00OSj000005hLHdMAM (later recreated as 00OSj000005j2vdMAA)
- Report Name: "Smart Waste Integration Errors - Enable"
- Report Type: **Smart Waste Log with Related Job (Custom)**
- Base Object: `SmartWaste_Integration_Log__c`

**Compared with working report**:
- "Copy of SmartWaste Failures" (00OSj000005iHThMAM)
- Report Type: **Smart Waste Integration Logs (Custom)**
- Base Object: `SmartWaste_Integration_Log__c` (same!)

**Key Finding**: Both reports use the same base object, so both should require the same permissions.

**Follow-up Test**: Rebekah actually could NOT access either report (initial information was incorrect).

---

### Step 3: Object Permission Check

**Query Used**:
```sql
SELECT SObjectType, PermissionsRead
FROM ObjectPermissions
WHERE ParentId = '00eSj000000MacjIAC'
  AND SObjectType = 'SmartWaste_Integration_Log__c'
```

**Result**: 0 records returned

**Profile Metadata Check**:
```bash
grep -i "smartwaste" "force-app/main/default/profiles/2%2E0 Internal Sales.profile-meta.xml"
# Result: No matches found
```

**Conclusion**: Profile has NO permission on SmartWaste_Integration_Log__c object.

---

### Step 4: Comparison with Working Users

**Phillip Ryan Check**:
```sql
SELECT Parent.Name, SObjectType, PermissionsRead
FROM ObjectPermissions
WHERE ParentId IN (
    SELECT PermissionSetId
    FROM PermissionSetAssignment
    WHERE AssigneeId = '0054H000006fHBJQA2'
)
AND SObjectType = 'SmartWaste_Integration_Log__c'
```

**Result**: ✅ Profile "2.0 Commercial Sales" HAS Read permission

**Jan Ward Check**: ✅ Profile "2.0 Key Account Manager" HAS Read permission

**Rebekah Stewart Check**: ❌ Profile "2.0 Internal Sales" DOES NOT have Read permission

---

## Solution Implemented

### Action Taken

**Date**: 2025-10-16
**Implemented By**: Shintu John

**Steps**:
1. Navigated to **Setup** → **Profiles**
2. Opened **"2.0 Internal Sales"** profile (00eSj000000MacjIAC)
3. Clicked **"Object Settings"**
4. Searched for **"Smart Waste Integration Log"**
5. Clicked on the object → **"Edit"**
6. Enabled **"Read"** permission checkbox
7. Clicked **"Save"**

### Changes Made

**Profile**: 2.0 Internal Sales
**Object**: SmartWaste_Integration_Log__c
**Permission Added**: Read ✅

**Other Permissions NOT Changed**:
- Create: ❌ (not needed for reports)
- Edit: ❌ (not needed for reports)
- Delete: ❌ (not needed for reports)
- View All: ❌ (not needed for reports)
- Modify All: ❌ (not needed for reports)

---

## Verification

### Test 1: Report Access
- **User**: Rebekah Stewart
- **Report**: "Smart Waste Integration Errors - Enable"
- **Result**: ✅ Can access and view report
- **Status**: PASS

### Test 2: Alternative Report Access
- **User**: Rebekah Stewart
- **Report**: "Copy of SmartWaste Failures"
- **Result**: ✅ Can access and view report
- **Status**: PASS

### Impact Assessment

**Before Fix**:
- Rebekah Stewart: ❌ Cannot access Smart Waste reports
- Other "2.0 Internal Sales" users: ❌ Cannot access Smart Waste reports (if any exist)

**After Fix**:
- Rebekah Stewart: ✅ Can access Smart Waste reports
- Other "2.0 Internal Sales" users: ✅ Can access Smart Waste reports
- No disruptions to existing functionality
- No security concerns (Read-only access appropriate for reporting)

---

## Key Learnings

### 1. Report Access Requires Both Folder AND Object Permissions

**In Salesforce, users need TWO levels of access to view reports**:
1. **Folder access** - Permission to see the folder containing the report
2. **Object-level Read permission** - Permission to read data from the underlying object(s)

Even if a user can access the report folder, they cannot run the report if they lack object permissions.

---

### 2. Error Messages Can Be Misleading

**The error**: "You don't have sufficient privileges to perform this operation"

**What it sounds like**: A general permissions issue (could be folder, sharing, profile, etc.)

**What it actually was**: Missing object-level Read permission

**Lesson**: Always investigate object permissions when reports fail with generic error messages, especially for custom objects.

---

### 3. Compare Working vs Non-Working Users

**Most effective troubleshooting approach**:
1. Find a user who CAN access the report
2. Find a user who CANNOT access the report
3. Compare their profiles and permission sets
4. Look for differences in object permissions

This revealed the issue quickly: Phillip and Jan had SmartWaste access, Rebekah didn't.

---

### 4. Profile Metadata May Not Show Object Permissions

**Discovery**:
```bash
grep -c "objectPermissions" "2%2E0 Internal Sales.profile-meta.xml"
# Result: 0
```

Some orgs manage object permissions directly in the UI rather than in profile metadata XML. Always verify via SOQL queries:

```sql
SELECT SObjectType, PermissionsRead
FROM ObjectPermissions
WHERE ParentId = '<ProfileId>'
```

---

### 5. Custom Objects Require Explicit Permissions

Unlike standard objects (Account, Contact, etc.) which often have default permissions configured, **custom objects** like `SmartWaste_Integration_Log__c` require explicit permission grants.

**Common mistake**: Assuming that if a user can access one report, they can access all reports in the same folder.

**Reality**: Each report's access depends on the underlying object(s) it queries.

---

### 6. Report Types Are Not Access Control Mechanisms

**Initial theory**: The custom report type "Smart Waste Log with Related Job (Custom)" had access restrictions.

**Reality**:
- Report Types in Salesforce define **structure** (which objects/fields are available)
- Report Types do NOT control **access** (who can use them)
- Access is controlled at the **object level** and **folder level**

**Attempted fix that failed**:
```xml
<!-- This syntax is INVALID for ReportType metadata -->
<accessLevel>public</accessLevel>
```

**Error**: `Element accessLevel invalid at this location in type ReportType`

**Lesson**: Don't waste time trying to modify report type access settings - they don't exist in the metadata API.

---

### 7. Standard Salesforce Profiles May Have Inconsistent Permissions

**Observation**: Three similar "2.0" sales profiles had different SmartWaste permissions:
- 2.0 Commercial Sales: ✅ YES
- 2.0 Key Account Manager: ✅ YES
- 2.0 Internal Sales: ❌ NO

**Lesson**: Even within a naming convention (e.g., "2.0 X Sales"), profile permissions can vary significantly. Always verify permissions don't assume consistency based on profile names.

---

### 8. Admin Testing Can Be Deceptive

**Problem**: As System Administrator, all reports worked perfectly during testing.

**Why**: Administrators typically have "View All Data" permission, which bypasses object-level security.

**Lesson**: Always test with actual user accounts or use "Login As" feature to see what users actually experience.

---

## Related Information

### Custom Objects Involved

**Primary Object**:
- **API Name**: `SmartWaste_Integration_Log__c`
- **Label**: Smart Waste Integration Log
- **Purpose**: Tracks integration attempts and errors between Salesforce and Smart Waste external system
- **Related Objects**: Job__c, Account, Site__c

### Custom Report Types

**Report Type 1**:
- **Label**: Smart Waste Integration Logs (Custom)
- **Developer Name**: Smart_Waste_Integration_Logs_Custom
- **Base Object**: SmartWaste_Integration_Log__c
- **Location**: [force-app/main/default/reportTypes/Smart_Waste_Integration_Logs_Custom.reportType-meta.xml](../force-app/main/default/reportTypes/Smart_Waste_Integration_Logs_Custom.reportType-meta.xml)

**Report Type 2**:
- **Label**: Smart Waste Log with Related Job (Custom)
- **Developer Name**: Smart_Waste_Log_with_Related_Job_Custom
- **Base Object**: SmartWaste_Integration_Log__c
- **Location**: [force-app/main/default/reportTypes/Smart_Waste_Log_with_Related_Job_Custom.reportType-meta.xml](../force-app/main/default/reportTypes/Smart_Waste_Log_with_Related_Job_Custom.reportType-meta.xml)
- **Difference**: Includes additional section "Lookup" with more Job-related fields

### Reports Affected

| Report Name | Report ID | Report Type | Folder |
|-------------|-----------|-------------|--------|
| Smart Waste Integration Errors - Enable | 00OSj000005j2vdMAA | Smart Waste Log with Related Job (Custom) | Misc |
| Copy of SmartWaste Failures | 00OSj000005iHThMAM | Smart Waste Integration Logs (Custom) | Misc |

### Users Checked

| User | User ID | Email | Profile | Profile ID | SmartWaste Access |
|------|---------|-------|---------|------------|-------------------|
| Rebekah Stewart | 005Sj000001u9mQIAQ | rebekah.stewart@recyclinglives-services.com | 2.0 Internal Sales | 00eSj000000MacjIAC | ✅ NOW (after fix) |
| Phillip Ryan | 0054H000006fHBJQA2 | phillip.ryan@recyclinglives-services.com | 2.0 Commercial Sales | 00eSj000000Msg5IAC | ✅ YES (via profile) |
| Jan Ward | 0051o00000AIeioAAD | jan.ward@recyclinglives-services.com | 2.0 Key Account Manager | 00eSj000000MshhIAC | ✅ YES (via profile) |

### Folders Mentioned

| Folder Name | Folder ID | Developer Name | Access Type |
|-------------|-----------|----------------|-------------|
| Misc | 00lSj000000iiJtIAI | Misc123 | Hidden |
| Misc (Rebekah's) | 00lSj000000uIDZIA2 | MiscRebekahStewart | Hidden |
| RLS) Rebekah Stewart Reports | 00lSj000000oGj7IAE | RLSRebekahStewartReports | Hidden |

### Useful SOQL Queries

**Check Object Permissions for a Profile**:
```sql
SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
FROM ObjectPermissions
WHERE ParentId = '00eSj000000MacjIAC'
  AND SObjectType = 'SmartWaste_Integration_Log__c'
```

**Check User's Permission Sets**:
```sql
SELECT PermissionSet.Name, PermissionSet.IsOwnedByProfile
FROM PermissionSetAssignment
WHERE AssigneeId = '005Sj000001u9mQIAQ'
```

**Check SmartWaste Access Across All Permission Sets for a User**:
```sql
SELECT Parent.Name, SObjectType, PermissionsRead
FROM ObjectPermissions
WHERE ParentId IN (
    SELECT PermissionSetId
    FROM PermissionSetAssignment
    WHERE AssigneeId = '005Sj000001u9mQIAQ'
)
AND SObjectType = 'SmartWaste_Integration_Log__c'
```

**Find All Reports Using SmartWaste Objects**:
```sql
SELECT Id, Name, DeveloperName, FolderName, OwnerId, Owner.Name
FROM Report
WHERE Name LIKE '%Smart Waste%' OR Name LIKE '%SmartWaste%'
```

**Check Report Folder Details**:
```sql
SELECT Id, Name, DeveloperName, Type, AccessType
FROM Folder
WHERE Type = 'Report' AND DeveloperName = 'Misc123'
```

---

## Troubleshooting Guide for Similar Issues

If another user reports "insufficient privileges" when accessing a report, follow this checklist:

### ✅ Step 1: Verify Report Folder Access
- Check if the user can see the folder
- Check folder access type (Public/Hidden/Shared)
- If Hidden, verify user has explicit access

### ✅ Step 2: Verify "Run Reports" Permission
```sql
SELECT Name, PermissionsRunReports
FROM Profile
WHERE Name = '<ProfileName>'
```

### ✅ Step 3: Identify Report's Base Object(s)
- Open the report in Edit mode
- Note the Report Type
- Retrieve the Report Type metadata to see base object:
```bash
sf project retrieve start -m "ReportType" --target-org OldOrg
```

### ✅ Step 4: Check Object-Level Permissions
```sql
SELECT SObjectType, PermissionsRead
FROM ObjectPermissions
WHERE ParentId = '<ProfileId>'
  AND SObjectType = '<ObjectApiName>'
```

### ✅ Step 5: Check Permission Sets
```sql
SELECT Parent.Name, SObjectType, PermissionsRead
FROM ObjectPermissions
WHERE ParentId IN (
    SELECT PermissionSetId
    FROM PermissionSetAssignment
    WHERE AssigneeId = '<UserId>'
)
AND SObjectType = '<ObjectApiName>'
```

### ✅ Step 6: Compare with Working User
- Find a user who CAN access the report
- Run same queries for that user
- Compare object permissions

### ✅ Step 7: Grant Appropriate Access
- If missing object permission → Add to Profile or Permission Set
- If missing folder access → Share folder or move report
- If missing "Run Reports" → Enable on profile

---

## Recommendations

### For Salesforce Administrators

1. **Document Object Permissions by Profile**: Maintain a matrix showing which custom objects each profile can access

2. **Consistent Permissions**: Ensure similar profiles (e.g., all "2.0" sales profiles) have consistent access to integration/system objects

3. **Test with Actual Users**: Use "Login As" feature to verify report access from end-user perspective

4. **Report Folder Organization**:
   - Keep integration/system reports in shared folders
   - Use folder sharing rather than moving reports to user-specific folders

5. **Error Message Training**: Educate admins that "insufficient privileges" for reports often means missing object permissions, not folder access

### For Report Creators

1. **Check Dependencies**: Before creating reports on custom objects, verify target users have object access

2. **Document Required Permissions**: When sharing reports with new users, note which object permissions they need

3. **Use Standard Report Types When Possible**: Standard objects often have more consistent permission models

---

## References

- Salesforce Documentation: [Object-Level Security](https://help.salesforce.com/articleView?id=security_about_object_security.htm)
- Salesforce Documentation: [Report and Dashboard Folders](https://help.salesforce.com/articleView?id=analytics_folder_access.htm)
- Claude Workflow Rules: [CLAUDE_WORKFLOW_RULES.md](CLAUDE_WORKFLOW_RULES.md)

---

**Resolution Date**: 2025-10-16
**Implemented By**: Shintu John
**Status**: ✅ Resolved and Documented
