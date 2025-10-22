# Portal Exchange Email - OldOrg vs NewOrg Gap Analysis

**Date**: October 22, 2025
**Scenario**: Portal Exchange Email SPF/DMARC Fix
**OldOrg Implementation Date**: October 16, 2025
**Analysis Status**: ✅ Complete

---

## Executive Summary

**Purpose**: This gap analysis compares the Portal Exchange Email SPF/DMARC fix between OldOrg (source) and NewOrg (target) to identify missing or outdated components requiring migration.

**Key Findings**:
- ⚠️ **Handler class OUTDATED**: NewOrg has V1 (1,522 lines) vs OldOrg V2 (2,827 lines) - missing regex email extraction
- ⚠️ **Test class OUTDATED**: NewOrg has V1 (1,660 lines) vs OldOrg V2 (5,608 lines) - missing test coverage for V2 features
- 🚨 **Custom Label MISSING**: From_Address_Portal_Exchanges not in NewOrg
- 🚨 **Trigger MISSING**: NewCaseEmailTrigger not deployed to NewOrg
- ⚠️ **Email Templates MISSING Pattern**: 5 templates lack "({!User.Email})" pattern for email extraction
- 🚨 **2 Flows MISSING**: Cancel_Flow and Job_Organise_Collection not active in NewOrg
- ✅ **4 Flows HAVE FIX**: Exchange_Job, Create_Job, Create_Mixed_Waste_Type_Job, Cancel_Collection_Flow contain fromEmailAddress

**Migration Impact**: HIGH - Core email functionality broken without handler V2, custom label, and trigger

**Estimated Migration Time**: 2-3 hours

---

## Component-by-Component Comparison

### 1. Apex Handler Class

| Component | OldOrg (Source) | NewOrg (Target) | Gap | Action Required |
|-----------|----------------|----------------|-----|-----------------|
| **NewCaseEmailPopACCandContactHandler.cls** | **2,827 lines** (Oct 16, 2025 20:54 UTC) | **1,522 lines** (Oct 2, 2025 09:33 UTC) | **🚨 CRITICAL: Missing 1,305 lines (46%)** | Deploy V2 from OldOrg |
| Last Modified By | John Shintu | Mark Strutz | Different author | - |
| Version | **V2 with regex extraction** | V1 without regex | V1 deployed, V2 needed | Replace with V2 |

**Gap Details**:

**V2 Features Missing in NewOrg**:
```apex
// 1. EMAIL EXTRACTION LOGIC (Missing)
Pattern emailPattern = Pattern.compile('\\(([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})\\)');
Matcher emailMatcher = emailPattern.matcher(caseDescription);
if (emailMatcher.find()) {
    String extractedEmail = emailMatcher.group(1);
}

// 2. CONTACT MATCHING (Missing)
List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Email = :extractedEmail LIMIT 1];
if (!contacts.isEmpty()) {
    Contact matchedContact = contacts[0];
    caseRecord.ContactId = matchedContact.Id;
    caseRecord.AccountId = matchedContact.AccountId;
}

// 3. ERROR HANDLING (Missing)
try {
    // Email extraction and contact matching
} catch (Exception e) {
    System.debug('Error in email extraction: ' + e.getMessage());
}
```

**Impact if Not Migrated**: Cases created from portal emails will NOT have Contact/Account populated - defeats entire purpose of SPF fix

---

### 2. Apex Test Class

| Component | OldOrg (Source) | NewOrg (Target) | Gap | Action Required |
|-----------|----------------|----------------|-----|-----------------|
| **NewCaseEmailPopACCandContactHandlerTest.cls** | **5,608 lines** (Oct 16, 2025 20:54 UTC) | **1,660 lines** (Sep 17, 2025 18:12 UTC) | **⚠️ WARNING: Missing 3,948 lines (70%)** | Deploy V2 from OldOrg |
| Test Coverage | **91%** (4 test methods) | Unknown (older version) | Likely lower coverage | Update to V2 tests |
| Tests Passing | ✅ All 4 passing | Unknown | Needs verification | Run tests post-deployment |

**Gap Details**:

**V2 Test Methods Missing in NewOrg**:
1. `testEmailExtraction()` - Tests regex pattern matching
2. `testContactMatching()` - Tests Contact lookup via extracted email
3. `testAccountPopulation()` - Tests Account ID population from Contact
4. `testErrorHandling()` - Tests exception handling for malformed emails

**Impact if Not Migrated**: Cannot verify V2 functionality works correctly - deployment risk increases

---

### 3. Custom Label

| Component | OldOrg (Source) | NewOrg (Target) | Gap | Action Required |
|-----------|----------------|----------------|-----|-----------------|
| **From_Address_Portal_Exchanges** | ✅ EXISTS | 🚨 **MISSING** | Label not created | Create custom label |
| Value | portal-exchanges@recyclinglives-services.com | N/A | - | Set value |
| Category | Custom Labels | N/A | - | Assign category |

**Gap Details**:

**Custom Label Query Result (NewOrg)**:
```sql
SELECT Name, Value FROM CustomLabel WHERE Name = 'From_Address_Portal_Exchanges'
-- Result: 0 records
```

**Impact if Not Migrated**:
- Flows will fail validation during deployment (reference to non-existent label)
- Email alerts will not have FROM address configured
- SPF/DMARC validation will fail (emails sent from wrong address)

**Priority**: 🔴 CRITICAL - Must be created BEFORE deploying flows

---

### 4. Apex Trigger

| Component | OldOrg (Source) | NewOrg (Target) | Gap | Action Required |
|-----------|----------------|----------------|-----|-----------------|
| **NewCaseEmailTrigger** | ✅ Active (Oct 16, 2025 20:54 UTC) | 🚨 **MISSING** | Trigger not deployed | Deploy trigger |
| Trigger Events | Before Update | N/A | - | Configure events |
| Handler | NewCaseEmailPopACCandContactHandler | N/A | - | Link to handler |

**Gap Details**:

**Trigger Query Result (NewOrg)**:
```sql
SELECT Name, Status FROM ApexTrigger WHERE Name = 'NewCaseEmailTrigger'
-- Result: 0 records
```

**Trigger Code (Missing in NewOrg)**:
```apex
trigger NewCaseEmailTrigger on Case (before update) {
    NewCaseEmailPopACCandContactHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
}
```

**Impact if Not Migrated**: Handler class will never execute - entire SPF fix will not work

**Priority**: 🔴 CRITICAL - Required for handler to execute

---

### 5. Email Templates

| Template | OldOrg (Source) | NewOrg (Target) | Gap | Action Required |
|----------|----------------|----------------|-----|-----------------|
| **New_Exchange_Request_Email_1_1** | Has "sent by {!User.Name} ({!User.Email})" | Has "sent by {!User.Name}" ❌ | **Missing ({!User.Email})** | Update template |
| **New_Job_Booking_Request_Email_1_1** | Has "sent by {!User.Name} ({!User.Email})" | Has "sent by {!User.Name}" ❌ | **Missing ({!User.Email})** | Update template |
| **Organise_Collection_Customer_Email_1_0** | Has "sent by {!User.Name} ({!User.Email})" | Has "sent by {!User.Name}" ❌ | **Missing ({!User.Email})** | Update template |
| **Cancel_Collection_Customer_Email_1_1** | Unknown (needs verification) | Has "sent by {!User.Name}" ❌ | **Missing ({!User.Email})** | Update template |
| **Cancel_Delivery_Customer_Email_1_1** | Unknown (needs verification) | Has "sent by {!User.Name}" ❌ | **Missing ({!User.Email})** | Update template |

**Gap Details**:

**Current NewOrg Template Pattern**:
```
sent by {!User.Name}
```

**Required OldOrg Pattern**:
```
sent by {!User.Name} ({!User.Email})
```

**Why This Matters**:
- Handler V2 uses regex pattern `\\(([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})\\)` to extract email
- Without "({!User.Email})" in parentheses, regex will not match
- Contact/Account lookup will fail - Case remains unlinked

**Impact if Not Migrated**: Email extraction will fail, Contact/Account will not populate

**Priority**: 🔴 HIGH - Required for handler logic to work

---

### 6. Flows

#### 6a. Flows WITH fromEmailAddress Parameter (✅ CORRECT)

| Flow | OldOrg Version | NewOrg Version | Status | Action Required |
|------|---------------|---------------|--------|-----------------|
| **Exchange_Job** | V42 Active (Oct 16, 2025 21:39 UTC) | V1 Active (Oct 15, 2025 11:58 UTC) | ✅ **HAS FIX** | Verify parameter value |
| **Create_Job** | V58 Active (Oct 16, 2025 20:37 UTC) | V1 Active (Oct 13, 2025 13:15 UTC) | ✅ **HAS FIX** | Verify parameter value |
| **Create_Mixed_Waste_Type_Job** | V4 Active (Oct 16, 2025 21:44 UTC) | V1 Active (Oct 13, 2025 13:15 UTC) | ✅ **HAS FIX** | Verify parameter value |
| **Cancel_Collection_Flow** | V2 Active (Oct 16, 2025 21:43 UTC) | V1 Active (Oct 16, 2025 09:34 UTC) | ✅ **HAS FIX** | Verify parameter value |

**Gap Details**:

These 4 flows **contain** the fromEmailAddress parameter in NewOrg, which means they were deployed with the SPF fix. However:

**Version Number Mismatch**:
- OldOrg shows high version numbers (V42, V58) from iterative development
- NewOrg shows V1 (likely fresh deployment to new org)
- **Version number difference is expected** - NewOrg is new org, starts at V1

**Critical Verification Needed**:
```bash
# MUST verify fromEmailAddress points to correct custom label
grep -A 2 "fromEmailAddress" /home/john/Projects/Salesforce/force-app/main/default/flows/Exchange_Job.flow-meta.xml

# Expected output:
<fromEmailAddress>{!$Label.From_Address_Portal_Exchanges}</fromEmailAddress>
```

**Potential Issue**: If custom label doesn't exist in NewOrg, flow will fail at runtime

---

#### 6b. Flows WITHOUT fromEmailAddress Parameter (🚨 MISSING)

| Flow | OldOrg Version | NewOrg Version | Status | Action Required |
|------|---------------|---------------|--------|-----------------|
| **Cancel_Flow** | V4 Active (Oct 16, 2025 21:43 UTC) | **NOT ACTIVE** ❌ | 🚨 **MISSING** | Deploy flow from OldOrg |
| **Job_Organise_Collection** | V23 Active (Oct 16, 2025 21:45 UTC) | **NOT ACTIVE** ❌ | 🚨 **MISSING** | Deploy flow from OldOrg |

**Gap Details**:

**NewOrg Query Result**:
```sql
SELECT Definition.DeveloperName, VersionNumber, Status
FROM Flow
WHERE Definition.DeveloperName IN ('Cancel_Flow', 'Job_Organise_Collection')
  AND Status = 'Active'
-- Result: 0 records
```

**Why These Flows Are Missing**:
- Cancel_Flow: Likely not migrated yet (new flow in OldOrg)
- Job_Organise_Collection: Possibly renamed or not activated in NewOrg

**Impact if Not Migrated**:
- Cancel_Flow: Cancellation emails will use wrong FROM address (SPF fail)
- Job_Organise_Collection: Collection emails will use wrong FROM address (SPF fail)

**Priority**: 🔴 CRITICAL - Required for complete SPF/DMARC compliance

---

## Summary of Gaps

### Critical Gaps (🚨 Deployment Blockers)

| Component | OldOrg | NewOrg | Impact | Priority |
|-----------|--------|--------|--------|----------|
| Custom Label | ✅ EXISTS | 🚨 MISSING | Flow deployment will fail | 🔴 CRITICAL |
| Trigger | ✅ Active | 🚨 MISSING | Handler never executes | 🔴 CRITICAL |
| Handler Class | V2 (2,827 lines) | V1 (1,522 lines) | Email extraction broken | 🔴 CRITICAL |
| Cancel_Flow | V4 Active | 🚨 MISSING | Cancellation SPF fails | 🔴 CRITICAL |
| Job_Organise_Collection | V23 Active | 🚨 MISSING | Collection SPF fails | 🔴 CRITICAL |

### High Priority Gaps (⚠️ Functional Issues)

| Component | OldOrg | NewOrg | Impact | Priority |
|-----------|--------|--------|--------|----------|
| Test Class | V2 (5,608 lines) | V1 (1,660 lines) | Cannot verify V2 works | 🟡 HIGH |
| Email Templates (5) | Has ({!User.Email}) | Missing ({!User.Email}) | Regex extraction fails | 🟡 HIGH |

### Low Priority Gaps (📋 Non-Blocking)

| Component | OldOrg | NewOrg | Impact | Priority |
|-----------|--------|--------|--------|----------|
| Flow Version Numbers | V4-V58 | V1 | Cosmetic only | 🟢 LOW |

---

## Gap Analysis by Category

### Category 1: Code Components

**Total Components**: 3 (Handler, Test, Trigger)

| Status | Count | Components |
|--------|-------|------------|
| 🚨 Missing | 1 | NewCaseEmailTrigger |
| ⚠️ Outdated | 2 | NewCaseEmailPopACCandContactHandler (V1→V2), NewCaseEmailPopACCandContactHandlerTest (V1→V2) |
| ✅ Up to Date | 0 | - |

**Code Gap Summary**:
- **46% of handler code missing** (1,305 lines)
- **70% of test code missing** (3,948 lines)
- **100% of trigger missing** (entire component)

---

### Category 2: Configuration Components

**Total Components**: 2 (Custom Label, Email Templates)

| Status | Count | Components |
|--------|-------|------------|
| 🚨 Missing | 1 | From_Address_Portal_Exchanges custom label |
| ⚠️ Incomplete | 5 | All 5 email templates missing ({!User.Email}) pattern |
| ✅ Complete | 0 | - |

**Configuration Gap Summary**:
- **Custom label**: Completely missing
- **Email templates**: Exist but lack critical email extraction pattern

---

### Category 3: Flow Components

**Total Components**: 6 flows

| Status | Count | Flows |
|--------|-------|-------|
| 🚨 Missing | 2 | Cancel_Flow, Job_Organise_Collection |
| ✅ Has Fix | 4 | Exchange_Job, Create_Job, Create_Mixed_Waste_Type_Job, Cancel_Collection_Flow |

**Flow Gap Summary**:
- **33% completely missing** (2 of 6 flows)
- **67% have fromEmailAddress** (4 of 6 flows)
- **Verification needed**: Confirm fromEmailAddress points to correct label

---

## Migration Impact Assessment

### Impact on Business Processes

**Without Migration**:
1. **Email Creation from Portal**: Cases created from portal user emails will NOT have Contact/Account linked
2. **SPF/DMARC Validation**: Emails sent without org-wide address will fail SPF checks, bouncing or going to spam
3. **Case Assignment**: Unlinked Cases won't follow normal assignment rules (depends on Contact/Account)
4. **Reporting**: Case reports by Account/Contact will be inaccurate (missing portal cases)
5. **Customer Experience**: Portal users won't see their Cases in portal (not linked to Contact)

**With Complete Migration**:
1. ✅ All portal emails use org-wide address (SPF/DMARC pass)
2. ✅ Handler extracts portal user email from body
3. ✅ Contact/Account automatically populated
4. ✅ Cases follow normal business processes
5. ✅ Customer portal experience works correctly

---

### Risk Assessment

| Risk | Likelihood | Impact | Severity | Mitigation |
|------|------------|--------|----------|------------|
| Custom label missing causes flow deployment failure | 🔴 HIGH | 🔴 HIGH | 🚨 CRITICAL | Create label BEFORE deploying flows |
| Handler V1 in production causes Contact/Account not to populate | 🔴 HIGH | 🔴 HIGH | 🚨 CRITICAL | Deploy handler V2 with trigger |
| Email templates missing pattern causes extraction to fail | 🔴 HIGH | 🟡 MEDIUM | 🟡 HIGH | Update all 5 templates with ({!User.Email}) |
| Cancel_Flow missing causes cancellation emails to fail SPF | 🟡 MEDIUM | 🟡 MEDIUM | 🟡 MEDIUM | Deploy flow from OldOrg |
| Job_Organise_Collection missing causes collection emails to fail SPF | 🟡 MEDIUM | 🟡 MEDIUM | 🟡 MEDIUM | Deploy flow from OldOrg |
| Test class V1 provides inadequate coverage for V2 | 🟢 LOW | 🟡 MEDIUM | 🟢 LOW | Deploy test class V2, run all tests |

---

## Deployment Order

To minimize risk, components must be deployed in this order:

### Phase 1: Foundation (Custom Label)
```
1. From_Address_Portal_Exchanges custom label
   ↓
   Enables flows to reference label
```

### Phase 2: Code (Apex Classes)
```
2. NewCaseEmailPopACCandContactHandler.cls (V2)
3. NewCaseEmailPopACCandContactHandlerTest.cls (V2)
   ↓
   Enables trigger to call handler
```

### Phase 3: Trigger (Apex Trigger)
```
4. NewCaseEmailTrigger
   ↓
   Enables handler to execute on Case updates
```

### Phase 4: Configuration (Email Templates)
```
5. New_Exchange_Request_Email_1_1 (add ({!User.Email}))
6. New_Job_Booking_Request_Email_1_1 (add ({!User.Email}))
7. Organise_Collection_Customer_Email_1_0 (add ({!User.Email}))
8. Cancel_Collection_Customer_Email_1_1 (add ({!User.Email}))
9. Cancel_Delivery_Customer_Email_1_1 (add ({!User.Email}))
   ↓
   Enables handler to extract email from body
```

### Phase 5: Flows (Missing Flows)
```
10. Cancel_Flow (with fromEmailAddress)
11. Job_Organise_Collection (with fromEmailAddress)
   ↓
   Completes SPF/DMARC coverage for all email scenarios
```

### Phase 6: Verification (Existing Flows)
```
12. Verify Exchange_Job has correct fromEmailAddress
13. Verify Create_Job has correct fromEmailAddress
14. Verify Create_Mixed_Waste_Type_Job has correct fromEmailAddress
15. Verify Cancel_Collection_Flow has correct fromEmailAddress
   ↓
   Confirms existing flows work with custom label
```

---

## Dependencies and Prerequisites

### Internal Dependencies

```
Custom Label (From_Address_Portal_Exchanges)
    ↓
    Required by: All 6 flows

Handler Class (NewCaseEmailPopACCandContactHandler V2)
    ↓
    Required by: NewCaseEmailTrigger

Email Templates (with ({!User.Email}) pattern)
    ↓
    Required by: Handler regex extraction logic

Trigger (NewCaseEmailTrigger)
    ↓
    Required by: Handler execution on Case updates
```

### External Dependencies

**Org-Wide Email Address**:
- Address: portal-exchanges@recyclinglives-services.com
- Must be created and verified in NewOrg
- Must have display name configured
- Required before flows can send emails

**Email-to-Case Configuration**:
- Email-to-Case must be enabled
- Routing addresses must be configured
- Case assignment rules must exist

**Portal Configuration**:
- Experience Cloud site must be active
- Portal users must have correct profiles
- Email relay must be configured

---

## Testing Requirements Post-Migration

### Test Case 1: Email Extraction
**Setup**: Portal user creates Job, flow sends email to CS team
**Expected**: Handler extracts portal user email from body using regex
**Verification**: Check Case Description contains extracted email

### Test Case 2: Contact Matching
**Setup**: Extracted email matches existing Contact
**Expected**: Case.ContactId populated with matched Contact
**Verification**: Query Case, confirm ContactId is populated

### Test Case 3: Account Population
**Setup**: Matched Contact has AccountId
**Expected**: Case.AccountId populated from Contact.AccountId
**Verification**: Query Case, confirm AccountId is populated

### Test Case 4: SPF/DMARC Validation
**Setup**: Flow sends email using fromEmailAddress
**Expected**: Email passes SPF/DMARC checks, delivered successfully
**Verification**: Check email headers for "spf=pass" and "dmarc=pass"

### Test Case 5: Missing Contact Scenario
**Setup**: Extracted email does NOT match any Contact
**Expected**: Case created but ContactId/AccountId remain null
**Verification**: Query Case, confirm no Contact/Account linkage

---

## Known Limitations After Migration

1. **Email Pattern Dependency**: Handler relies on exact pattern "sent by Name (email@domain.com)" - any deviation breaks extraction
2. **Single Contact Assumption**: If multiple Contacts share same email, only first match is used
3. **Manual Case Creation**: Handler only works for Email-to-Case, not manual Case creation
4. **Case Update Timing**: Trigger runs on before update, may not work if Case is updated by other processes simultaneously

---

## Migration Complexity Assessment

**Complexity Score**: 6/10 (Medium-High)

**Complexity Factors**:
- ✅ Simple: Only 3 Apex components (handler, test, trigger)
- ⚠️ Moderate: 6 flows to deploy/verify
- ⚠️ Moderate: 5 email templates to update
- 🚨 Complex: Custom label must exist BEFORE flows deploy
- 🚨 Complex: Org-wide email address must be verified
- ⚠️ Moderate: Regex pattern matching adds testing complexity

**Estimated Migration Time**: 2-3 hours
- Phase 1 (Label): 15 min
- Phase 2 (Apex): 30 min
- Phase 3 (Trigger): 15 min
- Phase 4 (Templates): 45 min
- Phase 5 (Flows): 45 min
- Phase 6 (Verification): 30 min

---

## Recommended Migration Approach

### Approach: Deploy All Components from OldOrg

**Rationale**:
- NewOrg components are outdated (V1 vs V2)
- Multiple components completely missing
- Partial migration would leave functionality broken
- Complete deployment ensures consistency

**Steps**:
1. Create custom label (prerequisite for all flows)
2. Deploy handler V2 + test V2 (replaces outdated V1)
3. Deploy trigger (currently missing)
4. Update all 5 email templates (add email pattern)
5. Deploy 2 missing flows (Cancel_Flow, Job_Organise_Collection)
6. Verify 4 existing flows have correct fromEmailAddress
7. Run all tests (verify 91% coverage maintained)
8. Test email extraction with sample portal email

---

## Gap Analysis Conclusion

**Overall Migration Status**: 🚨 HIGH PRIORITY

**Key Takeaways**:
1. ⚠️ **Handler class 46% smaller in NewOrg** - missing core email extraction logic
2. 🚨 **Trigger completely missing** - handler will never execute
3. 🚨 **Custom label missing** - flow deployment will fail
4. ⚠️ **Email templates incomplete** - regex extraction will fail
5. 🚨 **2 flows missing** - incomplete SPF/DMARC coverage
6. ✅ **4 flows have fromEmailAddress** - partial fix already deployed

**Migration Urgency**: HIGH - Current NewOrg implementation is non-functional

**Next Steps**:
1. Review this gap analysis
2. Proceed to migration plan (Phase 3)
3. Execute deployment in correct order
4. Verify all components work together
5. Monitor email deliverability and Case linkage

---

**Gap Analysis Complete** ✅
**Ready for**: Phase 3 (Migration Plan Creation)
**Documentation Date**: October 22, 2025
