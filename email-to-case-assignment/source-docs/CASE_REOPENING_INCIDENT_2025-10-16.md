# Case Reopening Incident - October 16, 2025

## Executive Summary

**Date:** October 16, 2025
**Issue:** Customer reported that case was not automatically reopened when they replied to a closed case
**Root Cause:** Cases without Record Types were not matching the automatic reopening flow criteria
**Impact:** 4 cases in October failed to reopen when customers replied; 143 closed cases were unintentionally reopened during remediation
**Resolution:** Fixed profile configuration, assigned record types to all cases, closed incorrectly reopened cases
**Status:** ✅ Resolved

---

## Initial Problem Report

### Customer Complaint
Customer (Wates Construction) reported that they replied to closed case **00474147** multiple times but the case was not reopened.

**Timeline of Ignored Emails:**
- Oct 9, 08:28 - Customer: "Any news on the 25-yard skip quote as we need it ASAP"
- Oct 14, 13:23 - Dale Newcombe: "Please could you give me a confirmed date for delivery"
- Oct 16, 07:31 - Dale: "Is there any danger that someone could respond to the below?"
- Oct 16, 07:33 - Duggie Zachariades escalated

---

## Root Cause Analysis

### The Automatic Reopening Flow

**Flow:** `EmailMessage_Open_Closed_Case_on_Email` (Status: Active)

**Trigger Conditions:**
1. Incoming email received (Incoming = true)
2. Email is attached to a Case (ParentId starts with "500")
3. Case status is "Closed" OR "Case Closed"
4. **AND** Case has one of these Record Types:
   - Email
   - Paperwork_Compliance
   - RLES_Invoicing
   - RLES_Purchase_Ledger

**Action:** Sets Status = "Reopen"

### The Problem

**Case 00474147 had NO Record Type assigned** (RecordTypeId = null)

**Why?**
- Case was manually created by customer service staff via phone call
- The "2.0 Customer Service" profile had NO record type access configured
- Record Type field appeared greyed out/locked when creating cases
- Cases were created with RecordTypeId = null
- Flow condition #4 failed → case didn't reopen

---

## Scale of the Problem

### Cases Without Record Types

**Total in 2025:** 584 cases
- 574 cases (98%) were Origin="Phone" (manually created)
- Created throughout the year (not a new issue)
- Consistent pattern since January 2025

**October Cases That Failed to Reopen:**

| Case Number | Customer | Issue | Priority |
|-------------|----------|-------|----------|
| 00474147 | Duggie Zachariades (Wates) | 5 ignored emails over 7 days | 🔴🔴🔴 Critical |
| 00478696 | Brian Davies (Wates) | Wasted Journey complaint | 🔴 High |
| 00468373 | Paul Moseley (Justice.gov.uk) | Replied 5 min after closure | ⚠️ High |
| 00470021 | Angela Maclean (BAM) | Auto-reply only | 🟢 Low |

---

## Remediation Actions

### Step 1: Bulk Record Type Assignment (09:42 AM)

**Action:** Assigned "Email" record type to all 584 cases without record types

**Command:**
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

**Result:** 584 cases updated with Email record type

### Step 2: Unintended Consequence - Mass Reopening

**Flow Triggered:** `Flow_to_manage_email_inbox_record_type_changes`

**What Happened:**
- Flow triggers when RecordTypeId changes to Email/RLES Invoicing/RLES Purchase Ledger
- Flow automatically sets Status = "Case Raised"
- **143 previously closed cases** changed from "Case Closed" → "Case Raised"
- Customer service team reported cases flooding back into queue

**Flow Logic (lines 44-47):**
```xml
<inputAssignments>
    <field>Status</field>
    <value>
        <stringValue>Case Raised</stringValue>
    </value>
</inputAssignments>
```

**Trigger Condition (lines 57-85):**
```xml
<filterLogic>1 AND (2 or 3 or 4)</filterLogic>
<filters>
    <field>RecordTypeId</field>
    <operator>IsChanged</operator>
</filters>
```

### Step 3: Reopened Case 00478696 (Intentional)

**Action:** Manually reopened the one case customer requested

**Command:**
```bash
sf data update record --sobject Case --record-id 500Sj00000Of2GBIAZ \
  --values "RecordTypeId='012Sj0000004DZlIAM' Status='Reopen'" \
  --target-org OldOrg
```

**Result:** Case 00478696 reopened for customer service follow-up

### Step 4: Closed Incorrectly Reopened Cases (11:01-11:02 AM)

**Identified 143 cases** that changed from "Case Closed" → "Case Raised/Reopen" during bulk update

**Closure Strategy:**
- Close all 143 cases EXCEPT case 00478696
- Use Database.update with allOrNone=false to handle validation errors

**Command:**
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

**Results:**
- ✅ Successfully closed: 123 cases
- ⚠️ Failed to close: 19 cases (validation error: missing Contact records)
- ✅ Case 00478696 remains open

**Validation Error:**
```
"You have not created a contact for this person. You must do this before you can close the case."
```

### Step 5: Profile Configuration (Permanent Fix)

**Action:** Configured "2.0 Customer Service" profile with Email record type access

**File Modified:** `force-app/main/default/profiles/2%2E0 Customer Service.profile-meta.xml`

**Change:**
```xml
<recordTypeVisibilities>
    <default>true</default>
    <recordType>Case.Email</recordType>
    <visible>true</visible>
</recordTypeVisibilities>
```

**Deployment:**
```bash
sf project deploy start -o OldOrg \
  -d "force-app/main/default/profiles/2%2E0 Customer Service.profile-meta.xml"
```

**Result:** ✅ Successfully deployed (42.06s)

---

## Final Status

### Cases Fixed

| Metric | Count | Status |
|--------|-------|--------|
| Total cases assigned Email record type | 584 | ✅ Complete |
| Cases unintentionally reopened | 143 | ⚠️ Side effect |
| Cases successfully closed back | 123 | ✅ Fixed |
| Cases remaining open (validation errors) | 19 | ⚠️ Need manual action |
| Case 00478696 (intentionally open) | 1 | ✅ Open for follow-up |

### Verification

**Confirmed:** We ONLY closed cases that were unintentionally reopened during bulk update

**Math Check:**
- 143 cases reopened = 1 (kept open) + 123 (closed) + 19 (validation errors) ✅

**No legitimate cases were affected** - all closures were from the 143 that were incorrectly reopened

---

## Outstanding Actions

### 19 Cases With Validation Errors

These cases remain open and need **manual intervention** by customer service:

**Required Actions:**
1. Open each case
2. Create or link a Contact record
3. Close the case manually

**Why They Failed:**
- Cases were created without associating a Contact record
- Validation rule requires Contact before closure
- Database.update with allOrNone=false skipped these cases

---

## Prevention Measures

### 1. Profile Configuration ✅

**Change:** Email record type is now default for "2.0 Customer Service" profile

**Impact:**
- Record Type field no longer greyed out
- Email automatically pre-selected when creating cases
- Staff can still change to other record types if needed

### 2. Email-to-Case Automation ✅

**Status:** Working correctly - all automated email cases already get record types

**Flow:** Email routing rules automatically assign appropriate record type

### 3. Case Reopening Flow ✅

**Status:** Working correctly - flow criteria match Email record type

**Flow:** `EmailMessage_Open_Closed_Case_on_Email`

### 4. Record Type Assignment Flow ⚠️

**Issue:** `Flow_to_manage_email_inbox_record_type_changes` automatically sets Status="Case Raised" when record type is assigned

**Recommendation:** Consider modifying flow to NOT change status for cases that are already closed

**Alternative:** Add condition to check if case was already closed before changing status

---

## Related Flows and Automation

### Flow: EmailMessage_Open_Closed_Case_on_Email
- **Purpose:** Automatically reopen closed cases when customers reply
- **Trigger:** Incoming EmailMessage (RecordAfterSave on Create)
- **Criteria:** Case Status = Closed/Case Closed AND RecordType = Email/Paperwork_Compliance/RLES_Invoicing/RLES_Purchase_Ledger
- **Action:** Set Status = "Reopen"
- **Status:** ✅ Working correctly

### Flow: Flow_to_manage_email_inbox_record_type_changes
- **Purpose:** Standardize status for email-related cases
- **Trigger:** RecordTypeId changed to Email/RLES Invoicing/RLES Purchase Ledger
- **Action:** Set Status = "Case Raised"
- **Issue:** Changes status even for closed cases
- **Recommendation:** Add condition to check IsClosed field

### Flow: Case_Remove_Case_Owner_if_Reopen_24_Hours
- **Purpose:** Reassign cases after 14+ hours of inactivity
- **Trigger:** Most_Recent_Message__c changed AND >14 hours since previous email AND RecordType = "Email"
- **Action:** Return to queue and auto-assign
- **Status:** ✅ Working correctly

### Flow: Flow_to_monitor_cases_if_reopened
- **Purpose:** Clear closure tracking fields when case reopens
- **Trigger:** Status changed to "Reopen"
- **Action:** Clear Date_Time_Case_Closed__c and Who_Closed_Case__c
- **Status:** ✅ Working correctly

---

## Lessons Learned

### What Went Wrong

1. **Profile Misconfiguration**
   - Customer Service profile had no Case record type access
   - Issue existed since at least January 2025 (584 cases affected)
   - Staff couldn't select record types when creating cases

2. **Unintended Flow Interaction**
   - Bulk record type assignment triggered status change flow
   - Flow didn't check if cases were already closed
   - 143 closed cases were unintentionally reopened

3. **Validation Rule Limitation**
   - 19 cases couldn't be closed due to missing Contact records
   - Need manual intervention to resolve

### What Went Right

1. **Quick Detection**
   - Customer escalation was identified immediately
   - Root cause found within hours

2. **Targeted Remediation**
   - Only affected cases were modified
   - Verification confirmed no legitimate cases were closed

3. **Permanent Fix**
   - Profile configuration prevents future occurrences
   - All 584 historical cases now have record types

---

## Recommendations

### Immediate (Done)
- ✅ Fix profile configuration
- ✅ Assign record types to all cases
- ✅ Close incorrectly reopened cases

### Short-term (Next Week)
1. **Customer Service Action:** Manually fix 19 cases with validation errors
2. **Customer Communication:** Follow up with Wates Construction on cases 00474147 and 00478696
3. **Team Training:** Inform staff that Email is now the default record type

### Long-term (Next Month)
1. **Flow Enhancement:** Modify `Flow_to_manage_email_inbox_record_type_changes` to check IsClosed before changing status
2. **Validation Rule Review:** Consider if Contact requirement should block closure
3. **Monitoring:** Create dashboard to alert if cases created without record types
4. **Documentation:** Update internal procedures for manual case creation

---

## Technical Details

### Record Type IDs
- Email: `012Sj0000004DZlIAM`
- RLES Invoicing: `012Sj0000006IK1IAM`
- RLES Purchase Ledger: `012Sj0000006ILdIAM`

### Profile
- Name: 2.0 Customer Service
- File: `force-app/main/default/profiles/2%2E0 Customer Service.profile-meta.xml`

### Users Affected
- Joanne Parry (created 175 cases without record type in 2025)
- Aaliyah Ormerod (created 175 cases)
- Darren Garrido (created 98 cases)
- Danielle Moss (created 71 cases)
- Dennis Dadey (created 63 cases)
- Supriya Chaterjee (created 4 cases, including case 00474147)

---

## Appendix: Commands Used

### Check cases without record type
```bash
sf data query --query "SELECT COUNT(Id) Total FROM Case WHERE RecordTypeId = null" --target-org OldOrg
```

### Assign Email record type to all cases
```apex
Id emailRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = 'Email' LIMIT 1].Id;
List<Case> casesToFix = [SELECT Id FROM Case WHERE RecordTypeId = null];
for(Case c : casesToFix) { c.RecordTypeId = emailRecordTypeId; }
update casesToFix;
```

### Find cases that changed from Closed to Open
```apex
List<CaseHistory> statusChanges = [
    SELECT CaseId, OldValue, NewValue
    FROM CaseHistory
    WHERE CreatedDate >= 2025-10-16T09:40:00Z
      AND CreatedDate <= 2025-10-16T09:45:00Z
      AND Field = 'Status'
];
```

### Verify current state
```bash
sf data query --query "SELECT Status, IsClosed, COUNT(Id) Total FROM Case WHERE LastModifiedDate >= 2025-10-16T09:40:00Z AND LastModifiedDate <= 2025-10-16T09:45:00Z GROUP BY Status, IsClosed" --target-org OldOrg
```

---

## Contact

**Incident Lead:** John Shintu
**Date:** October 16, 2025
**Documentation:** /home/john/Projects/Salesforce/Documentation/CASE_REOPENING_INCIDENT_2025-10-16.md
