# Domestic Customer Email Issue - Fix Documentation

**Created**: 2025-10-09
**Last Updated**: 2025-10-09
**Org**: OldOrg (Current Production)
**Requested by**: Shintu John
**Reported by**: Dennis Dadey
**Status**: ✅ Resolved

---

## Table of Contents

1. [Issue Summary](#issue-summary)
2. [Root Cause Analysis](#root-cause-analysis)
3. [Current State Analysis](#current-state-analysis)
4. [Solution Implemented](#solution-implemented)
5. [Testing & Verification](#testing--verification)
6. [Impact Assessment](#impact-assessment)
7. [Key Learnings](#key-learnings)
8. [Related Files](#related-files)
9. [Next Steps - Future Prevention](#next-steps---future-prevention)

---

## Issue Summary

**Date Reported**: 2025-10-09
**Reported By**: Dennis Dadey
**Affected Org**: OldOrg (Current Production)
**Affected Record**: Account ID: 001Sj00000OevwDIAR (George Williams)

**Problem**:
- User Dennis Dadey could not book a skip for Domestic Customer "George Williams"
- No email ID associated with the account
- Unable to add email ID - no edit option visible on the Account record
- Skip booking process blocked due to missing email requirement

**Business Impact**:
- Unable to process customer orders
- Customer service blocked from creating jobs
- Potential revenue loss and customer dissatisfaction

**Account Details**:
- **Account Name**: George Williams
- **Account ID**: 001Sj00000OevwDIAR
- **Record Type**: Domestic Customer
- **Account Type**: Person Account (IsPersonAccount = true)
- **Contact ID**: 003Sj00000ROEtaIAH
- **Owner**: Kaylie Morris (0054H000005pLoQQAU)

---

## Root Cause Analysis

### Why This Happened

**Person Account Architecture**:
The "Domestic Customer" record type uses Salesforce's **Person Account** functionality, which is a special account type that:

1. **Combines Account and Contact**: Person Accounts merge Account and Contact records into a single entity
2. **Uses Special Fields**: Email is stored in `PersonEmail` field (not standard Account fields)
3. **Different Field Access**: Person Account fields require specific page layout configuration
4. **Hidden Edit Capability**: Standard Account page layouts don't always expose PersonEmail for editing

### Technical Details

**Query Results** (2025-10-09):
```sql
SELECT Id, Name, RecordType.Name, PersonEmail, Phone, IsPersonAccount
FROM Account
WHERE Id = '001Sj00000OevwDIAR'
```

**Results**:
| ID | NAME | RECORDTYPE.NAME | PERSONEMAIL | ISPERSONACCOUNT |
|----|------|----------------|-------------|-----------------|
| 001Sj00000OevwDIAR | George Williams | Domestic Customer | null | true |

**Associated Contact**:
```sql
SELECT Id, FirstName, LastName, Email, AccountId
FROM Contact
WHERE AccountId = '001Sj00000OevwDIAR'
```

**Results**:
| ID | FIRSTNAME | LASTNAME | EMAIL | ACCOUNTID |
|----|-----------|----------|-------|-----------|
| 003Sj00000ROEtaIAH | George | Williams | null | 001Sj00000OevwDIAR |

### Why Email Field Was Not Editable

1. **Field Not on Page Layout**: The `PersonEmail` field was not added to the Domestic Customer page layout
2. **Person Account Limitation**: Standard Account edit screens don't automatically show Person Account-specific fields
3. **No Alternative Entry Point**: Users had no way to add email through the UI

### Why Email Is Required

The **Domestic Create Job** flow (`Domestic_Create_Job.flow-meta.xml`) includes email validation:

**Flow Logic** (Lines 440-462):
```xml
<decisions>
    <name>Account_Email_Decision</name>
    <label>Account Email Decision</label>
    <defaultConnector>
        <targetReference>Account_Email_Required</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>Email Not Available</defaultConnectorLabel>
    <rules>
        <name>Email_Available</name>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>Get_Account_Record.PersonEmail</leftValueReference>
            <operator>IsNull</operator>
            <rightValue>
                <booleanValue>false</booleanValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Get_Quote_Line_Item</targetReference>
        </connector>
        <label>Email Available</label>
    </rules>
</decisions>
```

**Flow Behavior**:
- Checks if `PersonEmail` is NULL
- If NULL → Shows error screen "Account Email Required"
- If NOT NULL → Proceeds to create job, order, and invoice

**Email Usage in Process**:
- Customer invoice sent automatically by email
- Booking confirmation sent to customer
- Communication trail for job updates

---

## Current State Analysis

**Verified in**: OldOrg (Current Production)
**Date**: 2025-10-09
**Method**: SOQL queries via Salesforce CLI

### Record Type Configuration

```sql
SELECT Id, DeveloperName, Name, Description
FROM RecordType
WHERE SObjectType = 'Account' AND DeveloperName = 'DomesticCustomer'
```

**Result**:
- **ID**: 0124H000000At5TQAS
- **Developer Name**: DomesticCustomer
- **Name**: Domestic Customer
- **Description**: null

### Active Account Record Types

Total: 5 active record types for Account object:
1. Person Account (0124H000000At5JQAS)
2. **Domestic Customer** (0124H000000At5TQAS) ← Affected record type
3. Supplier (0124H000000FWTUQA4)
4. Customer (0124H000000FWUIQA4)
5. Charity Partnerships (012Sj000000CijdIAC)

### Domestic Customer Usage

Found 110 files referencing "Domestic" in the codebase, including:
- **Flows**: Domestic_Create_Job, Domestic_Missing_Shipping_Address
- **Apex Classes**: CreateDomesticInvoiceFlowHandler, AutoConvertDomesticLeads
- **Layouts**: Opportunity-Domestic.layout-meta.xml
- **Fields**: Multiple Domestic-specific fields across objects

This indicates Domestic Customer is a heavily-used feature in the system.

---

## Solution Implemented

### Option C: System Admin Direct Update (Immediate Fix)

**Date**: 2025-10-09
**Implemented By**: Claude (via Shintu John)
**Method**: Salesforce CLI data update command

**Command Executed**:
```bash
sf data update record \
  --sobject Account \
  --record-id 001Sj00000OevwDIAR \
  --values "PersonEmail='tenspaces@hotmail.com'" \
  --target-org OldOrg
```

**Result**: Successfully updated record: 001Sj00000OevwDIAR

**Why This Solution**:
- **Immediate**: Unblocks Dennis Dadey right now
- **Direct**: Updates the exact field the flow checks
- **Safe**: Single-record update with known email address
- **Minimal Risk**: No code deployment or configuration changes required

---

## Testing & Verification

### Post-Update Verification

**Query Executed**:
```sql
SELECT Id, Name, PersonEmail, RecordType.Name
FROM Account
WHERE Id = '001Sj00000OevwDIAR'
```

**Results** (2025-10-09):
| ID | NAME | PERSONEMAIL | RECORDTYPE.NAME |
|----|------|-------------|----------------|
| 001Sj00000OevwDIAR | George Williams | tenspaces@hotmail.com | Domestic Customer |

✅ **Email successfully updated**

### Expected Behavior Now

Dennis Dadey can now:
1. Open the Quote for George Williams
2. Run "Domestic Create Job" flow
3. Flow will pass the `Account_Email_Decision` check (PersonEmail is NOT NULL)
4. Proceed with:
   - Delivery details input
   - Payment reference
   - Job creation
   - Order creation
   - Invoice generation
   - Automatic email to customer at `tenspaces@hotmail.com`

---

## Impact Assessment

### Before Fix

❌ **What Didn't Work**:
- Dennis Dadey could not create jobs for this Domestic Customer
- No way to add email through standard UI
- Skip booking process completely blocked
- Customer order could not be processed

❌ **Users Affected**:
- Dennis Dadey (immediate)
- Any user trying to book skips for Domestic Customers without emails
- Potentially all Domestic Customer service representatives

### After Fix

✅ **What Now Works**:
- Dennis can proceed with skip booking for George Williams
- Email validation in Domestic Create Job flow will pass
- Invoice and confirmation emails can be sent automatically
- Customer order can be completed end-to-end

✅ **Immediate Benefit**:
- Unblocked 1 customer order
- Restored normal workflow for Dennis Dadey

⚠️ **Limitation**:
- This fix only addresses THIS ONE account
- Other Domestic Customer accounts may have the same issue
- Users still cannot edit PersonEmail through standard UI

---

## Key Learnings

### Technical Insights

1. **Person Accounts Use Different Fields**:
   - Regular Account: Uses standard email fields
   - Person Account: Uses `PersonEmail` field
   - These are NOT the same field

2. **Record Type ≠ Person Account**:
   - "Domestic Customer" is a record type name
   - But it's configured as a Person Account type
   - This creates confusion for users expecting standard Account behavior

3. **Flow Dependencies on Field Availability**:
   - The Domestic Create Job flow REQUIRES PersonEmail
   - No workaround or bypass in the flow
   - Email is mandatory for invoice generation and customer communication

4. **Page Layout Configuration Critical**:
   - Even if a field exists, users can't edit it without page layout access
   - Person Account fields need explicit addition to layouts
   - Standard Account layouts don't auto-include Person Account fields

### Why This Was Hard to Diagnose

1. **No Obvious Error Message**: User just saw "no option to edit"
2. **Field Not Visible**: PersonEmail wasn't on the layout to see it was empty
3. **Special Account Type**: Person Accounts behave differently than expected
4. **Flow Validation Hidden**: Error only appears when trying to create job

---

## Related Files

### Flows
- [Domestic_Create_Job.flow-meta.xml](../force-app/main/default/flows/Domestic_Create_Job.flow-meta.xml) - Main skip booking flow with email validation

### Apex Classes
- [CreateDomesticInvoiceFlowHandler.cls](../force-app/main/default/classes/CreateDomesticInvoiceFlowHandler.cls) - Invoice creation logic
- [CreateDomesticInvoiceFlowHandlerTest.cls](../force-app/main/default/classes/CreateDomesticInvoiceFlowHandlerTest.cls) - Test class
- [AutoConvertDomesticLeads.cls](../force-app/main/default/classes/AutoConvertDomesticLeads.cls) - Lead conversion logic
- [AutoConvertDomesticLeadsTest.cls](../force-app/main/default/classes/AutoConvertDomesticLeadsTest.cls) - Test class

### Layouts
- [Account-Account Layout.layout-meta.xml](../force-app/main/default/layouts/Account-Account%20Layout.layout-meta.xml) - Standard Account layout
- [Opportunity-Domestic.layout-meta.xml](../force-app/main/default/layouts/Opportunity-Domestic.layout-meta.xml) - Domestic opportunity layout

### Record Types
- Domestic Customer Record Type ID: `0124H000000At5TQAS`
- Person Account Record Type ID: `0124H000000At5JQAS`

---

## Next Steps - Future Prevention

### Problem Scope

This fix addressed ONE account, but the underlying issue affects ALL Domestic Customer accounts where PersonEmail is missing or needs updating.

### Recommended Actions (To Be Implemented Later)

#### 1. Add PersonEmail Field to Domestic Customer Page Layout

**What**: Modify the page layout assigned to Domestic Customer record type to include PersonEmail field as an editable field

**Why**:
- Users like Dennis can edit email directly
- Self-service capability reduces admin dependency
- Prevents future tickets for the same issue

**How**:
1. Navigate to: **Setup → Object Manager → Account → Page Layouts**
2. Identify which layout is assigned to "Domestic Customer" record type
3. Edit the layout
4. Add "Person Email" field to an editable section (recommended: near top of layout)
5. Save and test

**Benefit**: All users can edit PersonEmail going forward

---

#### 2. Audit Existing Domestic Customer Accounts

**What**: Query all Domestic Customer accounts to find those with missing emails

**Why**: Proactively identify and fix accounts before users encounter blocking issues

**Query**:
```sql
SELECT Id, Name, PersonEmail, Owner.Name, CreatedDate
FROM Account
WHERE RecordType.DeveloperName = 'DomesticCustomer'
  AND PersonEmail = null
ORDER BY CreatedDate DESC
```

**Expected Action**:
- Generate report of accounts needing emails
- Contact account owners to gather email addresses
- Bulk update emails where possible

**Benefit**: Reduce future service interruptions

---

#### 3. Update Flow to Provide Better Error Messaging

**What**: Modify `Domestic_Create_Job` flow to show clearer error message with instructions

**Current Message**: "Account Email Required."

**Improved Message**:
```
"Account Email Required to Create Job

The customer email address is missing. Please contact your system
administrator to add the email address before proceeding.

Account: {Account Name}
Account ID: {Account ID}
```

**Why**:
- Users understand what's wrong
- Users know who to contact
- Reduces back-and-forth troubleshooting

**How**: Edit the `Account_Email_Required` screen in the flow

**Benefit**: Faster issue resolution when it occurs

---

#### 4. Consider Email Field Requirement on Account Creation

**What**: Add validation rule or required field setting for PersonEmail on Domestic Customer accounts

**Why**: Prevents accounts from being created without emails in the first place

**Considerations**:
- May block some legitimate use cases (accounts in progress)
- Need to understand full business process first
- Could use a checkbox "Email to be added later" with workflow reminder

**Action**: Discuss with business stakeholders before implementing

**Benefit**: Root cause prevention - emails captured at creation time

---

#### 5. Create User Documentation

**What**: Document the Person Account email editing process for end users

**Content Should Include**:
- What Person Accounts are
- Where to find the email field
- How to edit it (once layout is updated)
- Who to contact if edit access is missing
- Screenshot walkthrough

**Where**: Internal knowledge base or Salesforce help content

**Benefit**: Empowers users, reduces support tickets

---

### Priority Recommendation

**High Priority** (Implement Soon):
1. Add PersonEmail field to page layout (Quick win, prevents future issues)
2. Audit existing accounts (Identify scope of problem)

**Medium Priority** (Plan for Later):
3. Improve flow error messaging (Better user experience)
5. Create user documentation (Self-service enablement)

**Low Priority** (Discuss with Business First):
4. Email requirement on creation (Requires business process analysis)

---

## Resolution Summary

**Resolution Date**: 2025-10-09
**Resolved By**: Claude (via Shintu John - System Administrator)
**Method**: Direct PersonEmail field update via Salesforce CLI
**Status**: ✅ Immediate Issue Resolved

**Affected Account**:
- **Before**: George Williams (001Sj00000OevwDIAR) - PersonEmail = NULL
- **After**: George Williams (001Sj00000OevwDIAR) - PersonEmail = tenspaces@hotmail.com

**User Impact**:
- Dennis Dadey can now proceed with skip booking
- Customer order can be processed
- Workflow restored to normal operation

**Systemic Fix**: Pending future implementation of preventive measures outlined above

---

## Additional Update - Customer Details Changed

**Update Date**: 2025-10-09
**Updated By**: Claude (via Shintu John - System Administrator)
**Reason**: Customer details update requested

**Account ID**: 001Sj00000OevwDIAR

### Changes Applied:

**Customer Name & Details**:
- **Before**: George Williams
- **After**: Mr Illy Mitha ✅
  - Salutation: None → **Mr**
  - First Name: George → **Illy**
  - Last Name: Williams → **Mitha**

**Mailing Address**:
- **Before**: Moorpark, Preston, PR1 6AU
- **After**: 79 Moorpark Avenue, Preston, PR1 3NR ✅

**Billing Address**:
- **Before**: Moorpark, Preston, PR1 6AU
- **After**: 79 Moorpark Avenue, Preston, PR1 3NR ✅

**Email** (unchanged):
- tenspaces@hotmail.com ✅

**Commands Executed**:
```bash
# Update customer name and mailing address
sf data update record --sobject Account --record-id 001Sj00000OevwDIAR \
  --values "Salutation='Mr' FirstName='Illy' LastName='Mitha' \
            PersonMailingStreet='79 Moorpark Avenue' \
            PersonMailingCity='Preston' \
            PersonMailingPostalCode='PR1 3NR'" \
  --target-org OldOrg

# Update billing address
sf data update record --sobject Account --record-id 001Sj00000OevwDIAR \
  --values "BillingStreet='79 Moorpark Avenue' \
            BillingCity='Preston' \
            BillingPostalCode='PR1 3NR'" \
  --target-org OldOrg
```

**Verification**:
All fields successfully updated and verified via SOQL query. Account now reflects correct customer details for Mr Illy Mitha.

---

**Document Owner**: Shintu John
**Last Review**: 2025-10-09
**Next Review**: After preventive measures implementation
