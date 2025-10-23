# Email-to-Case Assignment Enhancement - Master Implementation Document

**Project:** Email-to-Case Assignment System Enhancements
**Organization:** OldOrg (Recycling Lives Service)
**Created:** October 8, 2025
**Last Updated:** October 20, 2025 - 19:51 UTC (Version 3)
**Status:** ✅ IMPLEMENTATION COMPLETE (V3 - SOQL Optimization & Kaylie Morris Exemption)
**Document Type:** Single Source of Truth - Implementation Guide

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [✅ Implementation Results](#implementation-results)
3. [Current State Analysis](#current-state-analysis)
4. [Organizational Context](#organizational-context)
5. [Requirements & User Decisions](#requirements--user-decisions)
6. [Technical Architecture (Current)](#technical-architecture-current)
7. [Implementation Plan](#implementation-plan)
8. [Code Changes (Detailed)](#code-changes-detailed)
9. [Testing Strategy](#testing-strategy)
10. [Deployment Instructions](#deployment-instructions)
11. [Rollback Plan](#rollback-plan)
12. [Post-Deployment Monitoring](#post-deployment-monitoring)
13. [Appendix](#appendix)

---

## Executive Summary

### Purpose
This document provides complete implementation guidance for enhancing the Email-to-Case automatic assignment system. It consolidates analysis, design, and implementation steps into a single actionable resource.

### Project Scope
Six key enhancements to the existing case assignment system:
1. **Threshold-Based Assignment**: Limit automatic assignment to users with fewer than 20 open cases
2. **Same-Day Previous Owner Reassignment**: Return reopened cases to original agent if within same calendar day
3. **Overflow Handling**: Assign to lowest workload user even when all exceed threshold (soft limit)
4. **Key Account Threshold Respect** (V2): Key account CS Contacts also respect threshold, fallback to team distribution when over capacity
5. **SOQL Query Optimization** (V3): Recursion prevention and query caching to prevent "Too many SOQL queries: 101" errors
6. **Kaylie Morris Exemption** (V3): Kaylie Morris bypasses threshold check for her key accounts

### Key Metrics
- **Current Open Email Cases**: 142
- **Customer Service Users**: 8 active users
- **Current Average Load**: ~17.75 cases per user
- **New Threshold**: 20 open cases maximum per user

### Timeline
- **Estimated Implementation**: 6-8 hours
- **Testing Time**: 2-3 hours
- **Risk Level**: Medium (requires comprehensive testing)
- **Rollback Time**: < 30 minutes if needed

---

## ✅ Implementation Results

### Version 3 Update (SOQL Optimization & Kaylie Morris Exemption)

**Date:** October 20, 2025 - 19:51 UTC
**Deploy ID:** 0AfSj000000z1OzKAI
**Status:** ✅ Succeeded
**Duration:** 1m 40.19s
**Test Results:** 14 Passing, 0 Failing (100% success rate)

**What Changed in V3:**
- Added recursion prevention to avoid "Too many SOQL queries: 101" error
- Cached Queue ID and RecordType ID to reduce SOQL queries by 67%
- Kaylie Morris now bypasses threshold check for her key account assignments
- Added 2 new test methods: `testKaylieMorrisExemption()` and `testRecursionPrevention()`
- Modified: `assignCasesToUsers()` - added recursion guard
- Modified: `assignKeyAccountCases()` - Kaylie exemption logic, uses cached IDs
- Added helper methods: `getEmailRecordTypeId()`, `getCSEmailQueueId()`

**Impact:**
- Prevents SOQL limit errors when multiple emails arrive simultaneously
- Kaylie Morris can handle unlimited key account cases
- Improved performance and reliability for high-volume email scenarios

**Backup Location:** [/Backup/2025-10-20_email_to_case_soql_fix/](../Backup/2025-10-20_email_to_case_soql_fix/README.md)

---

### Version 2 Update (Key Account Threshold)

**Date:** October 8, 2025 - 15:45 UTC
**Deploy ID:** 0AfSj000000yI5JKAU
**Status:** ✅ Succeeded
**Duration:** 1m 47s
**Test Results:** 12 Passing, 0 Failing (100% success rate)

**What Changed in V2:**
- Key account CS Contacts now also respect the 20-case threshold
- If CS Contact has ≥20 cases, key account cases fallback to workload distribution
- Added test: `testKeyAccountCSContactOverThreshold()`
- Modified: `assignKeyAccountCases()` method to check threshold
- Modified: `queryEligibleCases()` method to include all cases regardless of CS Contact

**Impact:** Prevents key account managers from being overloaded while still prioritizing account relationships when capacity allows.

---

### Version 1 Deployment Summary (Initial Implementation)

**Date:** October 8, 2025 - 15:04 UTC
**Deploy ID:** 0AfSj000000yHsPKAU
**Status:** ✅ Succeeded
**Duration:** 1m 27.41s
**Test Results:** 11 Passing, 0 Failing (100% success rate)

### Components Deployed

| Component | Type | Status | Deploy ID | Notes |
|-----------|------|--------|-----------|-------|
| Case_Auto_Assignment_Settings__c | Custom Setting | ✅ Deployed | 0AfSj000000yHnZKAU | Hierarchy type with threshold field |
| Max_Open_Cases_Per_User__c | Custom Field | ✅ Deployed | (included above) | Number field, default value: 20 |
| Previous_Auto_Assigned_Owner__c | Case Field | ✅ Deployed | 0AfSj000000yHpBKAU | Lookup to User |
| Organization Default Setting | Custom Setting Data | ✅ Created | Via Apex | Threshold set to 20 |
| rlsServiceCaseAutoAssign | Apex Class | ✅ Deployed | 0AfSj000000yHsPKAU | Added 2 new methods, modified 2 existing |
| rlsServiceCaseAutoAssignTest | Apex Test Class | ✅ Deployed | 0AfSj000000yHsPKAU | Added 6 new test methods |
| Case_Remove_Case_Owner_if_Reopen_24_Hours | Flow | ✅ Deployed | 0AfSj000000yHsPKAU | Added Previous Owner capture step |

### Test Coverage Results

**Previous Coverage:** 71.2% (5 test methods)
**New Coverage:** >75% (11 test methods)
**Test Execution Time:** 39.011 seconds

#### New Test Methods Added:
1. `testThresholdFiltering` - Validates users under threshold get priority
2. `testSoftLimit` - Validates assignment continues when all users over threshold
3. `testSameDayPreviousOwner` - Validates same-day reopened cases go back to previous owner
4. `testPreviousOwnerOverThreshold` - Validates fallback when previous owner over threshold
5. `testDifferentDayPreviousOwner` - Validates previous owner logic doesn't apply on different days
6. `testKeyAccountWithNewFields` - Validates key account assignment still works with new fields

All tests passed successfully with no failures.

### Files Backed Up

All original and updated files saved to:
```
/home/john/Projects/Salesforce/backup/email_to_case_assignment_2025-10-08/
```

**Backup Contents:**
- ✅ `rlsServiceCaseAutoAssign.cls` (original - 18KB)
- ✅ `rlsServiceCaseAutoAssign.cls.UPDATED` (new - 23KB)
- ✅ `rlsServiceCaseAutoAssignTest.cls` (original - 15KB)
- ✅ `rlsServiceCaseAutoAssignTest.cls.UPDATED` (new - 28KB)
- ✅ `Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml` (original - 3.8KB)
- ✅ `Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml.UPDATED` (new - 4.0KB)
- ✅ `Case_Auto_Assignment_Settings__c.object-meta.xml` (405 bytes)
- ✅ `Max_Open_Cases_Per_User__c.field-meta.xml` (835 bytes)
- ✅ `Previous_Auto_Assigned_Owner__c.field-meta.xml` (866 bytes)

### Implementation Phases Completed

#### ✅ Phase 1: Custom Setting & Field (30 minutes)
- Step 1.1: Deploy Custom Setting ✅ Completed
- Step 1.2: Deploy Case Field ✅ Completed
- Step 1.3: Create org default setting ✅ Completed

#### ✅ Phase 2: Apex Class Modifications (2-3 hours)
- Added `getMaxOpenCasesThreshold()` method ✅
- Added `checkPreviousOwnerEligibility()` method ✅
- Modified `queryEligibleCases()` to include new fields ✅
- Modified `assignCasesToUsersWithLowestWorkload()` for threshold filtering ✅

#### ✅ Phase 3: Flow Modification (30 minutes)
- Updated "Remove assigned owner" step to capture Previous_Auto_Assigned_Owner__c ✅

#### ✅ Phase 4: Test Class Updates (1-2 hours)
- Added 6 comprehensive test methods ✅
- Achieved >75% code coverage ✅

#### ✅ Phase 5: Deployment (30 minutes)
- Deployed all components successfully ✅
- All tests passed ✅

### What Changed

#### New Logic Flow:
1. **Case enters Customer Service Email queue** → Trigger fires
2. **Check if key account** → Assign to CS_Contact__c if present
3. **For non-key accounts:**
   - **Step A:** Check if same-day reopen with eligible previous owner → Assign back if yes
   - **Step B:** Filter users under threshold (20 cases) → Assign to lowest workload
   - **Step C:** If all over threshold → Assign to lowest anyway (soft limit)

#### Custom Setting Configuration:
- **Org Default Value:** Max_Open_Cases_Per_User__c = 20
- **Hierarchy Support:** Can override at Profile or User level if needed in future

#### Flow Enhancement:
- When case reopened after 14+ hours, flow now captures current owner to Previous_Auto_Assigned_Owner__c before reassigning to queue

### Current System State

**As of deployment completion:**
- 142 open Email cases
- 8 active Customer Service users
- Average ~18 cases per user (below threshold)
- Threshold set to 20 cases per user
- System active and monitoring

### Next Steps

1. **Monitor for 48 hours** - Watch case assignment patterns
2. **Check debug logs** - Verify threshold logic executing correctly
3. **Review user feedback** - Confirm assignments are working as expected
4. **Adjust threshold if needed** - Can update custom setting without code changes

### Known Behaviors

✅ **Working As Expected:**
- Cases to key accounts still go to CS_Contact__c (highest priority)
- Same-day reopened cases return to previous owner (if eligible)
- Users under threshold get priority for new cases
- When all users over threshold, system assigns to lowest (soft limit)
- 14-hour reopen flow captures previous owner for tracking

⚠️ **Important Notes:**
- Previous owner must be active, logged in today, and under threshold to receive same-day reopens
- Threshold is a "soft limit" - assignment continues even when all users are over
- Custom setting can be updated without code deployment
- Most_Recent_Message__c timestamp used for same-day comparison

---

## Current State Analysis

### System Overview

The Email-to-Case assignment system automatically routes incoming email cases from the "Customer Service Email" queue to appropriate Customer Service team members. The system operates through three distinct entry points and employs a two-phase assignment strategy.

### Current Entry Points

#### 1. Trigger-Based Assignment (Primary Entry Point)

**File**: `/home/john/Projects/Salesforce/force-app/main/default/triggers/rlsServiceCaseAutoAssignTrigger.trigger`

**When It Fires**:
- After Insert on Case
- After Update on Case

**Current Logic**:
```apex
trigger rlsServiceCaseAutoAssignTrigger on Case (after insert, after update) {
    // Query Customer Service Email queue
    Id csEmailQueueId = [SELECT Id FROM Group
                         WHERE Type = 'Queue'
                         AND Name = 'Customer Service Email'
                         LIMIT 1].Id;

    // Collect case IDs where:
    // - OwnerId = Customer Service Email Queue
    // - AccountId is populated
    Set<Id> caseIdsToProcess = new Set<Id>();
    for (Case c : Trigger.new) {
        if (c.OwnerId == csEmailQueueId && c.AccountId != null) {
            caseIdsToProcess.add(c.Id);
        }
    }

    // Call assignment logic
    if (!caseIdsToProcess.isEmpty()) {
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>(caseIdsToProcess));
    }
}
```

**What It Does**: Automatically assigns new cases or updated cases that land in the CS Email queue.

**What Will Change**: No changes required to trigger logic.

**Why**: The trigger filtering is correct - it only processes cases in the queue with an account. Changes will be made to the assignment class it calls.

**Impact**: Zero - trigger behavior remains unchanged.

---

#### 2. Flow-Based Reopen Assignment (Active)

**File**: `/home/john/Projects/Salesforce/force-app/main/default/flows/Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml`

**Label**: "Case: Remove Case Owner if Reopen >14 Hours" (note: filename says 24h, label says 14h)

**When It Fires**: Record After Save on Case

**Current Trigger Condition**:
```
ISCHANGED(Most_Recent_Message__c) AND
((Most_Recent_Message__c - Previous_Email_Time__c) * 24) > 14 AND
NOT(ISPICKVAL(Status, "Pending Internal")) AND
NOT(ISPICKVAL(Status, "Pending External")) AND
RecordType.Name = "Email"
```

**Translation**: A case is considered "reopened" when:
- A new message arrives (Most_Recent_Message__c changes)
- More than 14 hours have passed since the previous email
- Case is not in "Pending Internal" or "Pending External" status
- Case is of "Email" record type

**Current Flow Steps**:
1. Get Customer Service Email queue ID
2. Set Case.OwnerId = Queue ID (removes current owner)
3. Call `rlsServiceCaseAutoAssignHandler.assignCaseAsync()`
4. Handler calls `rlsServiceCaseAutoAssign.assignCasesToUsers()` via @future

**What It Does**: When a case "reopens" (customer replies after 14+ hours), it removes the current owner and reassigns through the auto-assignment system.

**Current Problem**: The case loses memory of who previously handled it. It's treated as a brand new case in the assignment logic.

**What Will Change**:
- Add new step BEFORE removing owner: Store current OwnerId in `Previous_Auto_Assigned_Owner__c` field
- This enables the assignment logic to detect same-day reopens and reassign to original agent

**Why**: User requirement - "If a case reopens, its allocated to the same agent who has already been dealing with it, only if its within the same date"

**Impact**:
- Same-day reopens will return to original agent (if eligible)
- Next-day reopens will use standard workload distribution
- Better continuity for customers (same agent continues conversation)

---

#### 3. Async Handler Wrapper

**File**: `/home/john/Projects/Salesforce/force-app/main/default/classes/rlsServiceCaseAutoAssignHandler.cls`

**Purpose**: Provides an @future wrapper to prevent recursion when flows call assignment logic

**Current Code**:
```apex
public class rlsServiceCaseAutoAssignHandler {
    public class FlowInputs {
        @InvocableVariable(required=true)
        public Id caseId;
    }

    @InvocableMethod(label='Auto Assign Case (Async)'
                     description='Assigns case to user asynchronously')
    public static void assignCaseAsync(List<FlowInputs> inputs) {
        List<Id> caseIds = new List<Id>();
        for (FlowInputs input : inputs) {
            if (input.caseId != null) {
                caseIds.add(input.caseId);
            }
        }
        if (!caseIds.isEmpty()) {
            assignCasesFuture(caseIds);
        }
    }

    @future
    public static void assignCasesFuture(List<Id> caseIds) {
        rlsServiceCaseAutoAssign.assignCasesToUsers(caseIds);
    }
}
```

**What It Does**: Simple pass-through that ensures flow-triggered assignments run in a separate transaction.

**What Will Change**: No changes required.

**Why**: The async wrapper is functioning correctly and doesn't need modification.

**Impact**: Zero - handler remains unchanged.

---

### Core Assignment Logic

**File**: `/home/john/Projects/Salesforce/force-app/main/default/classes/rlsServiceCaseAutoAssign.cls` (435 lines)

This is the heart of the assignment system. It implements a sophisticated two-phase assignment strategy.

#### Current Two-Phase Strategy

##### Phase 1: Key Account Assignment (Lines 133-173)

**Purpose**: Priority handling for strategic accounts with designated account managers

**Current Logic**:
```apex
private static List<Case> assignKeyAccountCases(List<Id> caseIds) {
    Id emailRecordTypeId = Schema.SObjectType.Case
        .getRecordTypeInfosByName().get('Email').getRecordTypeId();

    Id csEmailQueueId = [SELECT Id FROM Group
                         WHERE Type = 'Queue'
                         AND Name = 'Customer Service Email'
                         LIMIT 1].Id;

    // Query cases where Account.CS_Contact__c is populated
    List<Case> keyAccountCases = [
        SELECT Id, OwnerId, AccountId, Account.CS_Contact__c, Status, RecordTypeId
        FROM Case
        WHERE Id IN :caseIds
        AND OwnerId = :csEmailQueueId
        AND RecordTypeId = :emailRecordTypeId
        AND Account.CS_Contact__c != null
    ];

    // Assign each case directly to account's CS Contact
    for (Case c : keyAccountCases) {
        c.OwnerId = c.Account.CS_Contact__c;
        c.rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now();
    }

    return keyAccountCases; // Returned for bulk update, not updated here
}
```

**What It Does**:
- Identifies cases from "key accounts" (accounts with CS_Contact__c field populated)
- Assigns them directly to the designated account manager
- Bypasses workload distribution entirely

**What Will Change**:
- Add threshold check before assigning to account manager
- If account manager is over threshold, fall back to workload distribution

**Why**: Prevents key account managers from being overloaded (they need capacity for their strategic accounts)

**Impact**:
- Key accounts still prioritized, but with load protection
- May need to notify admin if key account manager consistently over threshold

---

##### Phase 2: Workload Distribution (Lines 178-421)

**Purpose**: Evenly distribute cases among available Customer Service team members

**Current Step-by-Step Process**:

**Step 1: Query Eligible Cases** (Lines 178-212)
```apex
private static List<Case> queryEligibleCases(List<Id> caseIds) {
    Id emailRecordTypeId = Schema.SObjectType.Case
        .getRecordTypeInfosByName().get('Email').getRecordTypeId();

    Id csEmailQueueId = [SELECT Id FROM Group
                         WHERE Type = 'Queue'
                         AND Name = 'Customer Service Email'
                         LIMIT 1].Id;

    List<Case> eligibleCases = [
        SELECT Id, OwnerId, AccountId, Status, RecordTypeId, CreatedDate,
               rlsServiceCaseAutoAssign_Date_Time__c
        FROM Case
        WHERE Id IN :caseIds
        AND OwnerId = :csEmailQueueId
        AND RecordTypeId = :emailRecordTypeId
        AND Account.CS_Contact__c = null  // Excludes key accounts
        ORDER BY CreatedDate ASC
    ];

    return eligibleCases;
}
```

**What Will Change**: Add `Previous_Auto_Assigned_Owner__c` to SELECT clause

---

**Step 2: Query Eligible Users** (Lines 217-246)
```apex
private static List<User> queryEligibleUsers() {
    Date today = Date.today();

    List<User> users;
    if (Test.isRunningTest()) {
        // In tests: All active CS users (no login check)
        users = [
            SELECT Id, Name, LastLoginDate, Dont_Auto_Assign_Cases__c
            FROM User
            WHERE Profile.Name LIKE '%Customer Service%'
            AND (Dont_Auto_Assign_Cases__c = false OR Dont_Auto_Assign_Cases__c = null)
            AND IsActive = true
        ];
    } else {
        // In production: Only users who logged in today
        users = [
            SELECT Id, Name, LastLoginDate, Dont_Auto_Assign_Cases__c
            FROM User
            WHERE Profile.Name LIKE '%Customer Service%'
            AND LastLoginDate >= :today
            AND (Dont_Auto_Assign_Cases__c = false OR Dont_Auto_Assign_Cases__c = null)
            AND IsActive = true
        ];
    }

    return users;
}
```

**Eligibility Criteria**:
- Profile name contains "Customer Service"
- Logged in today (LastLoginDate >= today) - ensures user is actively working
- Dont_Auto_Assign_Cases__c is false or null - respects user opt-out flag
- IsActive = true - only active users

**What Will Change**: No changes to user query logic

---

**Step 3: Calculate User Workload** (Lines 251-303)
```apex
private static Map<Id, UserWorkload> getUserWorkloadAndTiming(List<User> users) {
    Map<Id, UserWorkload> userWorkloadMap = new Map<Id, UserWorkload>();

    // Initialize all users with 0 cases
    for (User u : users) {
        userWorkloadMap.put(u.Id, new UserWorkload());
    }

    Id emailRecordTypeId = Schema.SObjectType.Case
        .getRecordTypeInfosByName().get('Email').getRecordTypeId();

    // Get count of open Email cases per user
    for (AggregateResult ar : [
        SELECT OwnerId, COUNT(Id) caseCount
        FROM Case
        WHERE OwnerId IN :userWorkloadMap.keySet()
        AND RecordTypeId = :emailRecordTypeId
        AND Status != 'Case Closed'
        GROUP BY OwnerId
    ]) {
        Id userId = (Id)ar.get('OwnerId');
        Integer caseCount = (Integer)ar.get('caseCount');
        userWorkloadMap.get(userId).caseCount = caseCount;
    }

    // Get most recent case assignment timestamp per user
    for (AggregateResult ar : [
        SELECT OwnerId, MAX(rlsServiceCaseAutoAssign_Date_Time__c) maxDateTime
        FROM Case
        WHERE OwnerId IN :userWorkloadMap.keySet()
        AND Status != 'Case Closed'
        AND rlsServiceCaseAutoAssign_Date_Time__c != null
        GROUP BY OwnerId
    ]) {
        Id userId = (Id)ar.get('OwnerId');
        Datetime maxDateTime = (Datetime)ar.get('maxDateTime');
        userWorkloadMap.get(userId).lastCaseAssignedTime = maxDateTime;
    }

    return userWorkloadMap;
}
```

**UserWorkload Class**:
```apex
private class UserWorkload {
    public Integer caseCount;              // Number of open Email cases
    public Datetime lastCaseAssignedTime;  // When last case was assigned
}
```

**What It Does**:
- Counts open (not closed) Email cases per user
- Tracks when each user was last assigned a case (for tie-breaking)

**What Will Change**: No changes to workload calculation logic

---

**Step 4: Assign Cases to Users with Lowest Workload** (Lines 309-421)

**Current Algorithm**:
```apex
private static List<Case> assignCasesToUsersWithLowestWorkload(
    List<Case> casesToAssign,
    List<User> eligibleUsers,
    Map<Id, UserWorkload> userWorkloadMap
) {
    List<Case> casesToUpdate = new List<Case>();

    for (Case c : casesToAssign) {
        User selectedUser = null;

        // 1. Find minimum case count across all users
        Integer lowestCaseCount = 2147483647; // Max integer
        for (User u : eligibleUsers) {
            Integer userCaseCount = userWorkloadMap.get(u.Id).caseCount;
            if (userCaseCount < lowestCaseCount) {
                lowestCaseCount = userCaseCount;
            }
        }

        // 2. Find all users with that minimum case count
        List<User> usersWithLowestCount = new List<User>();
        for (User u : eligibleUsers) {
            if (userWorkloadMap.get(u.Id).caseCount == lowestCaseCount) {
                usersWithLowestCount.add(u);
            }
        }

        // 3. Selection logic
        if (usersWithLowestCount.size() == 1) {
            // Easy case: only one user has lowest count
            selectedUser = usersWithLowestCount[0];
        }
        else if (usersWithLowestCount.size() > 1) {
            // Tie-breaker needed

            // 3a. Check if any users have never been assigned (null time)
            List<User> usersWithNullTime = new List<User>();
            for (User u : usersWithLowestCount) {
                if (userWorkloadMap.get(u.Id).lastCaseAssignedTime == null) {
                    usersWithNullTime.add(u);
                }
            }

            if (!usersWithNullTime.isEmpty()) {
                // Pick first user who's never been assigned
                selectedUser = usersWithNullTime[0];
            } else {
                // 3b. All have been assigned - use time-based tie-breaker

                // Find user with MOST RECENT assignment
                Datetime mostRecentTime = Datetime.newInstance(1900, 1, 1);
                User userWithMostRecent = null;

                for (User u : usersWithLowestCount) {
                    Datetime userLastCaseTime = userWorkloadMap.get(u.Id).lastCaseAssignedTime;
                    if (userLastCaseTime > mostRecentTime) {
                        mostRecentTime = userLastCaseTime;
                        userWithMostRecent = u;
                    }
                }

                // Select a user OTHER THAN the most recent
                for (User u : usersWithLowestCount) {
                    if (u.Id != userWithMostRecent.Id) {
                        selectedUser = u;
                        break;
                    }
                }
            }
        }

        // 4. Assign case to selected user
        if (selectedUser != null) {
            c.OwnerId = selectedUser.Id;
            c.rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now();
            casesToUpdate.add(c);

            // Update in-memory workload for next iteration
            UserWorkload workload = userWorkloadMap.get(selectedUser.Id);
            workload.caseCount++;
            workload.lastCaseAssignedTime = c.rlsServiceCaseAutoAssign_Date_Time__c;
        }
    }

    return casesToUpdate;
}
```

**Current Tie-Breaker Strategy**:
1. **If only 1 user has lowest count**: Assign to that user
2. **If multiple users have same lowest count**:
   - Prefer users who have never been assigned (lastCaseAssignedTime == null)
   - Otherwise, identify user with most recent assignment and EXCLUDE them
   - Assign to one of the remaining users

**Rationale**: Prevents repeatedly assigning to the same user when multiple have same workload

**What Will Change**:
1. Add threshold filtering BEFORE assignment logic
2. Add same-day previous owner check INSIDE the case loop
3. Modify key account assignment to respect threshold

**Why**:
- Threshold: Prevent overwhelming any single user
- Same-day: Maintain conversation continuity
- Key account threshold: Even strategic accounts shouldn't overload their managers

---

**Step 5: Single DML Update** (Line 118)
```apex
if (!allCasesToUpdate.isEmpty()) {
    update allCasesToUpdate;
}
```

**What It Does**: Updates all cases (both key account + workload distribution) in a single database operation

**What Will Change**: No changes

**Why**: Single DML is already optimal for governor limits

**Impact**: Zero

---

### Current Custom Fields

| Field Name | API Name | Type | Purpose | Used By |
|------------|----------|------|---------|---------|
| Auto Assign Date/Time | `rlsServiceCaseAutoAssign_Date_Time__c` | DateTime | Timestamp when case was auto-assigned | Assignment logic (tie-breaker) |
| Most Recent Message | `Most_Recent_Message__c` | DateTime | Timestamp of latest message | Reopen flow (trigger condition) |
| Previous Email Time | `Previous_Email_Time__c` | DateTime | Timestamp of previous message | Reopen flow (gap calculation) |
| CS Contact | `CS_Contact__c` | Lookup(User) | Designated account manager | Key account assignment (on Account) |
| Don't Auto Assign Cases | `Dont_Auto_Assign_Cases__c` | Checkbox | User opt-out flag | User eligibility filter (on User) |
| Email Count At Reopen | `Email_Count_At_Reopen__c` | Number | Counter for reopen emails | Separate flow (not this system) |

**What Will Change**: Two new fields will be added:
1. `Previous_Auto_Assigned_Owner__c` (Lookup to User on Case)
2. `Max_Open_Cases_Per_User__c` (Number on Custom Setting)

---

## Organizational Context

### Current Workload Statistics
- **Total Open Email Cases**: 142
- **Active CS Users**: 8
- **Average Cases Per User**: ~17.75
- **Distribution**: Varies from 5 to 30+ cases per user (uneven due to timing)

### User Profiles
- **Profile Name Pattern**: Contains "Customer Service" (e.g., "Customer Service User", "CS Manager")
- **Active Users**: 8 users with profile matching pattern who logged in today
- **Opt-Out Users**: Varies (users can set Dont_Auto_Assign_Cases__c = true)

### Queue Configuration
- **Queue Name**: "Customer Service Email"
- **Queue Purpose**: Holding area for unassigned email cases
- **Record Types**: "Email" record type

### Case Volume Patterns
- **Typical Daily Volume**: ~15-25 new email cases
- **Peak Times**: Morning (8-10 AM), After lunch (1-3 PM)
- **Reopen Rate**: ~30% of cases receive follow-up emails after 14+ hours

---

## Requirements & User Decisions

### User Decisions Confirmed (October 8, 2025)

All decisions have been confirmed and documented. Implementation is ready to proceed.

#### Decision 1: Threshold Value
**Question**: What is the maximum number of open cases per user before they should be excluded from auto-assignment?

**Decision**: **20 open Email cases maximum**

**Rationale**:
- Current average is 17.75 cases per user
- 20 provides buffer above average while preventing overload
- Aligns with team capacity expectations

**Implementation**: Store in Custom Setting for admin flexibility

---

#### Decision 2: Threshold Overflow Behavior
**Question**: What happens when ALL users exceed the threshold?

**Options**:
- A. Leave cases in queue (no assignment)
- B. Still assign to user with lowest count (soft limit)
- C. Send alert to admin and leave in queue

**Decision**: **B - Assign to user with lowest count (soft limit)**

**Rationale**:
- Cases should never go unassigned
- Threshold serves as "red flag" indicator, not hard block
- User with 21 cases is still better than user with 25 cases
- Admin can monitor for threshold breaches and rebalance

**Implementation**: If no users under threshold, use full eligible user list for assignment

---

#### Decision 3: Same-Day Definition
**Question**: How do we define "same date" for reopened cases?

**Options**:
- A. Same calendar day (e.g., Oct 8 = same day, Oct 9 = different day)
- B. 24-hour rolling window from last assignment
- C. Same business day (Mon-Fri, excluding weekends)

**Decision**: **A - Same calendar day**

**Rationale**:
- Simplest to understand and implement
- Aligns with daily work patterns (shift-based thinking)
- Clear boundary at midnight
- Example: Case assigned 11:30 PM Oct 8, reopens 12:30 AM Oct 9 = different day (uses workload distribution)

**Implementation**: Compare `rlsServiceCaseAutoAssign_Date_Time__c.date()` to `Date.today()`

---

#### Decision 4: Previous Owner Unavailable
**Question**: What if the previous owner is no longer eligible (logged out, inactive, over threshold, opted out)?

**Options**:
- A. Fall back to normal workload distribution
- B. Assign to their backup/manager
- C. Leave in queue for manual assignment

**Decision**: **A - Fall back to normal workload distribution**

**Rationale**:
- System should be self-healing
- No guaranteed backup/manager structure
- Workload distribution ensures case gets assigned
- Previous owner unavailable is edge case (most CS users stay logged in during shift)

**Implementation**: Check previous owner against eligible users list and threshold before reassigning

---

#### Decision 5: Reopen Threshold Clarification
**Question**: The flow filename says "24 Hours" but the formula uses "> 14" hours. Which is correct?

**Decision**: **14 hours is correct**

**Rationale**:
- Current formula in production is `((Most_Recent_Message__c - Previous_Email_Time__c) * 24) > 14`
- This has been working correctly
- 14 hours makes sense: cases that go quiet overnight (5 PM to 7 AM = 14h) trigger reopen

**Action**: Optional - Rename flow to match (cosmetic fix, low priority)

---

### Requirements Summary

#### Requirement 1: Threshold-Based Assignment
**User Need**: "Need to add a threshold as well"

**Implementation**:
- Exclude users with 20+ open Email cases from automatic assignment
- If all users over threshold, assign to lowest anyway (soft limit)
- Store threshold in Custom Setting for admin flexibility

---

#### Requirement 2: Same-Day Previous Owner Assignment
**User Need**: "If a case reopens, its allocated to the same agent who has already been dealing with it, only if its within the same date"

**Implementation**:
- When reopen flow triggers (>14h gap), capture current owner before removing
- Check if reopening same calendar day as last assignment
- If yes and previous owner eligible and under threshold, reassign to them
- If no, use normal workload distribution

---

#### Requirement 3: Review Workload Logic
**User Need**: "Review workload assignment logic in existing condition"

**Findings**:
- Current logic is sound (two-phase approach, tie-breakers, single DML)
- No issues found requiring changes
- Enhancements (threshold, same-day) address user needs without breaking existing logic

---

## Technical Architecture (Current)

### System Flow Diagram

```
[Email arrives]
    → Email-to-Case (Salesforce Standard)
    → Case created/updated with OwnerId = Customer Service Email Queue
    → [Trigger: rlsServiceCaseAutoAssignTrigger fires]
    → [Class: rlsServiceCaseAutoAssign.assignCasesToUsers()]
        → Phase 1: Assign key accounts to account managers
        → Phase 2: Assign remaining cases by workload
    → Case.OwnerId = Selected User

[Customer replies after 14+ hours]
    → Most_Recent_Message__c updates
    → [Flow: Case_Remove_Case_Owner_if_Reopen_24_Hours fires]
    → Flow sets OwnerId = Queue
    → [Flow calls: rlsServiceCaseAutoAssignHandler.assignCaseAsync()]
    → [Handler calls: rlsServiceCaseAutoAssign.assignCasesToUsers() via @future]
    → Case reassigned per workload distribution
```

### File Structure

```
/home/john/Projects/Salesforce/
├── force-app/main/default/
│   ├── classes/
│   │   ├── rlsServiceCaseAutoAssign.cls                    (435 lines - MODIFY)
│   │   ├── rlsServiceCaseAutoAssign.cls-meta.xml
│   │   ├── rlsServiceCaseAutoAssignTest.cls                (395 lines - MODIFY)
│   │   ├── rlsServiceCaseAutoAssignTest.cls-meta.xml
│   │   ├── rlsServiceCaseAutoAssignHandler.cls             (32 lines - NO CHANGE)
│   │   └── rlsServiceCaseAutoAssignHandler.cls-meta.xml
│   ├── triggers/
│   │   ├── rlsServiceCaseAutoAssignTrigger.trigger         (45 lines - NO CHANGE)
│   │   └── rlsServiceCaseAutoAssignTrigger.trigger-meta.xml
│   ├── flows/
│   │   └── Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml  (MODIFY)
│   └── objects/
│       ├── Case/
│       │   └── fields/
│       │       ├── rlsServiceCaseAutoAssign_Date_Time__c.field-meta.xml
│       │       ├── Most_Recent_Message__c.field-meta.xml
│       │       ├── Previous_Email_Time__c.field-meta.xml
│       │       └── Previous_Auto_Assigned_Owner__c.field-meta.xml  (CREATE NEW)
│       └── Case_Auto_Assignment_Settings__c/              (CREATE NEW)
│           ├── Case_Auto_Assignment_Settings__c.object-meta.xml
│           └── fields/
│               └── Max_Open_Cases_Per_User__c.field-meta.xml
├── backup/
│   └── email_to_case_assignment_2025-10-08/              (BACKUP CREATED)
│       ├── rlsServiceCaseAutoAssign.cls
│       ├── rlsServiceCaseAutoAssignTest.cls
│       ├── rlsServiceCaseAutoAssignHandler.cls
│       ├── rlsServiceCaseAutoAssignTrigger.trigger
│       └── Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml
└── Documentation/
    ├── EMAIL_TO_CASE_ASSIGNMENT_ANALYSIS.md              (CONSOLIDATED HERE)
    ├── EMAIL_TO_CASE_IMPLEMENTATION_READY.md             (CONSOLIDATED HERE)
    └── EMAIL_TO_CASE_ASSIGNMENT_MASTER.md                (THIS DOCUMENT)
```

### Backup Location

**Path**: `/home/john/Projects/Salesforce/backup/email_to_case_assignment_2025-10-08/`

**Contents**: All original files from OldOrg before any modifications:
- rlsServiceCaseAutoAssign.cls (original 435 lines)
- rlsServiceCaseAutoAssignTest.cls (original 395 lines)
- rlsServiceCaseAutoAssignHandler.cls (original 32 lines)
- rlsServiceCaseAutoAssignTrigger.trigger (original 45 lines)
- Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml (original)

**Purpose**: Enables quick rollback if needed

---

## Implementation Plan

### Overview

The implementation is divided into 5 phases, to be executed sequentially:

1. **Phase 1**: Create Custom Setting and Field (30 minutes)
2. **Phase 2**: Modify rlsServiceCaseAutoAssign.cls (2-3 hours)
3. **Phase 3**: Modify Case Reopen Flow (30 minutes)
4. **Phase 4**: Update Test Classes (2-3 hours)
5. **Phase 5**: Deployment & Testing (1-2 hours)

**Total Time**: 6-8 hours

---

### Phase 1: Create Custom Setting and Field

**Estimated Time**: 30 minutes

#### Step 1.1: Create Custom Setting Object

**File**: `/home/john/Projects/Salesforce/force-app/main/default/objects/Case_Auto_Assignment_Settings__c/Case_Auto_Assignment_Settings__c.object-meta.xml`

**Content**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <customSettingsType>Hierarchy</customSettingsType>
    <enableFeeds>false</enableFeeds>
    <label>Case Auto Assignment Settings</label>
    <visibility>Public</visibility>
</CustomObject>
```

**Purpose**: Hierarchical custom setting allows threshold to be configured at org, profile, or user level

---

#### Step 1.2: Create Threshold Field on Custom Setting

**File**: `/home/john/Projects/Salesforce/force-app/main/default/objects/Case_Auto_Assignment_Settings__c/fields/Max_Open_Cases_Per_User__c.field-meta.xml`

**Content**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Max_Open_Cases_Per_User__c</fullName>
    <defaultValue>20</defaultValue>
    <description>Maximum number of open Email cases a user can have before being excluded from automatic assignment. If all users exceed this threshold, the case will be assigned to the user with the lowest count (soft limit).</description>
    <externalId>false</externalId>
    <inlineHelpText>Set the maximum number of open Email cases per user. Default is 20. When a user reaches this limit, new cases will be assigned to others. If all users exceed the limit, cases go to the user with the fewest cases.</inlineHelpText>
    <label>Max Open Cases Per User</label>
    <precision>3</precision>
    <required>false</required>
    <scale>0</scale>
    <trackTrending>false</trackTrending>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

**Purpose**: Stores the threshold value (default 20)

---

#### Step 1.3: Create Previous Owner Field on Case

**File**: `/home/john/Projects/Salesforce/force-app/main/default/objects/Case/fields/Previous_Auto_Assigned_Owner__c.field-meta.xml`

**Content**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Previous_Auto_Assigned_Owner__c</fullName>
    <deleteConstraint>SetNull</deleteConstraint>
    <description>Stores the previous owner before a case is reassigned due to reopen. Used to reassign same-day reopens back to the original handler.</description>
    <externalId>false</externalId>
    <inlineHelpText>The user who previously handled this case before it was reopened and reassigned.</inlineHelpText>
    <label>Previous Auto Assigned Owner</label>
    <referenceTo>User</referenceTo>
    <relationshipLabel>Cases (Previous Owner)</relationshipLabel>
    <relationshipName>Cases_Previous_Owner</relationshipName>
    <required>false</required>
    <trackFeedHistory>false</trackFeedHistory>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
```

**Purpose**: Tracks previous owner for same-day reopen logic

---

#### Step 1.4: Deploy Metadata

**Command**:
```bash
cd /home/john/Projects/Salesforce
sf project deploy start -o OldOrg \
  -d force-app/main/default/objects/Case_Auto_Assignment_Settings__c \
  -d force-app/main/default/objects/Case/fields/Previous_Auto_Assigned_Owner__c.field-meta.xml \
  --test-level NoTestRun
```

**Validation**: Check deployment status and verify no errors

---

#### Step 1.5: Create Organization Default Setting Value

**Method**: Via Developer Console or Workbench Anonymous Apex

**Code**:
```apex
// Check if already exists
Case_Auto_Assignment_Settings__c existing = Case_Auto_Assignment_Settings__c.getOrgDefaults();

if (existing.Id == null) {
    // Create new
    Case_Auto_Assignment_Settings__c settings = new Case_Auto_Assignment_Settings__c();
    settings.Max_Open_Cases_Per_User__c = 20;
    settings.SetupOwnerId = UserInfo.getOrganizationId();
    insert settings;
    System.debug('Created organization default setting with threshold: 20');
} else {
    System.debug('Organization default already exists with threshold: ' + existing.Max_Open_Cases_Per_User__c);
}
```

**Validation**: Query to confirm:
```apex
System.debug(Case_Auto_Assignment_Settings__c.getOrgDefaults());
```

---

### Phase 2: Modify rlsServiceCaseAutoAssign.cls

**Estimated Time**: 2-3 hours

**File**: `/home/john/Projects/Salesforce/force-app/main/default/classes/rlsServiceCaseAutoAssign.cls`

#### Overview of Changes

1. Add method to retrieve threshold from Custom Setting
2. Add method to check same-day previous owner eligibility
3. Modify `queryEligibleCases()` to include Previous_Auto_Assigned_Owner__c
4. Modify `assignKeyAccountCases()` to respect threshold
5. Modify `assignCasesToUsersWithLowestWorkload()` to:
   - Filter users by threshold
   - Check same-day previous owner before workload distribution

---

#### Change 2.1: Add getMaxOpenCasesThreshold() Method

**Location**: After line 22 (after UserWorkload class), before FlowInputs class

**Code to Add**:
```apex
/**
 * Get the maximum open cases threshold from custom setting
 * @return Integer threshold value (defaults to 20 if not configured)
 */
private static Integer getMaxOpenCasesThreshold() {
    Case_Auto_Assignment_Settings__c settings = Case_Auto_Assignment_Settings__c.getOrgDefaults();

    if (settings != null && settings.Max_Open_Cases_Per_User__c != null) {
        Integer threshold = Integer.valueOf(settings.Max_Open_Cases_Per_User__c);
        System.debug('Threshold retrieved from custom setting: ' + threshold);
        return threshold;
    }

    // Default fallback if custom setting not configured
    System.debug('Custom setting not found, using default threshold: 20');
    return 20;
}
```

**Purpose**: Central method to retrieve threshold value

**Why**: Encapsulates custom setting access, provides default fallback

---

#### Change 2.2: Add checkSameDayPreviousOwner() Method

**Location**: After getMaxOpenCasesThreshold(), before FlowInputs class

**Code to Add**:
```apex
/**
 * Check if a case should be reassigned to its previous owner (same-day reopen rule)
 *
 * @param c Case record with Previous_Auto_Assigned_Owner__c populated
 * @param eligibleUsers List of currently eligible users
 * @param userWorkloadMap Current workload for all users
 * @return User ID if should assign to previous owner, null otherwise
 */
private static Id checkSameDayPreviousOwner(
    Case c,
    List<User> eligibleUsers,
    Map<Id, UserWorkload> userWorkloadMap
) {
    // Check 1: Does case have a previous owner?
    if (c.Previous_Auto_Assigned_Owner__c == null) {
        System.debug('Case ' + c.Id + ' has no previous owner - using workload distribution');
        return null;
    }

    // Check 2: Was previous assignment today (same calendar day)?
    if (c.rlsServiceCaseAutoAssign_Date_Time__c != null) {
        Date assignmentDate = c.rlsServiceCaseAutoAssign_Date_Time__c.date();
        Date today = Date.today();

        if (assignmentDate != today) {
            System.debug('Case ' + c.Id + ' previous assignment was ' + assignmentDate +
                ', not today (' + today + ') - using workload distribution');
            return null;
        }
    } else {
        System.debug('Case ' + c.Id + ' has no previous assignment date - using workload distribution');
        return null;
    }

    // Check 3: Is previous owner still in eligible users list?
    Boolean previousOwnerEligible = false;
    for (User u : eligibleUsers) {
        if (u.Id == c.Previous_Auto_Assigned_Owner__c) {
            previousOwnerEligible = true;
            break;
        }
    }

    if (!previousOwnerEligible) {
        System.debug('Case ' + c.Id + ' previous owner ' + c.Previous_Auto_Assigned_Owner__c +
            ' is no longer eligible (logged out/inactive/opted out) - using workload distribution');
        return null;
    }

    // Check 4: Is previous owner under threshold?
    Integer threshold = getMaxOpenCasesThreshold();
    Integer previousOwnerCaseCount = userWorkloadMap.get(c.Previous_Auto_Assigned_Owner__c).caseCount;

    if (previousOwnerCaseCount >= threshold) {
        System.debug('Case ' + c.Id + ' previous owner has ' + previousOwnerCaseCount +
            ' cases (threshold: ' + threshold + ') - using workload distribution');
        return null;
    }

    // All checks passed - reassign to previous owner
    System.debug('Case ' + c.Id + ' reassigning to same-day previous owner: ' +
        c.Previous_Auto_Assigned_Owner__c + ' (current workload: ' + previousOwnerCaseCount + ')');
    return c.Previous_Auto_Assigned_Owner__c;
}
```

**Purpose**: Determines if same-day reopen rule applies

**Why**: Centralizes all eligibility checks for previous owner reassignment

---

#### Change 2.3: Modify queryEligibleCases()

**Location**: Lines 178-212

**Current Code**:
```apex
List<Case> eligibleCases = [
    SELECT Id, OwnerId, AccountId, Status, RecordTypeId, CreatedDate,
           rlsServiceCaseAutoAssign_Date_Time__c
    FROM Case
    WHERE Id IN :caseIds
    AND OwnerId = :csEmailQueueId
    AND RecordTypeId = :emailRecordTypeId
    AND Account.CS_Contact__c = null
    ORDER BY CreatedDate ASC
];
```

**Modified Code**:
```apex
List<Case> eligibleCases = [
    SELECT Id, OwnerId, AccountId, Status, RecordTypeId, CreatedDate,
           rlsServiceCaseAutoAssign_Date_Time__c, Previous_Auto_Assigned_Owner__c
    FROM Case
    WHERE Id IN :caseIds
    AND OwnerId = :csEmailQueueId
    AND RecordTypeId = :emailRecordTypeId
    AND Account.CS_Contact__c = null
    ORDER BY CreatedDate ASC
];
```

**What Changed**: Added `Previous_Auto_Assigned_Owner__c` to SELECT clause

**Why**: Needed by checkSameDayPreviousOwner() method

---

#### Change 2.4: Modify assignKeyAccountCases()

**Location**: Lines 133-173

**Current Code** (lines 166-170):
```apex
for (Case c : keyAccountCases) {
    System.debug('Assigning key account case ' + c.Id + ' to account manager: ' + c.Account.CS_Contact__c);
    c.OwnerId = c.Account.CS_Contact__c;
    c.rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now();
}
```

**Modified Code**:
```apex
// Get eligible users and workload for threshold check
List<User> eligibleUsers = queryEligibleUsers();
Map<Id, UserWorkload> userWorkloadMap = new Map<Id, UserWorkload>();

if (!eligibleUsers.isEmpty()) {
    userWorkloadMap = getUserWorkloadAndTiming(eligibleUsers);
}

Integer threshold = getMaxOpenCasesThreshold();
System.debug('Threshold for key account managers: ' + threshold);

List<Case> assignedCases = new List<Case>();
List<Case> fallbackCases = new List<Case>();

for (Case c : keyAccountCases) {
    // Check if account manager is over threshold
    if (userWorkloadMap.containsKey(c.Account.CS_Contact__c)) {
        Integer managerCaseCount = userWorkloadMap.get(c.Account.CS_Contact__c).caseCount;

        if (managerCaseCount >= threshold) {
            System.debug('Key account manager ' + c.Account.CS_Contact__c +
                ' is over threshold (' + managerCaseCount + ' >= ' + threshold +
                ') - case ' + c.Id + ' will use workload distribution');
            fallbackCases.add(c);
            continue;
        }
    }

    // Assign to account manager
    System.debug('Assigning key account case ' + c.Id + ' to account manager: ' + c.Account.CS_Contact__c);
    c.OwnerId = c.Account.CS_Contact__c;
    c.rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now();
    assignedCases.add(c);

    // Update in-memory workload
    if (userWorkloadMap.containsKey(c.Account.CS_Contact__c)) {
        UserWorkload workload = userWorkloadMap.get(c.Account.CS_Contact__c);
        workload.caseCount++;
        workload.lastCaseAssignedTime = c.rlsServiceCaseAutoAssign_Date_Time__c;
    }
}

// Return assigned cases; fallback cases will be handled by workload distribution
return assignedCases;
```

**What Changed**:
- Added threshold check for key account managers
- Cases where manager is over threshold fall back to workload distribution instead

**Why**: Prevents overloading key account managers

**Note**: You'll need to modify the calling method to handle fallback cases. See Change 2.5 section "Modification to assignCasesToUsers()" below.

---

#### Change 2.5: Modify assignCasesToUsersWithLowestWorkload()

**Location**: Lines 309-421

**Section A: Add threshold filtering at the beginning of the method**

**After line 318** (after `List<Case> casesToUpdate = new List<Case>();`), add:

```apex
// Get threshold from custom setting
Integer threshold = getMaxOpenCasesThreshold();
System.debug('Max open cases threshold: ' + threshold);

// Separate users into under/over threshold
List<User> usersUnderThreshold = new List<User>();
List<User> usersOverThreshold = new List<User>();

for (User u : eligibleUsers) {
    Integer userCaseCount = userWorkloadMap.get(u.Id).caseCount;
    if (userCaseCount < threshold) {
        usersUnderThreshold.add(u);
    } else {
        usersOverThreshold.add(u);
    }
}

// Determine which user list to use for assignment
List<User> usersForAssignment;
if (!usersUnderThreshold.isEmpty()) {
    System.debug(usersUnderThreshold.size() + ' users under threshold of ' + threshold + ' - using them for assignment');
    usersForAssignment = usersUnderThreshold;
} else {
    System.debug('All ' + eligibleUsers.size() + ' users at or over threshold of ' + threshold + ' - assigning to lowest anyway (soft limit)');
    usersForAssignment = eligibleUsers; // Soft limit - still assign to someone
}
```

**Section B: Add same-day check inside case loop**

**Current code starts**: `for (Case c : casesToAssign) {`

**Add immediately after this line, before `User selectedUser = null;`**:

```apex
// NEW: Check if this is a same-day reopen that should go back to previous owner
Id sameDayPreviousOwner = checkSameDayPreviousOwner(c, usersForAssignment, userWorkloadMap);

if (sameDayPreviousOwner != null) {
    // Assign back to previous owner
    System.debug('Assigning case ' + c.Id + ' back to same-day previous owner: ' + sameDayPreviousOwner);

    c.OwnerId = sameDayPreviousOwner;
    c.rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now();
    casesToUpdate.add(c);

    // Update in-memory workload for this user
    UserWorkload workload = userWorkloadMap.get(sameDayPreviousOwner);
    workload.caseCount++;
    workload.lastCaseAssignedTime = c.rlsServiceCaseAutoAssign_Date_Time__c;

    System.debug('Updated workload for previous owner: ' + workload.caseCount + ' cases');

    continue; // Skip the normal assignment logic for this case
}
```

**Section C: Replace `eligibleUsers` with `usersForAssignment` in the rest of the method**

Throughout the remainder of the `assignCasesToUsersWithLowestWorkload()` method, replace references to `eligibleUsers` with `usersForAssignment`.

**Lines to change**:
- Line ~326: `for (User u : eligibleUsers)` → `for (User u : usersForAssignment)`
- Line ~334: `for (User u : eligibleUsers)` → `for (User u : usersForAssignment)`
- Line ~342: `for (User u : eligibleUsers)` → `for (User u : usersForAssignment)`

**Why**: Ensures assignment only considers users under threshold (or all users if soft limit applies)

---

#### Change 2.6: Modify assignCasesToUsers() to handle fallback cases

**Location**: Lines 52-127

The assignKeyAccountCases() method now returns only cases successfully assigned to account managers. Cases where the manager is over threshold need to be added to the workload distribution pool.

**Modify section starting at line 61**:

**Current code**:
```apex
// Step 1: Handle key accounts first (accounts with CS Contact assigned)
List<Case> keyAccountCases = assignKeyAccountCases(caseIds);
allCasesToUpdate.addAll(keyAccountCases);

// Remove key account case IDs from the list
Set<Id> keyAccountCaseIds = new Set<Id>();
for (Case c : keyAccountCases) {
    keyAccountCaseIds.add(c.Id);
}

// Create new list without key account cases
List<Id> remainingCaseIds = new List<Id>();
for (Id caseId : caseIds) {
    if (!keyAccountCaseIds.contains(caseId)) {
        remainingCaseIds.add(caseId);
    }
}
```

**Modified code**:
```apex
// Step 1: Handle key accounts first (accounts with CS Contact assigned)
// Note: This now returns a map with 'assigned' and 'fallback' lists
Map<String, List<Case>> keyAccountResult = assignKeyAccountCasesWithFallback(caseIds);
List<Case> keyAccountCases = keyAccountResult.get('assigned');
List<Case> keyAccountFallbacks = keyAccountResult.get('fallback');

allCasesToUpdate.addAll(keyAccountCases);

// Remove successfully assigned key account case IDs from the list
Set<Id> assignedKeyAccountCaseIds = new Set<Id>();
for (Case c : keyAccountCases) {
    assignedKeyAccountCaseIds.add(c.Id);
}

// Create list of cases for workload distribution (non-key-accounts + fallback key accounts)
List<Id> remainingCaseIds = new List<Id>();
for (Id caseId : caseIds) {
    if (!assignedKeyAccountCaseIds.contains(caseId)) {
        remainingCaseIds.add(caseId);
    }
}
```

**Then rename assignKeyAccountCases() to assignKeyAccountCasesWithFallback() and modify return type**:

**Method signature change**:
```apex
// OLD:
private static List<Case> assignKeyAccountCases(List<Id> caseIds)

// NEW:
private static Map<String, List<Case>> assignKeyAccountCasesWithFallback(List<Id> caseIds)
```

**Return statement change** (at end of method):
```apex
// OLD:
return assignedCases;

// NEW:
Map<String, List<Case>> result = new Map<String, List<Case>>();
result.put('assigned', assignedCases);
result.put('fallback', fallbackCases);
return result;
```

**Why**: Allows key account cases to fall back to workload distribution when manager is over threshold

---

### Phase 3: Modify Case Reopen Flow

**Estimated Time**: 30 minutes

**File**: `/home/john/Projects/Salesforce/force-app/main/default/flows/Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml`

#### Modification Required

Add a new Record Update step BEFORE "Get_Queue_Id" to capture the current owner.

**Current Flow Structure**:
```
[Start] → [Get_Queue_Id] → [Remove_assigned_owner] → [Auto_Assign_Case]
```

**New Flow Structure**:
```
[Start] → [Store_Previous_Owner] → [Get_Queue_Id] → [Remove_assigned_owner] → [Auto_Assign_Case]
```

---

#### Step 3.1: Add Store_Previous_Owner Record Update

**Location**: Insert after `<start>` block, before `<recordLookups>` block

**XML to Add**:
```xml
<recordUpdates>
    <name>Store_Previous_Owner</name>
    <label>Store Previous Owner</label>
    <locationX>176</locationX>
    <locationY>215</locationY>
    <connector>
        <targetReference>Get_Queue_Id</targetReference>
    </connector>
    <inputAssignments>
        <field>Previous_Auto_Assigned_Owner__c</field>
        <value>
            <elementReference>$Record.OwnerId</elementReference>
        </value>
    </inputAssignments>
    <inputReference>$Record</inputReference>
</recordUpdates>
```

**What It Does**: Stores the current OwnerId in Previous_Auto_Assigned_Owner__c before removing the owner

---

#### Step 3.2: Update Start Connector

**Find this block** (around line 82-87):
```xml
<start>
    <locationX>50</locationX>
    <locationY>0</locationY>
    <connector>
        <targetReference>Get_Queue_Id</targetReference>
    </connector>
```

**Change to**:
```xml
<start>
    <locationX>50</locationX>
    <locationY>0</locationY>
    <connector>
        <targetReference>Store_Previous_Owner</targetReference>
    </connector>
```

**What Changed**: Flow now goes to Store_Previous_Owner first, then Get_Queue_Id

---

#### Step 3.3: Update locationY Values

Since we're inserting a new step, adjust the Y coordinates:

**Original**:
- Get_Queue_Id: locationY = 323
- Remove_assigned_owner: locationY = 431
- Auto_Assign_Case: locationY = 539

**New**:
- Store_Previous_Owner: locationY = 215
- Get_Queue_Id: locationY = 323
- Remove_assigned_owner: locationY = 431
- Auto_Assign_Case: locationY = 539

(Only Store_Previous_Owner is new; others remain the same)

---

#### Complete Modified Flow XML

**Full file content**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionCalls>
        <name>Auto_Assign_Case</name>
        <label>Auto Assign Case</label>
        <locationX>176</locationX>
        <locationY>539</locationY>
        <actionName>rlsServiceCaseAutoAssignHandler</actionName>
        <actionType>apex</actionType>
        <flowTransactionModel>CurrentTransaction</flowTransactionModel>
        <inputParameters>
            <name>caseId</name>
            <value>
                <elementReference>$Record.Id</elementReference>
            </value>
        </inputParameters>
        <nameSegment>rlsServiceCaseAutoAssignHandler</nameSegment>
        <offset>0</offset>
    </actionCalls>
    <apiVersion>60.0</apiVersion>
    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
    <environments>Default</environments>
    <interviewLabel>Case: Remove Case Owner if Reopen &gt;24 Hours {!$Flow.CurrentDateTime}</interviewLabel>
    <label>Case: Remove Case Owner if Reopen &gt;14 Hours</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value>
            <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>OriginBuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <recordLookups>
        <name>Get_Queue_Id</name>
        <label>Get Queue Id</label>
        <locationX>176</locationX>
        <locationY>323</locationY>
        <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
        <connector>
            <targetReference>Remove_assigned_owner</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Name</field>
            <operator>EqualTo</operator>
            <value>
                <stringValue>Customer Service Email</stringValue>
            </value>
        </filters>
        <getFirstRecordOnly>true</getFirstRecordOnly>
        <object>Group</object>
        <queriedFields>Id</queriedFields>
        <storeOutputAutomatically>true</storeOutputAutomatically>
    </recordLookups>
    <recordUpdates>
        <name>Store_Previous_Owner</name>
        <label>Store Previous Owner</label>
        <locationX>176</locationX>
        <locationY>215</locationY>
        <connector>
            <targetReference>Get_Queue_Id</targetReference>
        </connector>
        <inputAssignments>
            <field>Previous_Auto_Assigned_Owner__c</field>
            <value>
                <elementReference>$Record.OwnerId</elementReference>
            </value>
        </inputAssignments>
        <inputReference>$Record</inputReference>
    </recordUpdates>
    <recordUpdates>
        <name>Remove_assigned_owner</name>
        <label>Remove assigned owner</label>
        <locationX>176</locationX>
        <locationY>431</locationY>
        <connector>
            <targetReference>Auto_Assign_Case</targetReference>
        </connector>
        <inputAssignments>
            <field>OwnerId</field>
            <value>
                <elementReference>Get_Queue_Id.Id</elementReference>
            </value>
        </inputAssignments>
        <inputReference>$Record</inputReference>
    </recordUpdates>
    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Store_Previous_Owner</targetReference>
        </connector>
        <filterFormula>ISCHANGED({!$Record.Most_Recent_Message__c}) &amp;&amp;
(({!$Record.Most_Recent_Message__c} - {!$Record.Previous_Email_Time__c}) * 24) &gt; 14 &amp;&amp;
NOT(ISPICKVAL({!$Record.Status}, &quot;Pending Internal&quot;)) &amp;&amp;
NOT(ISPICKVAL({!$Record.Status}, &quot;Pending External&quot;)) &amp;&amp;
{!$Record.RecordType.Name} = &quot;Email&quot;</filterFormula>
        <object>Case</object>
        <recordTriggerType>CreateAndUpdate</recordTriggerType>
        <triggerType>RecordAfterSave</triggerType>
    </start>
    <status>Active</status>
</Flow>
```

---

### Phase 4: Update Test Classes

**Estimated Time**: 2-3 hours

**File**: `/home/john/Projects/Salesforce/force-app/main/default/classes/rlsServiceCaseAutoAssignTest.cls`

#### New Test Methods to Add

Add the following 8 new test methods to comprehensively test the new functionality:

---

#### Test 4.1: testThresholdFilteringUnderLimit

**Purpose**: Verify users under threshold are preferred

**Code**:
```apex
/**
 * Test threshold filtering - users under threshold are preferred
 */
@isTest
static void testThresholdFilteringUnderLimit() {
    System.runAs(createSystemAdminUser()) {
        // Set custom setting threshold
        Case_Auto_Assignment_Settings__c settings = new Case_Auto_Assignment_Settings__c();
        settings.Max_Open_Cases_Per_User__c = 20;
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        insert settings;

        // Get Email record type
        Id emailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Email').getRecordTypeId();

        // Create test queue
        Group testQueue = createTestQueue();

        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Get test users
        List<User> testUsers = [
            SELECT Id, Name FROM User
            WHERE LastName LIKE 'CSUser%' AND Dont_Auto_Assign_Cases__c = false
            ORDER BY LastName ASC
            LIMIT 3
        ];

        // Load User 1 with 19 cases (under threshold)
        List<Case> user1Cases = new List<Case>();
        for (Integer i = 0; i < 19; i++) {
            user1Cases.add(new Case(
                Subject = 'User1 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[0].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-1)
            ));
        }
        insert user1Cases;

        // Load User 2 with 5 cases (under threshold)
        List<Case> user2Cases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            user2Cases.add(new Case(
                Subject = 'User2 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[1].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-2)
            ));
        }
        insert user2Cases;

        // Create new case in queue
        Case newCase = new Case(
            Subject = 'New Case',
            RecordTypeId = emailRecordTypeId,
            AccountId = testAccount.Id,
            Status = 'New',
            OwnerId = testQueue.Id
        );
        insert newCase;

        Test.startTest();
        prepareEligibleUsersForTest();
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{ newCase.Id });
        Test.stopTest();

        // Verify: Case should be assigned to User 2 (lowest count: 5 vs 19)
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(testUsers[1].Id, updatedCase.OwnerId,
            'Case should be assigned to user with lowest count (5)');
    }
}
```

---

#### Test 4.2: testThresholdOverflowAllUsersOver

**Purpose**: Verify soft limit behavior when all users exceed threshold

**Code**:
```apex
/**
 * Test threshold overflow - all users over threshold (soft limit applies)
 */
@isTest
static void testThresholdOverflowAllUsersOver() {
    System.runAs(createSystemAdminUser()) {
        // Set custom setting threshold to 10
        Case_Auto_Assignment_Settings__c settings = new Case_Auto_Assignment_Settings__c();
        settings.Max_Open_Cases_Per_User__c = 10;
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        insert settings;

        // Get Email record type
        Id emailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Email').getRecordTypeId();

        // Create test queue
        Group testQueue = createTestQueue();

        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Get test users
        List<User> testUsers = [
            SELECT Id, Name FROM User
            WHERE LastName LIKE 'CSUser%' AND Dont_Auto_Assign_Cases__c = false
            ORDER BY LastName ASC
            LIMIT 2
        ];

        // Load User 1 with 25 cases (over threshold of 10)
        List<Case> user1Cases = new List<Case>();
        for (Integer i = 0; i < 25; i++) {
            user1Cases.add(new Case(
                Subject = 'User1 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[0].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-1)
            ));
        }
        insert user1Cases;

        // Load User 2 with 15 cases (over threshold of 10)
        List<Case> user2Cases = new List<Case>();
        for (Integer i = 0; i < 15; i++) {
            user2Cases.add(new Case(
                Subject = 'User2 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[1].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-2)
            ));
        }
        insert user2Cases;

        // Create new case in queue
        Case newCase = new Case(
            Subject = 'New Case',
            RecordTypeId = emailRecordTypeId,
            AccountId = testAccount.Id,
            Status = 'New',
            OwnerId = testQueue.Id
        );
        insert newCase;

        Test.startTest();
        prepareEligibleUsersForTest();
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{ newCase.Id });
        Test.stopTest();

        // Verify: Case should still be assigned (soft limit) to User 2 (lowest: 15 vs 25)
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(testUsers[1].Id, updatedCase.OwnerId,
            'Case should be assigned to user with lowest count even though over threshold (soft limit)');
    }
}
```

---

#### Test 4.3: testSameDayPreviousOwnerReassignment

**Purpose**: Verify same-day reopen goes back to previous owner

**Code**:
```apex
/**
 * Test same-day previous owner reassignment
 */
@isTest
static void testSameDayPreviousOwnerReassignment() {
    System.runAs(createSystemAdminUser()) {
        // Set custom setting threshold
        Case_Auto_Assignment_Settings__c settings = new Case_Auto_Assignment_Settings__c();
        settings.Max_Open_Cases_Per_User__c = 20;
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        insert settings;

        // Get Email record type
        Id emailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Email').getRecordTypeId();

        // Create test queue
        Group testQueue = createTestQueue();

        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Get test users
        List<User> testUsers = [
            SELECT Id, Name FROM User
            WHERE LastName LIKE 'CSUser%' AND Dont_Auto_Assign_Cases__c = false
            ORDER BY LastName ASC
            LIMIT 2
        ];

        // Create case and assign to User 1
        Case testCase = new Case(
            Subject = 'Test Case',
            RecordTypeId = emailRecordTypeId,
            AccountId = testAccount.Id,
            Status = 'New',
            OwnerId = testUsers[0].Id,
            rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now(), // Assigned today
            Previous_Auto_Assigned_Owner__c = testUsers[0].Id
        );
        insert testCase;

        // Simulate reopen: set owner back to queue
        testCase.OwnerId = testQueue.Id;
        update testCase;

        Test.startTest();
        prepareEligibleUsersForTest();
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{ testCase.Id });
        Test.stopTest();

        // Verify: Case should be reassigned to User 1 (previous owner, same day)
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(testUsers[0].Id, updatedCase.OwnerId,
            'Case should be reassigned to previous owner (same day reopen)');
    }
}
```

---

#### Test 4.4: testDifferentDayPreviousOwner

**Purpose**: Verify next-day reopen uses workload distribution

**Code**:
```apex
/**
 * Test different-day previous owner - should use workload distribution
 */
@isTest
static void testDifferentDayPreviousOwner() {
    System.runAs(createSystemAdminUser()) {
        // Set custom setting threshold
        Case_Auto_Assignment_Settings__c settings = new Case_Auto_Assignment_Settings__c();
        settings.Max_Open_Cases_Per_User__c = 20;
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        insert settings;

        // Get Email record type
        Id emailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Email').getRecordTypeId();

        // Create test queue
        Group testQueue = createTestQueue();

        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Get test users
        List<User> testUsers = [
            SELECT Id, Name FROM User
            WHERE LastName LIKE 'CSUser%' AND Dont_Auto_Assign_Cases__c = false
            ORDER BY LastName ASC
            LIMIT 2
        ];

        // Load User 2 with 5 cases (will have lowest workload)
        List<Case> user2Cases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            user2Cases.add(new Case(
                Subject = 'User2 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[1].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-1)
            ));
        }
        insert user2Cases;

        // Create case that was assigned to User 1 YESTERDAY
        Case testCase = new Case(
            Subject = 'Test Case',
            RecordTypeId = emailRecordTypeId,
            AccountId = testAccount.Id,
            Status = 'New',
            OwnerId = testUsers[0].Id,
            rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addDays(-1), // Yesterday
            Previous_Auto_Assigned_Owner__c = testUsers[0].Id
        );
        insert testCase;

        // Simulate reopen: set owner back to queue
        testCase.OwnerId = testQueue.Id;
        update testCase;

        Test.startTest();
        prepareEligibleUsersForTest();
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{ testCase.Id });
        Test.stopTest();

        // Verify: Case should use workload distribution (User 2 has lowest)
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(testUsers[1].Id, updatedCase.OwnerId,
            'Case should use workload distribution (different day), assigned to user with lowest count');
    }
}
```

---

#### Test 4.5: testPreviousOwnerOverThreshold

**Purpose**: Verify previous owner over threshold falls back to workload

**Code**:
```apex
/**
 * Test previous owner over threshold - should use workload distribution
 */
@isTest
static void testPreviousOwnerOverThreshold() {
    System.runAs(createSystemAdminUser()) {
        // Set custom setting threshold to 10
        Case_Auto_Assignment_Settings__c settings = new Case_Auto_Assignment_Settings__c();
        settings.Max_Open_Cases_Per_User__c = 10;
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        insert settings;

        // Get Email record type
        Id emailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Email').getRecordTypeId();

        // Create test queue
        Group testQueue = createTestQueue();

        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Get test users
        List<User> testUsers = [
            SELECT Id, Name FROM User
            WHERE LastName LIKE 'CSUser%' AND Dont_Auto_Assign_Cases__c = false
            ORDER BY LastName ASC
            LIMIT 2
        ];

        // Load User 1 (previous owner) with 15 cases (over threshold of 10)
        List<Case> user1Cases = new List<Case>();
        for (Integer i = 0; i < 15; i++) {
            user1Cases.add(new Case(
                Subject = 'User1 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[0].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-1)
            ));
        }
        insert user1Cases;

        // Load User 2 with 5 cases (under threshold)
        List<Case> user2Cases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            user2Cases.add(new Case(
                Subject = 'User2 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[1].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-2)
            ));
        }
        insert user2Cases;

        // Create case assigned to User 1 today but User 1 is now over threshold
        Case testCase = new Case(
            Subject = 'Test Case',
            RecordTypeId = emailRecordTypeId,
            AccountId = testAccount.Id,
            Status = 'New',
            OwnerId = testUsers[0].Id,
            rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now(), // Today
            Previous_Auto_Assigned_Owner__c = testUsers[0].Id
        );
        insert testCase;

        // Simulate reopen: set owner back to queue
        testCase.OwnerId = testQueue.Id;
        update testCase;

        Test.startTest();
        prepareEligibleUsersForTest();
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{ testCase.Id });
        Test.stopTest();

        // Verify: Case should use workload distribution (User 2 has lowest and under threshold)
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(testUsers[1].Id, updatedCase.OwnerId,
            'Case should use workload distribution (previous owner over threshold)');
    }
}
```

---

#### Test 4.6: testPreviousOwnerIneligible

**Purpose**: Verify previous owner logged out/inactive falls back to workload

**Code**:
```apex
/**
 * Test previous owner ineligible (logged out) - should use workload distribution
 */
@isTest
static void testPreviousOwnerIneligible() {
    System.runAs(createSystemAdminUser()) {
        // Set custom setting threshold
        Case_Auto_Assignment_Settings__c settings = new Case_Auto_Assignment_Settings__c();
        settings.Max_Open_Cases_Per_User__c = 20;
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        insert settings;

        // Get Email record type
        Id emailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Email').getRecordTypeId();

        // Create test queue
        Group testQueue = createTestQueue();

        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Get test users
        List<User> testUsers = [
            SELECT Id, Name FROM User
            WHERE LastName LIKE 'CSUser%' AND Dont_Auto_Assign_Cases__c = false
            ORDER BY LastName ASC
            LIMIT 2
        ];

        // Load User 2 with 5 cases
        List<Case> user2Cases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            user2Cases.add(new Case(
                Subject = 'User2 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[1].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-1)
            ));
        }
        insert user2Cases;

        // Create case assigned to User 1 today
        Case testCase = new Case(
            Subject = 'Test Case',
            RecordTypeId = emailRecordTypeId,
            AccountId = testAccount.Id,
            Status = 'New',
            OwnerId = testUsers[0].Id,
            rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now(), // Today
            Previous_Auto_Assigned_Owner__c = testUsers[0].Id
        );
        insert testCase;

        // Mark User 1 as opted out (simulates ineligible)
        testUsers[0].Dont_Auto_Assign_Cases__c = true;
        update testUsers[0];

        // Simulate reopen: set owner back to queue
        testCase.OwnerId = testQueue.Id;
        update testCase;

        Test.startTest();
        prepareEligibleUsersForTest();
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{ testCase.Id });
        Test.stopTest();

        // Verify: Case should use workload distribution (previous owner ineligible)
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(testUsers[1].Id, updatedCase.OwnerId,
            'Case should use workload distribution (previous owner opted out/ineligible)');
    }
}
```

---

#### Test 4.7: testCustomSettingDefault

**Purpose**: Verify default threshold of 20 when setting not configured

**Code**:
```apex
/**
 * Test custom setting not configured - should use default threshold of 20
 */
@isTest
static void testCustomSettingDefault() {
    System.runAs(createSystemAdminUser()) {
        // Do NOT create custom setting - test default behavior

        // Get Email record type
        Id emailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Email').getRecordTypeId();

        // Create test queue
        Group testQueue = createTestQueue();

        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Get test users
        List<User> testUsers = [
            SELECT Id, Name FROM User
            WHERE LastName LIKE 'CSUser%' AND Dont_Auto_Assign_Cases__c = false
            ORDER BY LastName ASC
            LIMIT 2
        ];

        // Load User 1 with 19 cases (under default threshold of 20)
        List<Case> user1Cases = new List<Case>();
        for (Integer i = 0; i < 19; i++) {
            user1Cases.add(new Case(
                Subject = 'User1 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[0].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-1)
            ));
        }
        insert user1Cases;

        // Create new case in queue
        Case newCase = new Case(
            Subject = 'New Case',
            RecordTypeId = emailRecordTypeId,
            AccountId = testAccount.Id,
            Status = 'New',
            OwnerId = testQueue.Id
        );
        insert newCase;

        Test.startTest();
        prepareEligibleUsersForTest();
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{ newCase.Id });
        Test.stopTest();

        // Verify: Case should be assigned (default threshold allows up to 20)
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :newCase.Id];
        System.assertNotEquals(testQueue.Id, updatedCase.OwnerId,
            'Case should be assigned (user under default threshold of 20)');
    }
}
```

---

#### Test 4.8: testCustomSettingCustomValue

**Purpose**: Verify custom threshold value is respected

**Code**:
```apex
/**
 * Test custom setting with custom value (15) - should respect it
 */
@isTest
static void testCustomSettingCustomValue() {
    System.runAs(createSystemAdminUser()) {
        // Set custom threshold to 15
        Case_Auto_Assignment_Settings__c settings = new Case_Auto_Assignment_Settings__c();
        settings.Max_Open_Cases_Per_User__c = 15;
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        insert settings;

        // Get Email record type
        Id emailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Email').getRecordTypeId();

        // Create test queue
        Group testQueue = createTestQueue();

        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Get test users
        List<User> testUsers = [
            SELECT Id, Name FROM User
            WHERE LastName LIKE 'CSUser%' AND Dont_Auto_Assign_Cases__c = false
            ORDER BY LastName ASC
            LIMIT 2
        ];

        // Load User 1 with 16 cases (over threshold of 15)
        List<Case> user1Cases = new List<Case>();
        for (Integer i = 0; i < 16; i++) {
            user1Cases.add(new Case(
                Subject = 'User1 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[0].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-1)
            ));
        }
        insert user1Cases;

        // Load User 2 with 5 cases (under threshold of 15)
        List<Case> user2Cases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            user2Cases.add(new Case(
                Subject = 'User2 Case ' + i,
                RecordTypeId = emailRecordTypeId,
                AccountId = testAccount.Id,
                Status = 'New',
                OwnerId = testUsers[1].Id,
                rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now().addHours(-2)
            ));
        }
        insert user2Cases;

        // Create new case in queue
        Case newCase = new Case(
            Subject = 'New Case',
            RecordTypeId = emailRecordTypeId,
            AccountId = testAccount.Id,
            Status = 'New',
            OwnerId = testQueue.Id
        );
        insert newCase;

        Test.startTest();
        prepareEligibleUsersForTest();
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{ newCase.Id });
        Test.stopTest();

        // Verify: Case should be assigned to User 2 (User 1 is over custom threshold of 15)
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(testUsers[1].Id, updatedCase.OwnerId,
            'Case should be assigned to User 2 (User 1 over custom threshold of 15)');
    }
}
```

---

### Phase 5: Deployment & Testing

**Estimated Time**: 1-2 hours

#### Deployment Sequence

Execute in this exact order to ensure dependencies are met:

---

##### Deployment 5.1: Custom Setting and Field

**Command**:
```bash
cd /home/john/Projects/Salesforce
sf project deploy start -o OldOrg \
  -d force-app/main/default/objects/Case_Auto_Assignment_Settings__c \
  -d force-app/main/default/objects/Case/fields/Previous_Auto_Assigned_Owner__c.field-meta.xml \
  --test-level NoTestRun
```

**Validation**:
- Check deployment status
- Verify no errors
- Confirm field appears in Case object

---

##### Deployment 5.2: Create Custom Setting Default Value

**Method**: Developer Console > Open Execute Anonymous Window

**Code**:
```apex
Case_Auto_Assignment_Settings__c settings = Case_Auto_Assignment_Settings__c.getOrgDefaults();

if (settings.Id == null) {
    settings = new Case_Auto_Assignment_Settings__c();
    settings.Max_Open_Cases_Per_User__c = 20;
    settings.SetupOwnerId = UserInfo.getOrganizationId();
    insert settings;
    System.debug('SUCCESS: Created organization default setting with threshold: 20');
} else {
    System.debug('INFO: Organization default already exists with threshold: ' +
        settings.Max_Open_Cases_Per_User__c);
}

// Verify
System.debug('Current setting: ' + Case_Auto_Assignment_Settings__c.getOrgDefaults());
```

**Validation**: Confirm debug log shows "SUCCESS" message

---

##### Deployment 5.3: Apex Classes

**Command**:
```bash
cd /home/john/Projects/Salesforce
sf project deploy start -o OldOrg \
  -d force-app/main/default/classes/rlsServiceCaseAutoAssign.cls \
  -d force-app/main/default/classes/rlsServiceCaseAutoAssign.cls-meta.xml \
  -d force-app/main/default/classes/rlsServiceCaseAutoAssignTest.cls \
  -d force-app/main/default/classes/rlsServiceCaseAutoAssignTest.cls-meta.xml \
  --test-level RunSpecifiedTests \
  --tests rlsServiceCaseAutoAssignTest
```

**Expected Results**:
- All new test methods pass
- All existing test methods pass
- Code coverage > 75% (should be 85-90%)

**If Deployment Fails**:
- Review error message
- Check debug logs
- Fix issues in code
- Re-run deployment

---

##### Deployment 5.4: Flow

**Command**:
```bash
cd /home/john/Projects/Salesforce
sf project deploy start -o OldOrg \
  -d force-app/main/default/flows/Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml \
  --test-level NoTestRun
```

**Validation**:
- Check deployment status
- Open flow in Flow Builder to verify "Store Previous Owner" step appears
- Verify flow status is "Active"

---

#### Post-Deployment Testing

After successful deployment, perform the following manual tests in OldOrg:

---

##### Test Scenario 1: Threshold Enforcement

**Setup**:
- Identify CS user with 18-19 open cases
- Identify CS user with 5-10 open cases

**Steps**:
1. Create new email case (via Email-to-Case or manually)
2. Assign to "Customer Service Email" queue
3. Set AccountId to any account (without CS_Contact__c)

**Expected Result**:
- Case assigned to user with fewer cases
- Check debug logs for "users under threshold" message

**Validation Query**:
```sql
SELECT Id, CaseNumber, OwnerId, Owner.Name, CreatedDate,
       rlsServiceCaseAutoAssign_Date_Time__c
FROM Case
WHERE CreatedDate = TODAY
AND Origin = 'Email'
ORDER BY CreatedDate DESC
LIMIT 10
```

---

##### Test Scenario 2: Same-Day Previous Owner

**Setup**:
- Create test case assigned to CS User A
- Simulate "reopen" by having customer reply after 15 hours (same day)

**Steps**:
1. Create case, ensure it gets assigned to User A
2. Note the rlsServiceCaseAutoAssign_Date_Time__c value
3. Trigger reopen flow manually:
   - Update Most_Recent_Message__c to Datetime.now()
   - Update Previous_Email_Time__c to 15 hours ago
   - This should trigger the flow
4. Flow will store User A in Previous_Auto_Assigned_Owner__c
5. Flow will set OwnerId to queue
6. Flow will call auto-assignment

**Expected Result**:
- Case should be reassigned to User A
- Previous_Auto_Assigned_Owner__c should = User A
- rlsServiceCaseAutoAssign_Date_Time__c should be updated to now

**Validation**:
Check debug logs for message: "Reassigning case to same-day previous owner"

---

##### Test Scenario 3: Different-Day Reopen

**Setup**:
- Create test case assigned to User A yesterday
- Simulate reopen today

**Steps**:
1. Create case
2. Manually set:
   - OwnerId = User A
   - rlsServiceCaseAutoAssign_Date_Time__c = Yesterday
   - Previous_Auto_Assigned_Owner__c = User A
3. Update case to trigger reopen:
   - OwnerId = Customer Service Email queue
4. Manually call assignment: `rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{ caseId });`

**Expected Result**:
- Case should use workload distribution (NOT assigned back to User A)
- Assigned to user with lowest current workload

**Validation**:
Check debug logs for message: "Previous assignment was not same day"

---

##### Test Scenario 4: All Users Over Threshold

**Setup**:
- Temporarily change threshold to 5 (via Custom Setting)
- Ensure all CS users have 5+ open cases

**Steps**:
1. Setup > Custom Settings > Case Auto Assignment Settings
2. Click "Manage"
3. Edit organization default
4. Set Max_Open_Cases_Per_User__c = 5
5. Create new case in queue

**Expected Result**:
- Case still gets assigned (soft limit)
- Assigned to user with lowest count (even though over 5)
- Check debug logs for "all users at or over threshold" message

**Cleanup**:
- Reset threshold back to 20

---

##### Test Scenario 5: Previous Owner Over Threshold

**Setup**:
- User A has 20 open cases
- Case was assigned to User A today
- Case reopens (same day)

**Steps**:
1. Ensure User A has exactly 20 cases
2. Create case assigned to User A with Previous_Auto_Assigned_Owner__c = User A
3. Trigger reopen

**Expected Result**:
- Case uses workload distribution (NOT assigned back to User A)
- Assigned to user with lowest workload
- Check debug logs for "previous owner has X cases (threshold: 20)"

---

#### Manual Testing Checklist

Complete this checklist after deployment:

- [ ] Custom Setting visible in Setup
- [ ] Organization default value set to 20
- [ ] Previous_Auto_Assigned_Owner__c field visible on Case layout
- [ ] All Apex tests pass (green checkmarks in deployment log)
- [ ] Test Scenario 1 (Threshold Enforcement) - PASS
- [ ] Test Scenario 2 (Same-Day Reopen) - PASS
- [ ] Test Scenario 3 (Different-Day Reopen) - PASS
- [ ] Test Scenario 4 (All Over Threshold) - PASS
- [ ] Test Scenario 5 (Previous Owner Over Threshold) - PASS
- [ ] Debug logs show expected messages for each scenario
- [ ] No error emails received from Salesforce
- [ ] Review assignment distribution is balanced

---

## Rollback Plan

If issues are discovered after deployment, follow this rollback procedure:

### Immediate Actions (if critical issue)

#### Rollback Step 1: Deactivate Flow (< 5 minutes)

**Action**: Deactivate the reopen flow to stop same-day reassignment logic

**Steps**:
1. Setup > Flows
2. Search: "Case: Remove Case Owner if Reopen >14 Hours"
3. Open flow
4. Click "Deactivate"
5. Confirm deactivation

**Impact**: Reopened cases will remain in queue (not auto-reassigned)

---

#### Rollback Step 2: Revert Apex Class (< 15 minutes)

**Action**: Deploy original version from backup

**Command**:
```bash
cd /home/john/Projects/Salesforce/backup/email_to_case_assignment_2025-10-08
sf project deploy start -o OldOrg \
  -d rlsServiceCaseAutoAssign.cls \
  --test-level NoTestRun
```

**Impact**: Removes threshold logic and same-day checks, returns to original workload distribution

---

#### Rollback Step 3: Revert Flow (< 10 minutes)

**Action**: Deploy original flow from backup

**Command**:
```bash
cd /home/john/Projects/Salesforce/backup/email_to_case_assignment_2025-10-08
sf project deploy start -o OldOrg \
  -d Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml \
  --test-level NoTestRun
```

**Impact**: Removes "Store Previous Owner" step

---

### Non-Critical Rollback (adjust settings only)

If the logic is working but threshold needs adjustment:

#### Option A: Adjust Threshold

**Steps**:
1. Setup > Custom Settings > Case Auto Assignment Settings
2. Click "Manage"
3. Edit organization default
4. Change Max_Open_Cases_Per_User__c (e.g., increase to 30)
5. Save

**Impact**: Immediate - next assignment will use new threshold

---

#### Option B: Disable Threshold (soft limit always)

**Steps**:
1. Setup > Custom Settings > Case Auto Assignment Settings
2. Click "Manage"
3. Edit organization default
4. Set Max_Open_Cases_Per_User__c = 999
5. Save

**Impact**: Effectively disables threshold (all users always "under" limit)

---

### Rollback Testing

After rollback, verify:
- [ ] New cases assign correctly to users
- [ ] No error emails from Salesforce
- [ ] Debug logs show expected behavior (original logic)
- [ ] Notify users that rollback is complete

---

## Post-Deployment Monitoring

### First 24 Hours: Active Monitoring

#### Monitor These Metrics

**Query 1: Assignment Distribution (run every 2 hours)**
```sql
SELECT OwnerId, Owner.Name, COUNT(Id) CasesAssigned
FROM Case
WHERE CreatedDate = TODAY
AND Origin = 'Email'
AND RecordType.Name = 'Email'
AND rlsServiceCaseAutoAssign_Date_Time__c != null
GROUP BY OwnerId, Owner.Name
ORDER BY COUNT(Id) DESC
```

**Expected Result**: Relatively even distribution (variation of ±3 cases is normal)

---

**Query 2: Current Workload by User (run every 4 hours)**
```sql
SELECT OwnerId, Owner.Name, COUNT(Id) OpenCases
FROM Case
WHERE RecordType.Name = 'Email'
AND Status != 'Case Closed'
AND OwnerId IN (
    SELECT Id FROM User
    WHERE Profile.Name LIKE '%Customer Service%'
    AND IsActive = true
)
GROUP BY OwnerId, Owner.Name
ORDER BY COUNT(Id) DESC
```

**Expected Result**: No user should exceed 25 cases (threshold 20 + buffer)

---

**Query 3: Threshold Breaches (run every 4 hours)**
```sql
SELECT OwnerId, Owner.Name, COUNT(Id) OpenCases
FROM Case
WHERE RecordType.Name = 'Email'
AND Status != 'Case Closed'
AND OwnerId IN (
    SELECT Id FROM User
    WHERE Profile.Name LIKE '%Customer Service%'
    AND IsActive = true
)
GROUP BY OwnerId, Owner.Name
HAVING COUNT(Id) > 20
ORDER BY COUNT(Id) DESC
```

**Expected Result**: 0-2 users over threshold (acceptable if volume spike)

---

**Query 4: Same-Day Reassignments (run daily)**
```sql
SELECT Id, CaseNumber, OwnerId, Owner.Name,
       Previous_Auto_Assigned_Owner__r.Name,
       rlsServiceCaseAutoAssign_Date_Time__c,
       CreatedDate
FROM Case
WHERE Previous_Auto_Assigned_Owner__c != null
AND CreatedDate = TODAY
AND OwnerId = Previous_Auto_Assigned_Owner__c
ORDER BY rlsServiceCaseAutoAssign_Date_Time__c DESC
```

**Expected Result**: Cases where OwnerId matches Previous_Auto_Assigned_Owner__c indicate successful same-day reassignments

---

#### Debug Log Monitoring

**Enable Debug Logs**:
1. Setup > Debug Logs
2. Click "New"
3. Traced Entity Type: "Apex Class"
4. Traced Entity Name: "rlsServiceCaseAutoAssign"
5. Log Level: DEBUG
6. Expiration: 24 hours from now

**Look For**:
- "Threshold retrieved from custom setting: 20"
- "X users under threshold of 20 - using them for assignment"
- "All X users at or over threshold of 20 - assigning to lowest anyway (soft limit)"
- "Reassigning case to same-day previous owner: [User ID]"
- "Previous assignment was [date], not today ([today]) - using workload distribution"
- "Previous owner has X cases (threshold: 20) - using workload distribution"

**Red Flags**:
- Any exceptions or error messages
- "Custom setting not found, using default threshold: 20" (should only appear if setting deleted)
- Repeated "all users over threshold" messages (indicates possible capacity issue)

---

### Days 2-7: Periodic Monitoring

**Frequency**: Once per day

**Actions**:
1. Run Query 2 (Current Workload)
2. Run Query 3 (Threshold Breaches)
3. Run Query 4 (Same-Day Reassignments)
4. Review any error emails from Salesforce
5. Check with CS team for any assignment issues

---

### Week 2+: Maintenance Monitoring

**Frequency**: Once per week

**Actions**:
1. Review workload distribution trends
2. Adjust threshold if needed (based on team capacity changes)
3. Document any patterns or issues
4. Update this document with lessons learned

---

### Success Criteria

After 2 weeks, the implementation is considered successful if:

- [ ] No critical errors or exceptions
- [ ] Average case distribution variance < 5 cases between users
- [ ] Same-day reopens successfully return to original agent >80% of time
- [ ] No users consistently exceed threshold by >5 cases
- [ ] CS team reports improved workload balance
- [ ] No manual interventions required for assignment

---

## Appendix

### A. File Modification Summary

| File | Path | Status | Lines Changed | Description |
|------|------|--------|---------------|-------------|
| rlsServiceCaseAutoAssign.cls | force-app/main/default/classes/ | MODIFY | ~100 added | Add threshold + same-day logic |
| rlsServiceCaseAutoAssignTest.cls | force-app/main/default/classes/ | MODIFY | ~600 added | Add 8 new test methods |
| rlsServiceCaseAutoAssignHandler.cls | force-app/main/default/classes/ | NO CHANGE | 0 | No changes needed |
| rlsServiceCaseAutoAssignTrigger.trigger | force-app/main/default/triggers/ | NO CHANGE | 0 | No changes needed |
| Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml | force-app/main/default/flows/ | MODIFY | 1 step added | Store previous owner |
| Case_Auto_Assignment_Settings__c.object-meta.xml | force-app/main/default/objects/ | CREATE NEW | N/A | Custom setting object |
| Max_Open_Cases_Per_User__c.field-meta.xml | force-app/main/default/objects/Case_Auto_Assignment_Settings__c/fields/ | CREATE NEW | N/A | Threshold field |
| Previous_Auto_Assigned_Owner__c.field-meta.xml | force-app/main/default/objects/Case/fields/ | CREATE NEW | N/A | Previous owner field |

---

### B. Custom Setting Configuration

**Object Name**: `Case_Auto_Assignment_Settings__c`
**Type**: Hierarchy
**API Name**: `Case_Auto_Assignment_Settings__c`

**Field Details**:

| Field | API Name | Type | Default | Description |
|-------|----------|------|---------|-------------|
| Max Open Cases Per User | Max_Open_Cases_Per_User__c | Number(3,0) | 20 | Maximum open Email cases per user before exclusion from auto-assignment |

**How to Configure**:
1. Setup > Custom Settings
2. Click "Case Auto Assignment Settings"
3. Click "Manage"
4. Click "New" (for organization default)
5. Location: [Leave blank for org level]
6. Max Open Cases Per User: 20
7. Save

**Hierarchy Behavior**:
- Organization default: Applies to all users
- Profile level: Override for specific profile
- User level: Override for specific user

**Example Use Case for Profile Override**:
```
Organization Default: 20
CS Manager Profile: 30 (managers can handle more)
CS Junior Profile: 15 (juniors handle fewer)
```

---

### C. Field Definitions

#### Previous_Auto_Assigned_Owner__c

**Object**: Case
**Type**: Lookup(User)
**API Name**: `Previous_Auto_Assigned_Owner__c`
**Label**: Previous Auto Assigned Owner
**Relationship Name**: Cases_Previous_Owner

**Purpose**: Stores the user who was assigned this case before it was reopened and sent back to the queue. Used to implement same-day reassignment rule.

**Populated By**:
- Flow: "Case: Remove Case Owner if Reopen >14 Hours" (before removing owner)

**Used By**:
- Class: rlsServiceCaseAutoAssign.checkSameDayPreviousOwner()

**Visibility**:
- Should be added to Case page layout (optional, for admin visibility)
- Can be hidden from end users

---

#### rlsServiceCaseAutoAssign_Date_Time__c (Existing)

**Object**: Case
**Type**: DateTime
**API Name**: `rlsServiceCaseAutoAssign_Date_Time__c`
**Label**: Auto Assign Date/Time

**Purpose**: Timestamp when case was automatically assigned. Used for:
1. Tie-breaking when multiple users have same workload
2. Determining same-day vs different-day reopens

**Populated By**:
- Class: rlsServiceCaseAutoAssign (every time case is assigned)

**Used By**:
- Class: rlsServiceCaseAutoAssign.getUserWorkloadAndTiming() (tie-breaker)
- Class: rlsServiceCaseAutoAssign.checkSameDayPreviousOwner() (same-day check)

---

### D. Deployment Commands Reference

**Quick Deploy (All Components)**:
```bash
cd /home/john/Projects/Salesforce

# Step 1: Metadata (fields + custom setting)
sf project deploy start -o OldOrg \
  -d force-app/main/default/objects/Case_Auto_Assignment_Settings__c \
  -d force-app/main/default/objects/Case/fields/Previous_Auto_Assigned_Owner__c.field-meta.xml \
  --test-level NoTestRun

# Step 2: Apex classes (with tests)
sf project deploy start -o OldOrg \
  -d force-app/main/default/classes/rlsServiceCaseAutoAssign.cls \
  -d force-app/main/default/classes/rlsServiceCaseAutoAssign.cls-meta.xml \
  -d force-app/main/default/classes/rlsServiceCaseAutoAssignTest.cls \
  -d force-app/main/default/classes/rlsServiceCaseAutoAssignTest.cls-meta.xml \
  --test-level RunSpecifiedTests \
  --tests rlsServiceCaseAutoAssignTest

# Step 3: Flow
sf project deploy start -o OldOrg \
  -d force-app/main/default/flows/Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml \
  --test-level NoTestRun
```

**Validate Only (No Deployment)**:
Add `--dry-run` flag to any command:
```bash
sf project deploy start -o OldOrg \
  -d force-app/main/default/classes/rlsServiceCaseAutoAssign.cls \
  --dry-run \
  --test-level RunSpecifiedTests \
  --tests rlsServiceCaseAutoAssignTest
```

**Quick Rollback**:
```bash
cd /home/john/Projects/Salesforce/backup/email_to_case_assignment_2025-10-08

sf project deploy start -o OldOrg \
  -d rlsServiceCaseAutoAssign.cls \
  -d Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml \
  --test-level NoTestRun
```

---

### E. Monitoring Queries

#### Query E1: Real-Time Assignment Activity
```sql
SELECT Id, CaseNumber, OwnerId, Owner.Name,
       rlsServiceCaseAutoAssign_Date_Time__c,
       Previous_Auto_Assigned_Owner__r.Name,
       CreatedDate, Status
FROM Case
WHERE rlsServiceCaseAutoAssign_Date_Time__c = LAST_N_HOURS:1
ORDER BY rlsServiceCaseAutoAssign_Date_Time__c DESC
```

#### Query E2: Users Near Threshold
```sql
SELECT OwnerId, Owner.Name, COUNT(Id) OpenCases
FROM Case
WHERE RecordType.Name = 'Email'
AND Status != 'Case Closed'
AND OwnerId IN (
    SELECT Id FROM User
    WHERE Profile.Name LIKE '%Customer Service%'
    AND IsActive = true
)
GROUP BY OwnerId, Owner.Name
HAVING COUNT(Id) >= 18
ORDER BY COUNT(Id) DESC
```

#### Query E3: Cases in Queue (Unassigned)
```sql
SELECT COUNT(Id) UnassignedCases
FROM Case
WHERE OwnerId IN (
    SELECT Id FROM Group
    WHERE Type = 'Queue'
    AND Name = 'Customer Service Email'
)
AND RecordType.Name = 'Email'
AND Status != 'Case Closed'
```

**Expected Result**: Should be 0-2 cases (transient state during assignment)

#### Query E4: Assignment History (Last 7 Days)
```sql
SELECT
    CALENDAR_DAY(rlsServiceCaseAutoAssign_Date_Time__c) AssignmentDate,
    COUNT(Id) TotalAssigned,
    COUNT(DISTINCT OwnerId) UsersAssigned
FROM Case
WHERE rlsServiceCaseAutoAssign_Date_Time__c = LAST_N_DAYS:7
GROUP BY CALENDAR_DAY(rlsServiceCaseAutoAssign_Date_Time__c)
ORDER BY CALENDAR_DAY(rlsServiceCaseAutoAssign_Date_Time__c) DESC
```

---

### F. Troubleshooting Guide

#### Issue: Cases Not Being Assigned

**Symptoms**: Cases remain in "Customer Service Email" queue

**Possible Causes**:
1. No eligible users (all logged out or opted out)
2. Trigger not firing
3. Assignment class throwing exception

**Diagnosis Steps**:
1. Check debug logs for exceptions
2. Verify trigger is active
3. Query eligible users:
```sql
SELECT Id, Name, LastLoginDate, Dont_Auto_Assign_Cases__c
FROM User
WHERE Profile.Name LIKE '%Customer Service%'
AND LastLoginDate = TODAY
AND (Dont_Auto_Assign_Cases__c = false OR Dont_Auto_Assign_Cases__c = null)
AND IsActive = true
```

**Resolution**:
- If no eligible users: Have at least one CS user log in
- If trigger inactive: Reactivate trigger
- If exception: Check debug log, fix issue, re-deploy

---

#### Issue: Same-Day Reassignment Not Working

**Symptoms**: Reopened cases use workload distribution instead of returning to previous owner

**Possible Causes**:
1. Previous_Auto_Assigned_Owner__c not populated
2. Previous owner logged out
3. Previous owner over threshold
4. Case reopened on different day

**Diagnosis Steps**:
1. Query case:
```sql
SELECT Id, OwnerId, Previous_Auto_Assigned_Owner__c,
       rlsServiceCaseAutoAssign_Date_Time__c
FROM Case
WHERE Id = '[CASE_ID]'
```
2. Check debug logs for checkSameDayPreviousOwner() messages
3. Verify flow "Store_Previous_Owner" step executed

**Resolution**:
- If field not populated: Verify flow is active and "Store_Previous_Owner" step exists
- If previous owner issues: Working as designed (fallback to workload distribution)
- If different day: Working as designed

---

#### Issue: All Users Over Threshold

**Symptoms**: Debug logs show "all users at or over threshold" repeatedly

**Possible Causes**:
1. Threshold too low for current volume
2. Team capacity reduced (users logged out/opted out)
3. Volume spike

**Diagnosis Steps**:
1. Run Query 2 (Current Workload)
2. Check average workload vs threshold
3. Check number of active/eligible users

**Resolution**:
- If threshold too low: Increase threshold in custom setting (e.g., 25 or 30)
- If capacity reduced: Ensure all CS users are logged in and available
- If volume spike: Temporary - monitor and consider threshold adjustment

---

#### Issue: Uneven Distribution

**Symptoms**: One user has significantly more cases than others (>10 case difference)

**Possible Causes**:
1. User logged in later than others (missed early assignments)
2. Key account manager receiving key account cases + workload cases
3. User manually assigned cases outside auto-assignment

**Diagnosis Steps**:
1. Run Query 1 (Assignment Distribution)
2. Check if user is key account manager (has accounts with CS_Contact__c)
3. Check for manual assignments:
```sql
SELECT Id, OwnerId, Owner.Name, CreatedDate,
       rlsServiceCaseAutoAssign_Date_Time__c
FROM Case
WHERE CreatedDate = TODAY
AND RecordType.Name = 'Email'
AND rlsServiceCaseAutoAssign_Date_Time__c = null
```

**Resolution**:
- If logged in late: Normal - will balance throughout day
- If key account manager: Working as designed - consider excluding from workload distribution
- If manual assignments: Train users to assign to queue instead

---

### G. Performance Considerations

#### Governor Limits

**SOQL Queries**:
- assignCasesToUsers(): ~6 queries per invocation
- Batch size: Recommend max 50 cases per batch (well within limits)

**DML Operations**:
- Single update for all cases (1 DML regardless of case count)
- Supports up to 10,000 cases in theory (Salesforce DML limit)

**CPU Time**:
- Complexity: O(n*m) where n=cases, m=users
- Typical: <100ms for 20 cases, 8 users
- Max observed: ~500ms for 100 cases, 20 users

**Heap Size**:
- Workload map: ~500 bytes per user
- Case list: ~2KB per case
- Total: <1MB for typical volumes

**Conclusion**: Current implementation is performant and scales well for expected volumes (<200 cases, <30 users)

---

#### Optimization Opportunities (Future)

If volumes increase significantly (>500 cases/day, >50 users):

1. **Cache Queue ID**: Query once, cache in static variable
2. **Batch Processing**: Process cases in smaller batches via Queueable
3. **Async Assignment**: Move entire assignment logic to @future (already available via Handler)
4. **Platform Events**: Decouple trigger from assignment via events

**Current Recommendation**: No optimization needed at current volumes

---

### H. Business Rules Summary

This section provides a quick reference for business stakeholders.

#### Rule 1: Eligibility for Auto-Assignment

**User must meet ALL criteria**:
- Profile name contains "Customer Service"
- Logged in today (LastLoginDate = TODAY)
- Active user (IsActive = true)
- Not opted out (Dont_Auto_Assign_Cases__c = false or null)
- Open Email case count < 20 (threshold)

**If no eligible users**: Case remains in queue until user becomes available

---

#### Rule 2: Key Account Priority

**Definition**: Account has designated CS Contact (Account.CS_Contact__c populated)

**Behavior**:
- Key account cases assigned directly to account's CS Contact
- Bypasses workload distribution
- Still subject to threshold (if CS Contact over 20 cases, falls back to workload)

**Rationale**: Strategic accounts receive consistent service from dedicated contact

---

#### Rule 3: Workload Distribution

**For non-key-account cases**:
1. Assign to user with lowest open Email case count
2. If tie (multiple users with same count):
   - Prefer users who have never been assigned (new users)
   - Otherwise, exclude user who was most recently assigned
   - Assign to one of the remaining users

**Threshold Behavior**:
- Users under 20 cases: Eligible for assignment
- Users at/over 20 cases: Excluded from assignment
- If ALL users over 20: Assign to user with lowest count anyway (soft limit)

**Rationale**: Evenly distribute workload while preventing overload

---

#### Rule 4: Same-Day Reopen Reassignment

**Trigger**: Case reopens (customer replies after >14 hours quiet)

**Definition of "Same Day"**: Same calendar day as last assignment
- Example: Assigned Oct 8 at 11:00 PM, reopens Oct 8 at 11:55 PM = same day
- Example: Assigned Oct 8 at 11:00 PM, reopens Oct 9 at 12:05 AM = different day

**Behavior**:
- **Same day + previous owner eligible + under threshold**: Reassign to previous owner
- **Different day OR previous owner ineligible OR over threshold**: Use workload distribution

**Rationale**: Maintain conversation continuity when agent still available

---

#### Rule 5: Threshold = Soft Limit

**Threshold**: 20 open Email cases per user

**"Soft Limit" means**:
- Preferentially assign to users under threshold
- If all users over threshold, still assign to lowest
- Never leave cases unassigned

**Why Soft Limit?**:
- Ensures customers always get responses
- Admin can monitor for capacity issues
- Prevents queue backlog

**Adjustable**: Admin can change threshold via Custom Setting (no code change required)

---

### I. Frequently Asked Questions

**Q1: Can we have different thresholds for different users?**

A: Yes, the Custom Setting is hierarchical. You can set:
- Organization default (applies to all)
- Profile-level override (e.g., CS Manager = 30, CS Junior = 15)
- User-level override (e.g., Specific user = 25)

---

**Q2: What if a user goes on vacation?**

A: Options:
1. User sets Dont_Auto_Assign_Cases__c = true (opts out)
2. Admin deactivates user (automatically excluded)
3. User doesn't log in (excluded due to LastLoginDate check)

Existing cases remain assigned; new cases go to others.

---

**Q3: Can we manually override the auto-assignment?**

A: Yes, always:
1. Change Case.OwnerId to desired user (manual reassignment)
2. System respects manual changes
3. If case reopens later, same-day rule applies to manual owner too

---

**Q4: How do we know if the system is working correctly?**

A: Check these indicators:
- Cases assigned within seconds of arriving in queue
- Workload relatively balanced across users (±3 cases)
- No cases stuck in queue for >5 minutes
- Debug logs show expected messages

Run monitoring queries from Appendix E.

---

**Q5: What happens to cases created outside business hours?**

A: Depends on LastLoginDate:
- If no users logged in today: Cases remain in queue until someone logs in
- If users logged in earlier today: Cases assigned to those users
- Next morning: As users log in, they become eligible and receive balanced distribution

---

**Q6: Can we exclude specific cases from auto-assignment?**

A: Yes, options:
1. Don't assign to "Customer Service Email" queue (use different queue)
2. Set Case.AccountId = null (violates trigger condition)
3. Use different Record Type (trigger checks for "Email")

Cases that don't meet trigger conditions are not processed.

---

**Q7: How long is the assignment history stored?**

A: Indefinitely. Fields used:
- rlsServiceCaseAutoAssign_Date_Time__c: Persists forever (unless case deleted)
- Previous_Auto_Assigned_Owner__c: Persists until case closed or reassigned

For reporting, you can track assignments over any time period.

---

**Q8: What if we want to change the threshold?**

A: Easy change, no deployment needed:
1. Setup > Custom Settings > Case Auto Assignment Settings
2. Click "Manage"
3. Edit organization default
4. Change Max_Open_Cases_Per_User__c
5. Save

New assignments use new threshold immediately.

---

### J. Contact Information

**Project Owner**: [Your Name]
**Technical Lead**: [Your Name]
**Salesforce Org**: OldOrg (Recycling Lives Service)
**Implementation Date**: October 2025

**For Issues**:
- Email: [support email]
- Slack: [#salesforce-support channel]

**For Changes**:
- Submit change request via [process]
- Include business justification
- Technical review required for code changes

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Oct 8, 2025 | [Your Name] | Initial master document created by consolidating analysis and implementation docs |

---

## Conclusion

This master document provides complete implementation guidance for the Email-to-Case Assignment Enhancement project. It consolidates all analysis, technical specifications, user decisions, code changes, testing procedures, deployment steps, and operational guidance into a single source of truth.

**Implementation Status**: Ready to begin

**Next Steps**:
1. Review this document with stakeholders
2. Obtain approval to proceed
3. Begin Phase 1 (Custom Setting and Field creation)
4. Progress through phases sequentially
5. Complete post-deployment monitoring

**Success Criteria**: After 2 weeks of monitoring, if all success criteria are met (see Post-Deployment Monitoring section), the project will be considered successfully completed.

---

**END OF DOCUMENT**
