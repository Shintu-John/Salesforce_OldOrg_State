# Case Reopening Incident Analysis - October 16, 2025

**Created**: October 23, 2025
**Scenario Type**: 📊 **Analysis** (Incident Troubleshooting & Resolution)
**Organization**: OldOrg (Recycling Lives Service)
**Status**: ✅ Resolved (October 16, 2025)

---

## Executive Summary

**What This Documents**: Critical incident where cases failed to automatically reopen when customers replied, caused by missing record types on manually-created cases.

**Incident Details**:
- **Date**: October 16, 2025
- **Issue**: Customer (Wates Construction) replied 5 times to closed case over 7 days with no response
- **Root Cause**: 584 cases created without record types due to profile misconfiguration
- **Impact**: 4 October cases failed to reopen; 143 closed cases unintentionally reopened during fix
- **Resolution**: Fixed profile configuration, assigned record types, closed incorrectly reopened cases

**Critical Customer Impact**:
- **Case 00474147** (Wates Construction): 5 ignored customer emails over 7 days
- Customer escalation to senior management
- Reputation risk with major client (Wates)

---

## Incident Timeline

### Initial Problem (October 9-16, 2025)

**Customer**: Duggie Zachariades (Wates Construction)
**Case Number**: 00474147

**Email Timeline (All Ignored)**:
- **Oct 9, 08:28** - Customer: "Any news on the 25-yard skip quote as we need it ASAP"
- **Oct 14, 13:23** - Dale Newcombe: "Please could you give me a confirmed date for delivery"
- **Oct 16, 07:31** - Dale: "Is there any danger that someone could respond to the below?"
- **Oct 16, 07:33** - Duggie Zachariades escalates to management

**Why Case Didn't Reopen**: Case had `RecordTypeId = null`, didn't match automatic reopening flow criteria

---

## Root Cause Analysis

### The Automatic Reopening System

**Flow**: `EmailMessage_Open_Closed_Case_on_Email` (Active)

**Trigger Conditions**:
1. ✅ Incoming email received (Incoming = true)
2. ✅ Email attached to Case (ParentId starts with "500")
3. ✅ Case status = "Closed" OR "Case Closed"
4. ❌ **Case has Record Type** = Email/Paperwork_Compliance/RLES_Invoicing/RLES_Purchase_Ledger

**Action**: Sets `Status = "Reopen"`

### The Problem

**Case 00474147 had NO Record Type** (RecordTypeId = null)

**Why Cases Had No Record Types**:
- Cases manually created by customer service staff via phone
- "2.0 Customer Service" profile had **NO record type access** configured
- Record Type field appeared greyed out/locked when creating cases
- Staff couldn't assign record types → Cases created with `RecordTypeId = null`
- Flow condition #4 failed → **cases didn't reopen when customers replied**

### Scale of the Problem

**Total Cases Without Record Types (2025)**: 584 cases
- 574 cases (98%) were `Origin="Phone"` (manually created)
- Pattern existed since January 2025 (not a new issue)
- Profile misconfiguration undetected for 10 months

**October Cases That Failed to Reopen**:

| Case Number | Customer | Issue | Priority |
|-------------|----------|-------|----------|
| 00474147 | Duggie Zachariades (Wates) | 5 ignored emails over 7 days | 🔴🔴🔴 Critical |
| 00478696 | Brian Davies (Wates) | Wasted Journey complaint | 🔴 High |
| 00468373 | Paul Moseley (Justice.gov.uk) | Replied 5 min after closure | ⚠️ High |
| 00470021 | Angela Maclean (BAM) | Auto-reply only | 🟢 Low |

---

## Resolution Steps

### Step 1: Bulk Record Type Assignment (09:42 AM)

**Action**: Assigned "Email" record type to all 584 cases without record types

**Command**:
```apex
Id emailRecordTypeId = [SELECT Id FROM RecordType
                        WHERE SobjectType = 'Case'
                        AND DeveloperName = 'Email' LIMIT 1].Id;

List<Case> casesToFix = [SELECT Id FROM Case WHERE RecordTypeId = null];
for(Case c : casesToFix) {
    c.RecordTypeId = emailRecordTypeId;
}
update casesToFix;
```

**Result**: ✅ 584 cases updated with Email record type

### Step 2: Unintended Consequence - Mass Reopening

**Flow Triggered**: `Flow_to_manage_email_inbox_record_type_changes`

**What Happened**:
- Flow triggers when RecordTypeId changes to Email/RLES Invoicing/RLES Purchase Ledger
- Flow automatically sets `Status = "Case Raised"`
- **143 previously closed cases** changed from "Case Closed" → "Case Raised"
- Customer service team reported cases flooding back into queue

**Flow Logic** (lines 44-47 of flow metadata):
```xml
<inputAssignments>
    <field>Status</field>
    <value>
        <stringValue>Case Raised</stringValue>
    </value>
</inputAssignments>
```

**Trigger Condition** (lines 57-85):
```xml
<filterLogic>1 AND (2 or 3 or 4)</filterLogic>
<filters>
    <field>RecordTypeId</field>
    <operator>IsChanged</operator>
</filters>
```

**Root Issue**: Flow didn't check if cases were already closed before changing status

### Step 3: Close Incorrectly Reopened Cases (11:01-11:02 AM)

**Identified**: 143 cases that changed from "Case Closed" → "Case Raised/Reopen" during bulk update

**Closure Strategy**:
- Close all 143 cases EXCEPT case 00478696 (customer requested to keep open)
- Use `Database.update` with `allOrNone=false` to handle validation errors

**Command**:
```apex
List<CaseHistory> statusChanges = [
    SELECT CaseId, OldValue, NewValue
    FROM CaseHistory
    WHERE CreatedDate >= 2025-10-16T09:40:00Z
      AND CreatedDate <= 2025-10-16T09:45:00Z
      AND Field = 'Status'
];

Set<Id> casesClosedToOpen = new Set<Id>();
for (CaseHistory ch : statusChanges) {
    if ((String.valueOf(ch.OldValue) == 'Case Closed') &&
        (String.valueOf(ch.NewValue) == 'Case Raised')) {
        casesClosedToOpen.add(ch.CaseId);
    }
}

List<Case> casesToClose = [
    SELECT Id FROM Case
    WHERE Id IN :casesClosedToOpen
      AND CaseNumber != '00478696'
];

for (Case c : casesToClose) {
    c.Status = 'Case Closed';
}

Database.SaveResult[] results = Database.update(casesToClose, false);
```

**Results**:
- ✅ Successfully closed: 123 cases
- ⚠️ Failed to close: 19 cases (validation error: missing Contact records)
- ✅ Case 00478696 remains open for customer follow-up

**Validation Error** (for 19 cases):
```
"You have not created a contact for this person. You must do this before you can close the case."
```

### Step 4: Profile Configuration (Permanent Fix)

**Action**: Configured "2.0 Customer Service" profile with Email record type access

**File Modified**: `force-app/main/default/profiles/2%2E0 Customer Service.profile-meta.xml`

**Change Added**:
```xml
<recordTypeVisibilities>
    <default>true</default>
    <recordType>Case.Email</recordType>
    <visible>true</visible>
</recordTypeVisibilities>
```

**Deployment**:
```bash
sf project deploy start -o OldOrg \
  -d "force-app/main/default/profiles/2%2E0 Customer Service.profile-meta.xml"
```

**Result**: ✅ Successfully deployed (42.06s)

**Impact**:
- Record Type field no longer greyed out for customer service staff
- Email automatically pre-selected when creating cases
- Staff can still change to other record types if needed
- **Prevents future occurrences of this issue**

---

## Final Status

### Cases Fixed

| Metric | Count | Status |
|--------|-------|--------|
| Total cases assigned Email record type | 584 | ✅ Complete |
| Cases unintentionally reopened | 143 | ⚠️ Side effect |
| Cases successfully closed back | 123 | ✅ Fixed |
| Cases remaining open (validation errors) | 19 | ⚠️ Manual action needed |
| Case 00478696 (intentionally kept open) | 1 | ✅ Open for follow-up |

### Verification

**Confirmed**: Only closed cases that were unintentionally reopened during bulk update

**Math Check**:
- 143 cases reopened = 1 (kept open) + 123 (closed) + 19 (validation errors) ✅

**No legitimate cases were affected** - all closures were from the 143 that were incorrectly reopened

---

## Outstanding Actions

### 19 Cases With Validation Errors

These cases remain open and need **manual intervention** by customer service:

**Required Actions**:
1. Open each case
2. Create or link a Contact record
3. Close the case manually

**Why They Failed**:
- Cases created without associating a Contact record
- Validation rule requires Contact before closure
- `Database.update` with `allOrNone=false` skipped these cases

---

## Related Flows and Automation

### Flow: EmailMessage_Open_Closed_Case_on_Email
- **Purpose**: Automatically reopen closed cases when customers reply
- **Trigger**: Incoming EmailMessage (RecordAfterSave on Create)
- **Criteria**: Case Status = Closed/Case Closed AND RecordType = Email/Paperwork_Compliance/RLES_Invoicing/RLES_Purchase_Ledger
- **Action**: Set `Status = "Reopen"`
- **Status**: ✅ Working correctly (after record types assigned)

### Flow: Flow_to_manage_email_inbox_record_type_changes
- **Purpose**: Standardize status for email-related cases
- **Trigger**: RecordTypeId changed to Email/RLES Invoicing/RLES Purchase Ledger
- **Action**: Set `Status = "Case Raised"`
- **Issue**: ⚠️ Changes status even for closed cases (caused mass reopening)
- **Recommendation**: Add condition to check `IsClosed` field before changing status

### Flow: Case_Remove_Case_Owner_if_Reopen_24_Hours
- **Purpose**: Reassign cases after 14+ hours of inactivity
- **Trigger**: Most_Recent_Message__c changed AND >14 hours since previous email AND RecordType = "Email"
- **Action**: Return to queue and auto-assign
- **Status**: ✅ Working correctly

### Flow: Flow_to_monitor_cases_if_reopened
- **Purpose**: Clear closure tracking fields when case reopens
- **Trigger**: Status changed to "Reopen"
- **Action**: Clear `Date_Time_Case_Closed__c` and `Who_Closed_Case__c`
- **Status**: ✅ Working correctly

**Related Scenario**: See [email-to-case-assignment](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/email-to-case-assignment) for complete email-to-case automation system documentation.

---

## Prevention Measures

### 1. Profile Configuration ✅ Complete

**Change**: Email record type is now default for "2.0 Customer Service" profile

**Impact**:
- Record Type field no longer greyed out
- Email automatically pre-selected when creating cases
- Staff can still change to other record types if needed

### 2. Email-to-Case Automation ✅ Already Working

**Status**: All automated email cases already get record types

**Flow**: Email routing rules automatically assign appropriate record type

### 3. Case Reopening Flow ✅ Now Working

**Status**: Flow criteria now match Email record type (after bulk assignment)

**Flow**: `EmailMessage_Open_Closed_Case_on_Email`

### 4. Record Type Assignment Flow ⚠️ Needs Enhancement

**Issue**: `Flow_to_manage_email_inbox_record_type_changes` automatically sets `Status="Case Raised"` when record type is assigned

**Recommendation**: Modify flow to NOT change status for cases that are already closed

**Suggested Enhancement**: Add condition to check `IsClosed` field before changing status

---

## Lessons Learned

### What Went Wrong

1. **Profile Misconfiguration (Primary)**
   - Customer Service profile had no Case record type access
   - Issue existed since at least January 2025 (584 cases affected over 10 months)
   - Staff couldn't select record types when creating cases manually

2. **Unintended Flow Interaction (Secondary)**
   - Bulk record type assignment triggered status change flow
   - Flow didn't check if cases were already closed
   - 143 closed cases were unintentionally reopened

3. **Validation Rule Limitation**
   - 19 cases couldn't be closed due to missing Contact records
   - Required manual intervention to resolve

### What Went Right

1. **Quick Detection**
   - Customer escalation identified immediately
   - Root cause found within hours of escalation

2. **Targeted Remediation**
   - Only affected cases were modified
   - Verification confirmed no legitimate cases were incorrectly closed

3. **Permanent Fix**
   - Profile configuration prevents future occurrences
   - All 584 historical cases now have record types
   - System now works correctly for future manually-created cases

---

## Recommendations

### Immediate (✅ Done)
- ✅ Fix profile configuration
- ✅ Assign record types to all 584 cases
- ✅ Close 123 incorrectly reopened cases

### Short-term (Next Week)
1. **Customer Service Action**: Manually fix 19 cases with validation errors (create Contacts, then close)
2. **Customer Communication**: Follow up with Wates Construction on cases 00474147 and 00478696
3. **Team Training**: Inform staff that Email is now the default record type for manual case creation

### Long-term (Next Month)
1. **Flow Enhancement**: Modify `Flow_to_manage_email_inbox_record_type_changes` to check `IsClosed` before changing status
2. **Validation Rule Review**: Consider if Contact requirement should block closure (or allow closure with warning)
3. **Monitoring**: Create dashboard to alert if cases created without record types
4. **Documentation**: Update internal procedures for manual case creation

---

## Technical Details

### Record Type IDs (OldOrg)

- **Email**: `012Sj0000004DZlIAM`
- **RLES Invoicing**: `012Sj0000006IK1IAM`
- **RLES Purchase Ledger**: `012Sj0000006ILdIAM`
- **Paperwork_Compliance**: (Active in flows)

### Profile

- **Name**: 2.0 Customer Service
- **File**: `force-app/main/default/profiles/2%2E0 Customer Service.profile-meta.xml`

### Users Affected (Top 6 by case count)

- **Joanne Parry**: Created 175 cases without record type in 2025
- **Aaliyah Ormerod**: Created 175 cases
- **Darren Garrido**: Created 98 cases
- **Danielle Moss**: Created 71 cases
- **Dennis Dadey**: Created 63 cases
- **Supriya Chaterjee**: Created 4 cases (including critical case 00474147)

---

## Related Documentation

### Source Documentation

- [source-docs/CASE_REOPENING_INCIDENT_2025-10-16.md](source-docs/CASE_REOPENING_INCIDENT_2025-10-16.md) - Complete incident documentation with full details

### NewOrg Configuration

**⚠️ IMPORTANT**: NewOrg must implement the same prevention measures:

See: [NewOrg case-reopening-incident Guide](https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/case-reopening-incident)

### Related Scenarios

- [email-to-case-assignment](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/email-to-case-assignment) - Complete email-to-case automation system (includes reopening flows)

---

## Referenced Components

### Flows (Existing in OldOrg - No Changes Needed)

All flows are already deployed and working correctly (after record type assignment):

- `EmailMessage_Open_Closed_Case_on_Email` - Automatic case reopening
- `Flow_to_manage_email_inbox_record_type_changes` - Status standardization (⚠️ enhancement recommended)
- `Case_Remove_Case_Owner_if_Reopen_24_Hours` - Case reassignment after 14 hours
- `Flow_to_monitor_cases_if_reopened` - Clear closure fields on reopen

**Note**: No code deployment needed - all flows existed and work correctly. Issue was profile configuration only.

### Profile (Modified)

- `force-app/main/default/profiles/2%2E0 Customer Service.profile-meta.xml`
  - Added Email record type visibility
  - Set as default record type
  - Deployed October 16, 2025

---

## Key Learnings for NewOrg

### 1. Profile Configuration is Critical

Ensure **ALL** NewOrg profiles that create cases manually have proper record type access configured BEFORE go-live.

### 2. Test Manual Case Creation

Test manual case creation from UI with all user profiles to ensure record types are assignable.

### 3. Test Case Reopening Flows

Test that closed cases reopen automatically when customers reply (with all record types).

### 4. Flow Enhancement

Consider enhancing `Flow_to_manage_email_inbox_record_type_changes` to check `IsClosed` before changing status (prevents mass reopening if bulk assignment needed).

### 5. Monitor for NULL Record Types

Create dashboard or report to alert if cases created without record types (early detection).

---

**Resolution Status**: ✅ **RESOLVED** (October 16, 2025)
**Resolved By**: John Shintu (Administrator)
**Business Impact**: Prevented future customer escalations, fixed profile configuration, 584 historical cases corrected
**Prevention**: Profile configuration ensures all new manual cases get record types

---

**Last Updated**: October 23, 2025
**Documentation Type**: Incident Analysis (Profile Configuration Fix)
**Scenario Classification**: Analysis / Troubleshooting (NOT code deployment)
