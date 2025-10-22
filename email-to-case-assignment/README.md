# Email-to-Case Assignment System - OldOrg Current State

**Organization:** OldOrg (Recycling Lives Service - recyclinglives.my.salesforce.com)
**Last Verified:** October 22, 2025
**Status:** ✅ Active and Deployed in Production
**Implementation Version:** V3 (SOQL Optimization & Kaylie Morris Exemption)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Overview](#system-overview)
3. [Components Inventory](#components-inventory)
4. [Current State Verification](#current-state-verification)
5. [Business Logic](#business-logic)
6. [Configuration](#configuration)
7. [Integration Points](#integration-points)
8. [Related Scenarios](#related-scenarios)
9. [Files and Metadata](#files-and-metadata)

---

## Executive Summary

### What This System Does

The Email-to-Case Assignment System automatically assigns incoming email cases to Customer Service representatives based on workload distribution and business rules. It implements intelligent threshold-based assignment, key account management, and same-day case reassignment.

### Key Features (V3 - Current)

1. **Threshold-Based Assignment**: Limits automatic assignment to users with < 20 open cases
2. **Same-Day Previous Owner Reassignment**: Returns reopened cases to original agent if within same calendar day
3. **Overflow Handling**: Assigns to lowest workload user even when all exceed threshold (soft limit)
4. **Key Account Threshold Respect**: Key account CS Contacts respect threshold, fallback to team when over capacity
5. **SOQL Query Optimization**: Recursion prevention and query caching to prevent "Too many SOQL queries: 101" errors
6. **Kaylie Morris Exemption**: Kaylie Morris bypasses threshold check for her key accounts

### Current Metrics

- **Open Email Cases**: 142 (as of Oct 8, 2025)
- **Customer Service Users**: 8 active users
- **Average Load**: ~17.75 cases per user
- **Configured Threshold**: 20 open cases maximum per user

### Implementation Timeline

- **V1 Deployed**: October 8, 2025 - 15:04 UTC (Deploy ID: 0AfSj000000yHsPKAU)
- **V2 Deployed**: October 8, 2025 - 15:45 UTC (Deploy ID: 0AfSj000000yI5JKAU)
- **V3 Deployed**: October 20, 2025 - 19:51 UTC (Deploy ID: 0AfSj000000z1OzKAI)

---

## System Overview

### High-Level Flow

```
[Email arrives]
    ↓
Email-to-Case (Salesforce Standard)
    ↓
Case created/updated with OwnerId = "Customer Service Email" Queue
    ↓
[Trigger: rlsServiceCaseAutoAssignTrigger fires]
    ↓
[Class: rlsServiceCaseAutoAssign.assignCasesToUsers()]
    ↓
Phase 1: Assign key accounts to account managers
    ↓
Phase 2: Check same-day previous owner eligibility
    ↓
Phase 3: Workload-based assignment with threshold filter
    ↓
Case assigned to appropriate user
```

### Related Flows

1. **Case_Remove_Case_Owner_if_Reopen_24_Hours** (Active - Version 2)
   - Removes case owner if reopened after 14+ hours
   - Captures Previous_Auto_Assigned_Owner__c before reassigning to queue
   - Triggers the auto-assignment system

2. **EmailMessage_Open_Closed_Case_on_Email** (Active - Version 4)
   - Automatically reopens closed cases when customer replies
   - Checks for Email, Paperwork_Compliance, RLES_Invoicing, RLES_Purchase_Ledger record types
   - Sets Status = "Reopen"

---

## Components Inventory

### 1. Apex Components

#### rlsServiceCaseAutoAssign.cls
- **Type**: Apex Class
- **Status**: ✅ Active
- **Last Modified**: October 20, 2025 18:51:47 UTC by John Shintu
- **Size**: ~27 KB (with comments)
- **Created By**: Glen Bagshaw (May 20, 2025)
- **Class ID**: 01pSj000000k789IAA

**Key Methods**:
- `assignCasesToUsers()` - Main entry point with recursion guard
- `queryEligibleCases()` - Fetches unassigned cases from queue
- `assignKeyAccountCases()` - Handles key account assignments with Kaylie exemption
- `assignCasesToUsersWithLowestWorkload()` - Workload distribution with threshold logic
- `checkPreviousOwnerEligibility()` - Same-day previous owner check
- `getMaxOpenCasesThreshold()` - Retrieves threshold from custom setting
- `getEmailRecordTypeId()` - Cached RecordType ID getter (V3)
- `getCSEmailQueueId()` - Cached Queue ID getter (V3)
- `getUserOpenCaseCounts()` - Aggregates open case counts per user

#### rlsServiceCaseAutoAssignTest.cls
- **Type**: Apex Test Class
- **Status**: ✅ Active
- **Last Modified**: October 20, 2025 18:51:48 UTC by John Shintu
- **Size**: ~36 KB
- **Test Coverage**: >75% (14 test methods)
- **Test Execution Time**: 39-45 seconds
- **Class ID**: 01pSj000000k78AIAQ

**Test Methods** (V3):
1. `testAssignOneCase()` - Basic assignment
2. `testAssignMultipleCases()` - Multiple cases distribution
3. `testKeyAccountAssignment()` - Key account CS Contact logic
4. `testNoEligibleUsers()` - All users unavailable scenario
5. `testAssignAfterReassign()` - Case reassignment logic
6. `testThresholdFiltering()` - Threshold validation
7. `testSoftLimit()` - Overflow handling when all over threshold
8. `testSameDayPreviousOwner()` - Same-day reopened case reassignment
9. `testPreviousOwnerOverThreshold()` - Fallback when previous owner over threshold
10. `testDifferentDayPreviousOwner()` - Previous owner logic doesn't apply next day
11. `testKeyAccountWithNewFields()` - Key account assignment with V1 fields
12. `testKeyAccountCSContactOverThreshold()` - Key account threshold respect (V2)
13. `testKaylieMorrisExemption()` - Kaylie Morris exemption logic (V3)
14. `testRecursionPrevention()` - Recursion guard validation (V3)

**All tests passing**: ✅ 14/14 (100% success rate)

#### rlsServiceCaseAutoAssignTrigger.trigger
- **Type**: Apex Trigger
- **Object**: Case
- **Status**: ✅ Active
- **Events**: after insert, after update
- **Last Modified**: October 2, 2025 13:27:07 UTC by Mark Strutz
- **API Version**: 63.0
- **Trigger ID**: 01qSj000002IbG5IAK

**Logic**: Calls `rlsServiceCaseAutoAssign.assignCasesToUsers(Trigger.new)`

---

### 2. Flows

#### Case_Remove_Case_Owner_if_Reopen_24_Hours
- **Developer Name**: Case_Remove_Case_Owner_if_Reopen_24_Hours
- **Type**: Record-Triggered Flow (AutoLaunchedFlow)
- **Object**: Case
- **Trigger**: Before Save
- **Active Version**: 2
- **Latest Version**: 3 (Draft - not deployed)
- **Definition ID**: 300Sj00000Mt4SvIAJ
- **Version 2 ID**: 301Sj00000O2bYkIAJ

**Entry Conditions**:
- Case Status changed to "Reopen" OR "Reopened"
- Last Modified Date >= 14 hours ago

**Actions**:
1. Capture current OwnerId → Previous_Auto_Assigned_Owner__c
2. Set OwnerId = Customer Service Email Queue
3. Clear OwnerName__c (formula field cache)

**Version History**:
- Version 1: Original (Obsolete)
- Version 2: Added Previous_Auto_Assigned_Owner__c capture ✅ **ACTIVE**
- Version 3: Draft modifications (not deployed)

#### EmailMessage_Open_Closed_Case_on_Email
- **Developer Name**: EmailMessage_Open_Closed_Case_on_Email
- **Type**: Record-Triggered Flow (AutoLaunchedFlow)
- **Object**: EmailMessage
- **Trigger**: After Save
- **Active Version**: 4
- **Definition ID**: 300Sj000005Srt3IAC
- **Version 4 ID**: 301Sj000008rq8kIAA

**Entry Conditions**:
- Incoming = true
- ParentId starts with "500" (Case)
- Parent.Status = "Closed" OR "Case Closed"
- Parent.RecordType.DeveloperName IN ('Email', 'Paperwork_Compliance', 'RLES_Invoicing', 'RLES_Purchase_Ledger')

**Actions**:
- Update Case Status = "Reopen"

**Version History**:
- Versions 1-3: Obsolete/Draft
- Version 4: Current ✅ **ACTIVE**

---

### 3. Custom Objects & Fields

#### Case_Auto_Assignment_Settings__c
- **Type**: Custom Setting (Hierarchy)
- **API Name**: Case_Auto_Assignment_Settings__c
- **Created**: October 8, 2025 by John Shintu
- **Object ID**: 01ISj000002QW7xMAG
- **Visibility**: Public

**Fields**:
- `Max_Open_Cases_Per_User__c` (Number, 0 decimals)
  - Default Value: 20
  - Description: Maximum open cases before threshold applies
  - Created: October 8, 2025

**Organization Default Setting**:
```apex
Name: "OrgDefaults"
Max_Open_Cases_Per_User__c: 20
```

**Hierarchy Support**: Can be overridden at Profile or User level (currently using org default only)

#### Case.Previous_Auto_Assigned_Owner__c
- **Type**: Custom Field (Lookup to User)
- **Object**: Case
- **API Name**: Previous_Auto_Assigned_Owner__c
- **Created**: October 8, 2025 by John Shintu
- **Field Purpose**: Stores the last auto-assigned owner for same-day reassignment logic

**Usage**:
- Populated by "Case_Remove_Case_Owner_if_Reopen_24_Hours" flow
- Read by `checkPreviousOwnerEligibility()` method
- Enables intelligent same-day case reassignment

---

## Current State Verification

### Verification Date: October 22, 2025

#### Apex Classes
```bash
Query: SELECT Name, LengthWithoutComments, LastModifiedDate, LastModifiedBy.Name
       FROM ApexClass
       WHERE Name IN ('rlsServiceCaseAutoAssign', 'rlsServiceCaseAutoAssignTest')
```

**Results**:
| Class | Last Modified | Modified By | Size (chars) |
|-------|---------------|-------------|--------------|
| rlsServiceCaseAutoAssign | 2025-10-20 18:51:47 | John Shintu | ~27,000 |
| rlsServiceCaseAutoAssignTest | 2025-10-20 18:51:48 | John Shintu | ~36,000 |

✅ **Verified**: V3 code is deployed

#### Trigger Status
```bash
Query: SELECT Name, TableEnumOrId, Status, ApiVersion
       FROM ApexTrigger
       WHERE Name = 'rlsServiceCaseAutoAssignTrigger'
```

**Result**:
| Trigger | Object | Status | API Version |
|---------|--------|--------|-------------|
| rlsServiceCaseAutoAssignTrigger | Case | **Active** | 63.0 |

✅ **Verified**: Trigger is active

#### Flow Versions
```bash
Query: SELECT DefinitionId, VersionNumber, Status, ProcessType
       FROM Flow
       WHERE Definition.DeveloperName IN ('Case_Remove_Case_Owner_if_Reopen_24_Hours',
                                          'EmailMessage_Open_Closed_Case_on_Email')
```

**Results**:

**Case_Remove_Case_Owner_if_Reopen_24_Hours**:
| Version | Status | Notes |
|---------|--------|-------|
| 1 | Obsolete | Original version |
| 2 | **Active** | ✅ With Previous Owner capture |
| 3 | Draft | Not deployed |

**EmailMessage_Open_Closed_Case_on_Email**:
| Version | Status | Notes |
|---------|--------|-------|
| 1 | Obsolete | - |
| 2 | Obsolete | - |
| 3 | Draft | - |
| 4 | **Active** | ✅ Current production version |

✅ **Verified**: Correct flow versions are active

#### Custom Settings
```bash
Query: SELECT Name, Max_Open_Cases_Per_User__c
       FROM Case_Auto_Assignment_Settings__c
```

**Result**:
| Name | Max_Open_Cases_Per_User__c |
|------|----------------------------|
| OrgDefaults | 20 |

✅ **Verified**: Custom setting configured correctly

---

## Business Logic

### Assignment Priority Order

1. **Check Key Account** (Priority 1)
   - If Account has CS_Contact__c populated
   - **AND** CS_Contact__c has < 20 open cases (OR is Kaylie Morris)
   - **THEN** Assign to CS_Contact__c
   - **ELSE** Fall through to workload distribution

2. **Check Same-Day Previous Owner** (Priority 2)
   - If Case has Previous_Auto_Assigned_Owner__c
   - **AND** Previous owner reopened case today (same calendar day)
   - **AND** Previous owner has < 20 open cases
   - **THEN** Assign back to previous owner
   - **ELSE** Fall through to workload distribution

3. **Workload Distribution with Threshold** (Priority 3)
   - Filter users with < 20 open cases (under threshold)
   - **IF** any users under threshold:
     - Assign to user with lowest workload among filtered users
   - **ELSE** (all users over threshold - soft limit):
     - Assign to user with lowest workload overall
     - No user is blocked from receiving cases

### Threshold Logic Details

**Custom Setting**: `Case_Auto_Assignment_Settings__c.Max_Open_Cases_Per_User__c`
- **Default Value**: 20
- **Type**: Hierarchy (can override at Profile/User level)
- **Behavior**: Soft limit (doesn't completely block assignment)

**Implementation**:
```apex
public Integer getMaxOpenCasesThreshold() {
    Case_Auto_Assignment_Settings__c settings = Case_Auto_Assignment_Settings__c.getInstance();
    return settings != null && settings.Max_Open_Cases_Per_User__c != null
        ? Integer.valueOf(settings.Max_Open_Cases_Per_User__c)
        : 20; // Default fallback
}
```

### Kaylie Morris Special Handling (V3)

**User**: Kaylie Morris (kaylie.morris@recyclinglives.co.uk)
**Rule**: Bypasses threshold check for her key account assignments

**Logic**:
```apex
// In assignKeyAccountCases() method
if (cs_contact_name == 'Kaylie Morris') {
    // Kaylie bypasses threshold - always gets her key accounts
    case_obj.OwnerId = cs_contact_user.Id;
} else if (cs_contact_user_case_count < threshold) {
    // Other CS Contacts respect threshold
    case_obj.OwnerId = cs_contact_user.Id;
} else {
    // Over threshold - fallback to workload distribution
    remaining_cases.add(case_obj);
}
```

### SOQL Optimization (V3)

**Problem**: Multiple email triggers caused "Too many SOQL queries: 101" errors

**Solution**:
1. **Recursion Guard**: Static boolean prevents recursive trigger execution
2. **Query Caching**: RecordType and Queue IDs cached in static variables
3. **Reduced Queries**: Eliminated redundant SOQL queries by 67%

**Implementation**:
```apex
private static Boolean isRunning = false; // Recursion guard
private static Id cachedEmailRecordTypeId; // Cache RecordType
private static Id cachedCSEmailQueueId; // Cache Queue ID

public static void assignCasesToUsers(List<Case> newCases) {
    if (isRunning) return; // Prevent recursion
    isRunning = true;
    try {
        // Assignment logic
    } finally {
        isRunning = false; // Reset guard
    }
}
```

---

## Configuration

### Adjustable Settings

#### 1. Threshold Configuration

**Location**: Setup → Custom Settings → Case_Auto_Assignment_Settings → Manage

**Hierarchy Levels**:
- Organization Default (currently used): 20 cases
- Profile Level: Can override for specific profiles
- User Level: Can override for individual users

**To Adjust**:
1. Navigate to Setup → Custom Settings
2. Click "Case Auto Assignment Settings"
3. Click "Manage" next to hierarchy level
4. Edit "Max_Open_Cases_Per_User__c" field
5. Save (takes effect immediately)

#### 2. Case Reopening Time Window

**Location**: Flow → Case_Remove_Case_Owner_if_Reopen_24_Hours

**Current Value**: 14 hours (configured in flow decision criteria)

**To Adjust**:
1. Navigate to Setup → Flows
2. Edit "Case_Remove_Case_Owner_if_Reopen_24_Hours"
3. Modify decision criteria: `LastModifiedDate >= 14 HOURS AGO`
4. Save and activate new version

#### 3. Key Account CS Contact Assignment

**Exempted Users**:
- Kaylie Morris (hardcoded exemption in V3)

**To Add More Exemptions**:
- Modify `assignKeyAccountCases()` method
- Add user email to exemption list
- Redeploy Apex class

---

## Integration Points

### 1. Email-to-Case Integration
- **Standard Salesforce Feature**: Email-to-Case
- **Integration Type**: Native
- **Email Addresses**: Customer Service email addresses configured in Email-to-Case settings
- **Action**: Creates/updates cases with OwnerId = "Customer Service Email" queue

### 2. Queue Integration
- **Queue Name**: "Customer Service Email"
- **Purpose**: Temporary case storage before auto-assignment
- **Members**: Customer Service users
- **Usage**: Trigger monitors cases entering this queue

### 3. RecordType Dependencies
- **Email RecordType**: Used for filtering eligible cases
- **Other RecordTypes**: Paperwork_Compliance, RLES_Invoicing, RLES_Purchase_Ledger
- **Purpose**: EmailMessage_Open_Closed_Case_on_Email flow uses these for reopening logic

### 4. User Profile Requirements
- **Required Profile Settings**:
  - Access to "Customer Service Email" queue
  - Case record type access (Email, etc.)
  - Create/Edit permissions on Case object

---

## Related Scenarios

### 1. Case Reopening Incident (October 16, 2025)
- **Issue**: Cases without RecordTypes weren't automatically reopened
- **Root Cause**: Profile "2.0 Customer Service" had no record type access
- **Fix**: Assigned "Email" record type to all 584 cases without record types
- **Documentation**: `/Documentation/CASE_REOPENING_INCIDENT_2025-10-16.md`
- **Impact on This System**: EmailMessage_Open_Closed_Case_on_Email flow now works correctly

### 2. Domestic Customer Email Issue
- **Documentation**: `/Documentation/DOMESTIC_CUSTOMER_EMAIL_ISSUE_FIX.md`
- **Relationship**: Related to email handling and case creation

### 3. Daily Reminder Emails
- **Documentation**: `/Documentation/DAILY_REMINDER_EMAILS_COMPLETE_GUIDE.md`
- **Relationship**: Another case management automation feature

---

## Files and Metadata

### Source Files in OldOrg

All files retrieved from OldOrg and available in this repository under `/code/` directory:

```
email-to-case-assignment/
├── code/
│   ├── classes/
│   │   ├── rlsServiceCaseAutoAssign.cls
│   │   ├── rlsServiceCaseAutoAssign.cls-meta.xml
│   │   ├── rlsServiceCaseAutoAssignTest.cls
│   │   └── rlsServiceCaseAutoAssignTest.cls-meta.xml
│   ├── triggers/
│   │   ├── rlsServiceCaseAutoAssignTrigger.trigger
│   │   └── rlsServiceCaseAutoAssignTrigger.trigger-meta.xml
│   ├── flows/
│   │   ├── Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml
│   │   └── EmailMessage_Open_Closed_Case_on_Email.flow-meta.xml
│   ├── objects/
│   │   ├── Case_Auto_Assignment_Settings__c/
│   │   │   ├── Case_Auto_Assignment_Settings__c.object-meta.xml
│   │   │   └── fields/
│   │   │       └── Max_Open_Cases_Per_User__c.field-meta.xml
│   │   └── Case/
│   │       └── fields/
│   │           └── Previous_Auto_Assigned_Owner__c.field-meta.xml
│   └── README-CODE.md
└── README.md (this file)
```

### Backup Files

Original implementation backups available in Salesforce project:

- `/Backup/2025-10-08_email_to_case_assignment/` - V1 & V2 implementation
- `/Backup/2025-10-20_email_to_case_soql_fix/` - V3 implementation (SOQL optimization)

### Documentation Files

- `/Documentation/EMAIL_TO_CASE_ASSIGNMENT_MASTER.md` - Complete implementation guide (112KB)
- `/Documentation/CASE_REOPENING_INCIDENT_2025-10-16.md` - Case reopening incident analysis

---

## Version History

### V3 - SOQL Optimization & Kaylie Morris Exemption (October 20, 2025)

**Deploy ID**: 0AfSj000000z1OzKAI
**Status**: ✅ Deployed and Active

**Changes**:
- Added recursion prevention guard
- Cached RecordType and Queue IDs
- Kaylie Morris threshold bypass
- 2 new test methods

**Files Modified**:
- rlsServiceCaseAutoAssign.cls
- rlsServiceCaseAutoAssignTest.cls

### V2 - Key Account Threshold (October 8, 2025)

**Deploy ID**: 0AfSj000000yI5JKAU
**Status**: ✅ Deployed and Active

**Changes**:
- Key account CS Contacts now respect threshold
- Fallback to workload distribution when over capacity
- 1 new test method

**Files Modified**:
- rlsServiceCaseAutoAssign.cls
- rlsServiceCaseAutoAssignTest.cls

### V1 - Initial Implementation (October 8, 2025)

**Deploy ID**: 0AfSj000000yHsPKAU
**Status**: ✅ Deployed and Active

**Changes**:
- Threshold-based assignment (20 cases)
- Same-day previous owner reassignment
- Soft limit overflow handling
- Custom setting creation
- Case field creation
- Flow modification
- 6 new test methods

**New Components**:
- Case_Auto_Assignment_Settings__c (Custom Setting)
- Max_Open_Cases_Per_User__c (Custom Setting Field)
- Previous_Auto_Assigned_Owner__c (Case Field)
- getMaxOpenCasesThreshold() method
- checkPreviousOwnerEligibility() method

**Files Modified**:
- rlsServiceCaseAutoAssign.cls
- rlsServiceCaseAutoAssignTest.cls
- Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml

---

## Support Information

### Key Contacts

- **Original Developer**: Glen Bagshaw (May 20, 2025)
- **V1-V3 Developer**: John Shintu (October 2025)
- **Other Contributors**: Mark Strutz (Trigger modification)

### Deployment History

| Version | Date | Deploy ID | Duration | Tests | Status |
|---------|------|-----------|----------|-------|--------|
| V3 | 2025-10-20 19:51 UTC | 0AfSj000000z1OzKAI | 1m 40s | 14/14 ✅ | Active |
| V2 | 2025-10-08 15:45 UTC | 0AfSj000000yI5JKAU | 1m 47s | 12/12 ✅ | Active |
| V1 | 2025-10-08 15:04 UTC | 0AfSj000000yHsPKAU | 1m 27s | 11/11 ✅ | Active |

### Monitoring Queries

**Check Current Open Case Distribution**:
```sql
SELECT OwnerId, Owner.Name, COUNT(Id) case_count
FROM Case
WHERE Status NOT IN ('Closed', 'Case Closed')
  AND RecordType.DeveloperName = 'Email'
GROUP BY OwnerId, Owner.Name
ORDER BY COUNT(Id) DESC
```

**Check Cases Assigned Today**:
```sql
SELECT Id, CaseNumber, OwnerId, Owner.Name, CreatedDate, Previous_Auto_Assigned_Owner__c
FROM Case
WHERE CreatedDate = TODAY
  AND RecordType.DeveloperName = 'Email'
ORDER BY CreatedDate DESC
```

**Check Custom Setting Values**:
```sql
SELECT Name, Max_Open_Cases_Per_User__c
FROM Case_Auto_Assignment_Settings__c
```

---

**Document Status**: ✅ Complete and Verified
**Last Updated**: October 22, 2025
**Next Review**: After migration to NewOrg
