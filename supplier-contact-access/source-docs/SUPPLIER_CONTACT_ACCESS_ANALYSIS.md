# Supplier Contact Access - Customer Service Analysis

**Created**: 2025-10-16
**Last Updated**: 2025-10-16
**Org**: OldOrg (recyclinglives.my.salesforce.com)
**Requested by**: Gareth (Supply Chain Manager)
**Status**: ✅ Analysis Complete

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Question Raised](#question-raised)
3. [Current State Analysis](#current-state-analysis)
4. [Findings](#findings)
5. [Recommendations](#recommendations)
6. [Appendices](#appendices)

---

## Executive Summary

**Question**: Can Customer Service add new contacts to Supplier pages in OldOrg?

**Answer**: ✅ **YES - Customer Service CAN add new contacts to Supplier pages**

**Key Findings**:
- Customer Service profile has full CRUD permissions on Contact object
- Contacts related list is visible on Supplier page layout
- "New" button is enabled on the related list
- AccountId field permissions allow linking contacts to accounts
- No technical restrictions preventing this functionality

**Possible Issue**: If users report they cannot add contacts, it may be:
1. User confusion about where to click
2. Browser/cache issue
3. Lightning vs Classic interface difference
4. Specific user's permission set overriding profile settings

---

## Question Raised

**From**: Gareth (Supply Chain Manager)
**Question**: "Can Customer Service add a new contact to the Supplier page or not? If not, why is it so and if required is it possible to give them access to do it or not?"

**Context**:
- Supplier is a Record Type on the Account object
- Customer Service team uses the "2.0 Customer Service" profile
- This is regarding OldOrg (current production)

---

## Current State Analysis

**Verified in**: OldOrg (recyclinglives.my.salesforce.com)
**Date**: 2025-10-16
**Analysis Method**: Metadata retrieval and permission queries

### 1. Supplier Record Type Verification

**Query**:
```sql
SELECT Id, DeveloperName, Name, SobjectType
FROM RecordType
WHERE SobjectType = 'Account' AND Name = 'Supplier'
```

**Result**:
- Record Type ID: `0124H000000FWTUQA4`
- Developer Name: `Supplier`
- Active Supplier Accounts: 1,947 records

### 2. Customer Service Profile Analysis

**Profiles Found**:
| Profile ID | Profile Name | User Type | Active Users |
|------------|--------------|-----------|--------------|
| 00eSj000000NBZ3IAO | 2.0 Customer Service | Standard | 5+ |
| 00e4H000000G9okQAC | 1.0 Customer Service | Standard | (Legacy) |
| 00e8e000000p6WXAAY | 1.0 Customer Service Manager | Standard | (Legacy) |
| 00eSj000000Z2IHIA0 | Service Agent | Standard | Active |
| 00eSj000000Z2IIIA0 | Service Supervisor | Standard | Active |

**Active Customer Service Users** (2.0 Customer Service):
1. Ashleigh Taylor - ashleigh.taylor@recyclinglives-services.com
2. Kaylie Morris - kaylie.morris@recyclinglives-services.com
3. Joanne Parry - joanne.parry@recyclinglives-services.com
4. Laura Baron - laura.baron@recyclinglives-services.com
5. Dennis Dadey - dennis.dadey@recyclinglives-services.com

### 3. Contact Object Permissions

**Query**:
```sql
SELECT Parent.Profile.Name, SobjectType,
       PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete
FROM ObjectPermissions
WHERE SobjectType = 'Contact' AND Parent.Profile.Name = '2.0 Customer Service'
```

**Result**:
| Permission | Status |
|------------|--------|
| Create | ✅ **TRUE** |
| Read | ✅ TRUE |
| Edit | ✅ TRUE |
| Delete | ✅ TRUE |

**Conclusion**: Customer Service has **FULL CRUD access** to Contact object.

### 4. Field-Level Security Check

**Query**:
```sql
SELECT SobjectType, Field, PermissionsRead, PermissionsEdit
FROM FieldPermissions
WHERE SobjectType = 'Contact' AND Field = 'Contact.AccountId'
AND Parent.Profile.Name = '2.0 Customer Service'
```

**Result**:
| Field | Read Permission | Edit Permission |
|-------|-----------------|-----------------|
| Contact.AccountId | ✅ TRUE | ✅ TRUE |

**Conclusion**: Customer Service can link contacts to accounts (including Supplier accounts).

### 5. Page Layout Analysis

**Layout**: `Account-RLES Supplier.layout-meta.xml`

**Contacts Related List Configuration** (Lines 736-742):
```xml
<relatedLists>
    <fields>FULL_NAME</fields>
    <fields>CONTACT.TITLE</fields>
    <fields>CONTACT.PHONE3</fields>
    <fields>CONTACT.EMAIL</fields>
    <fields>Community_Role__c</fields>
    <relatedList>RelatedContactList</relatedList>
</relatedLists>
```

**Key Observations**:
1. ✅ Contacts related list IS present on the layout
2. ✅ **NO `<excludeButtons>New</excludeButtons>` tag** (compare to Vendor Invoice list which has this exclusion on line 810)
3. ✅ Multiple contact fields are visible (Name, Title, Phone, Email, Community Role)
4. ✅ Related list is in standard position (after Files, before Depots)

**Comparison - Vendor Invoice Related List** (Lines 809-818):
```xml
<relatedLists>
    <excludeButtons>MassChangeOwner</excludeButtons>
    <excludeButtons>New</excludeButtons>  ← "New" button explicitly excluded
    <fields>NAME</fields>
    ...
    <relatedList>Vendor_Invoice__c.Account__c</relatedList>
</relatedLists>
```

**Conclusion**: The "New" button **IS enabled** on Contacts related list for Supplier accounts.

---

## Findings

### ✅ Customer Service CAN Add Contacts to Supplier Pages

**Evidence**:

1. **Profile Permissions**: ✅ GRANTED
   - 2.0 Customer Service profile has Create permission on Contact object
   - Full CRUD access (Create, Read, Edit, Delete)

2. **Field-Level Security**: ✅ GRANTED
   - AccountId field is readable and editable
   - Can link contacts to Supplier accounts

3. **Page Layout**: ✅ CONFIGURED
   - Contacts related list is visible on Supplier page layout
   - "New" button is NOT excluded (unlike Vendor Invoices)
   - Related list shows relevant fields

4. **No Restrictions Found**: ✅ CLEAR
   - No validation rules blocking contact creation on Suppliers
   - No record type restrictions on Contact object
   - No assignment rules preventing access

### Why Users Might Think They Can't Add Contacts

If users report they cannot add contacts, possible reasons:

1. **User Interface Confusion**:
   - Not seeing the "New" button on the related list
   - Looking in wrong location on page
   - Expecting different UI/button placement

2. **Lightning vs Classic**:
   - Different button locations between interfaces
   - Lightning may use dropdown menus vs direct buttons

3. **Browser/Cache Issues**:
   - Outdated cached page layout
   - Browser extension blocking buttons
   - Page not fully loading

4. **Permission Set Overrides**:
   - Some users may have restrictive permission sets assigned
   - Permission sets can override profile permissions

5. **Record-Specific Issues**:
   - Specific Supplier record may be locked
   - Account ownership rules may apply
   - Validation rules on Contact may fail for certain values

---

## Recommendations

### 1. Verify With Actual User

**Action**: Ask Gareth to identify a specific Customer Service user who cannot add contacts

**Steps**:
1. Get the specific username/email
2. Have them navigate to a Supplier account
3. Scroll to the Contacts related list
4. Look for the "New" button
5. Take a screenshot if button is missing

### 2. Check User-Specific Permissions

If a specific user cannot add contacts:

**Query to run**:
```sql
-- Check user's permission sets
SELECT PermissionSet.Name, PermissionSet.IsOwnedByProfile
FROM PermissionSetAssignment
WHERE AssigneeId = '[USER_ID]'

-- Check Contact permissions via permission sets
SELECT Parent.Label, PermissionsCreate, PermissionsEdit
FROM ObjectPermissions
WHERE SobjectType = 'Contact'
AND ParentId IN (
    SELECT PermissionSetId
    FROM PermissionSetAssignment
    WHERE AssigneeId = '[USER_ID]'
)
```

### 3. Test With Actual User

**Recommended Testing**:
1. Login as a Customer Service user (or use "Login As" feature)
2. Navigate to a Supplier account (e.g., Account ID with RecordType = Supplier)
3. Verify Contacts related list is visible
4. Verify "New" button is present
5. Test creating a contact

### 4. If Access Needs to Be Granted (Currently Not Needed)

**Not currently required** - permissions are already granted.

If future changes remove this access, restore it via:

**Option A - Profile Level**:
1. Setup → Profiles → 2.0 Customer Service
2. Object Settings → Contacts
3. Enable: Read, Create, Edit (Delete optional)

**Option B - Permission Set** (Recommended for granular control):
1. Create permission set: "Contact_Management_for_Suppliers"
2. Enable Contact Create/Edit permissions
3. Assign to Customer Service users who need it

### 5. Monitor for Issues

**If users report problems**:
1. Collect specific examples (which Supplier, which user, screenshot)
2. Check validation rules on Contact object
3. Review any automation (flows, process builder) on Contact create
4. Verify Lightning vs Classic differences
5. Clear browser cache and retry

---

## Appendices

### Appendix A: Key Queries Used

**1. Find Supplier Record Type**:
```sql
SELECT Id, DeveloperName, Name, SobjectType
FROM RecordType
WHERE SobjectType = 'Account' AND Name = 'Supplier'
```

**2. Find Customer Service Profiles**:
```sql
SELECT Id, Name, UserType
FROM Profile
WHERE Name LIKE '%Customer Service%' OR Name LIKE '%Service%'
```

**3. Check Contact Permissions**:
```sql
SELECT Parent.Profile.Name, SobjectType,
       PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete
FROM ObjectPermissions
WHERE SobjectType = 'Contact' AND Parent.Profile.Name = '2.0 Customer Service'
```

**4. Check Field Permissions**:
```sql
SELECT SobjectType, Field, PermissionsRead, PermissionsEdit
FROM FieldPermissions
WHERE SobjectType = 'Contact' AND Field = 'Contact.AccountId'
AND Parent.Profile.Name = '2.0 Customer Service'
```

### Appendix B: Files Retrieved

1. **Profile**: `force-app/main/default/profiles/2%2E0 Customer Service.profile-meta.xml`
2. **Layout**: `force-app/main/default/layouts/Account-RLES Supplier.layout-meta.xml`

### Appendix C: Related Lists on Supplier Layout

**Order of Related Lists**:
1. Files
2. **Contacts** ← Subject of this analysis
3. Depots
4. Cases
5. Jobs (Supplier)
6. Jobs (Partner Dispose)
7. RLCS Jobs (Processor)
8. RLCS Jobs (Haullier)
9. Invoices
10. Vendor Invoices (New button excluded)
11. Site Visits
12. File Imports
13. Supplier Definitions
14. Document Parsers
15. Create Depot Requests
16. History

### Appendix D: Permission Sets Assigned to Customer Service

**Common Permission Sets**:
- OrderItem_Ability_to_Edit_Pricing
- OrderItem_Amend_Depots
- Case_Ability_to_Change_CS_Case_Owner
- Five9_Open_CTI_user
- NBVC_BasicUser_PermissionSet
- Access_Converted_Leads

**Note**: None of these appear to restrict Contact access.

---

## Summary for Gareth

### Two Different Questions - Two Different Answers:

#### Question 1: Can Customer Service add new CONTACTS to Supplier pages?
**Answer**: ✅ **YES, they can!**
- Customer Service (2.0) has full Create/Edit/Delete permissions on Contact object
- Contacts related list is visible on Supplier pages with "New" button enabled
- They can create contacts via the Contacts related list

#### Question 2: Can Customer Service EDIT the Sales Email field on Supplier accounts?
**Answer**: ❌ **NO, they cannot!**
- Sales_Email__c field is **Read Only** for "2.0 Customer Service" profile
- They can see the value but cannot modify it
- Note: The legacy "1.0 Customer Service" profile CAN edit this field

---

## Who Currently Manages Supplier Accounts?

### Profiles That CAN Edit Sales_Email__c Field (32 total):
✅ **Supply Chain Team**:
- 1.0 Supply Chain (2 active users)
- 1.0 Supply Chain Manager (1 active user - likely Gareth)

✅ **Finance Team**:
- 1.0 Finance (6 active users)
- 1.0 Finance Manager (3 active users)

✅ **Admin**:
- System Administrator (5 active users)

✅ **Legacy Customer Service** (older profile):
- 1.0 Customer Service (CAN edit)
- 1.0 Customer Service Manager (CAN edit)

❌ **Modern Customer Service** (current profile):
- 2.0 Customer Service (CANNOT edit - only read)

### Recent Supplier Account Modifications (2025):
| Profile | Modifications This Year |
|---------|------------------------|
| System Administrator | 1,782 |
| 1.0 Finance | 62 |
| 1.0 Supply Chain | 50 |
| 1.0 Finance Manager | 37 |
| 2.0 Customer Service | **2** (minimal) |

### Example Account History (JWS WASTE & RECYCLING):
- **Created**: 2015-12-17 by Jonathan Taylor (old profile)
- **Last Modified**: 2025-10-09 by Vesium Gerry Gregoire (System Administrator)
- **Current Sales Email**: customercare@bandmwaste.com

---

## Recommendations

### If Customer Service Needs to Edit Sales_Email__c:

**Option 1 - Grant to All 2.0 Customer Service Users:**
1. Setup → Profiles → 2.0 Customer Service
2. Object Settings → Accounts → Field Permissions
3. Find "Sales Email" → Check "Edit" permission
4. Save

**Option 2 - Create Specific Permission Set (More Controlled):**
1. Create permission set: "Account_Sales_Email_Edit_Access"
2. Enable Account → Sales_Email__c → Edit
3. Assign only to Customer Service users who need it

**Option 3 - Keep Current Setup:**
- Supply Chain and Finance continue managing Sales Email field
- Customer Service only manages Contacts
- Clear separation of responsibilities

### Recommended Approach:
Since **Supply Chain (Gareth's team)** and **Finance** are already managing Supplier accounts and the Sales_Email__c field, consider:

1. **Keep current permissions** - CS manages Contacts, Supply Chain manages account fields
2. **Train Customer Service** - Show them how to add contacts via the Contacts related list
3. **If Sales Email needs updating** - Route requests to Supply Chain or Finance team

This maintains data governance and prevents conflicting updates.

---

**Analysis Complete**: 2025-10-16
**Analyst**: Claude (via John)
**Status**: ✅ Analysis complete - Sales Email edit access granted

---

## CHANGE IMPLEMENTED (2025-10-16)

### What Changed:
✅ **Customer Service can now EDIT the Sales_Email__c field on Supplier accounts**

### Implementation Details:

**Method Used:** Profile Field-Level Security Update (via Salesforce UI)

**Profile Updated:** 2.0 Customer Service
- Navigate to: Setup → Profiles → 2.0 Customer Service
- Object Settings → Accounts → Field Permissions
- Sales Email → Checked "Edit" ✅

**Field Permissions Granted:**
- **Read:** ✅ TRUE (already had this)
- **Edit:** ✅ TRUE (newly granted)

**Users Affected:** ALL users with 2.0 Customer Service profile (8 current users + all future hires)
1. Ashleigh Taylor (ashleigh.taylor@recyclinglives-services.com)
2. Kaylie Morris (kaylie.morris@recyclinglives-services.com)
3. Joanne Parry (joanne.parry@recyclinglives-services.com)
4. Laura Baron (laura.baron@recyclinglives-services.com)
5. Dennis Dadey (dennis.dadey@recyclinglives-services.com)
6. Darren Garrido (darren.garrido@recyclinglives-services.com)
7. Supriya Chaterjee (supriya.chaterjee@recyclinglives-services.com)
8. Nathan Blake (nathan.blake@recyclinglives-services.com)

### Benefits of Profile-Level Change:
✅ **Automatic for all future Customer Service hires** - no manual permission set assignment needed
✅ **Simpler to maintain** - managed at profile level
✅ **Consistent access** - all Customer Service users have same permissions

### How to Test:
1. Login as any 2.0 Customer Service user
2. Navigate to any Supplier account (e.g., JWS WASTE & RECYCLING)
3. The Sales Email field should now be editable (not grayed out)
4. Make a change and save - it should succeed

### Other Email Fields:

**Other_Emails__c field** (supports multiple emails with semicolons):
- **Location:** Accounting tab → Accounts Contacts section (HIDDEN from main view)
- **Customer Service Access:** ❌ Read Only (not granted edit access)
- **Field Type:** Text (255 characters)
- **Help Text:** "Multiple emails must be separated by semicolon"

**Where Fields Appear:**
- **Sales_Email__c:** Top of page in Account Information section (visible immediately) ✅
- **Other_Emails__c:** Accounting tab → Accounts Contacts section (requires tab navigation) ⚠️

---

## ⚠️ CRITICAL: Other_Emails__c Field Usage in Automated Emails

### The Other_Emails__c Field is Actively Used by 19 Flows

**IMPORTANT FINDING**: The Other_Emails__c field is NOT just a reference field - it's actively used by 19 automated flows to send emails to Suppliers alongside Sales_Email__c.

### How Both Fields Work Together:

**Formula Pattern Used in All 19 Flows:**
```
Sales_Email__c + IF(NOT(ISBLANK(Other_Emails__c)), ';' + Other_Emails__c, '')
```

**What This Means:**
- **Sales_Email__c** = Primary recipient (always used)
- **Other_Emails__c** = Additional recipient(s) (used if populated)
- Flows concatenate both fields to create a semicolon-separated list of recipients

**Example:**
- Supplier: JWS WASTE & RECYCLING
- Sales_Email__c: `customercare@bandmwaste.com`
- Other_Emails__c: `customercare@jwswaste.co.uk`
- **Emails sent to**: `customercare@bandmwaste.com;customercare@jwswaste.co.uk`

### 19 Flows Using Both Fields for Email Automation:

**Job Management & Booking Confirmations (5 flows):**
1. Booking_Confirmation_Email
2. RLCS_Booking_Confirmation_Email
3. Manage_Booking_Confirmation_Email_Subflow
4. Job_Organise_Collection
5. RLCS_Job_Organise_Collection

**Job Creation (5 flows):**
6. Create_Job
7. Create_RLCS_Job
8. Create_Mixed_Waste_Type_Job
9. Create_Mixed_Waste_Type_Job_RLCS
10. Domestic_Create_Job

**Job Changes (5 flows):**
11. Exchange_Job
12. Exchange_RLCS_Job
13. Cancel_Flow
14. Cancel_RLCS_Job
15. Cancel_Collection_Flow

**Invoicing & Payment (4 flows):**
16. Invoice_Action_Send_Invoice
17. X2_0_Email_Invoice_Opero_Doc
18. Job_Pay
19. Job_Pay_Supplier

### Usage Statistics:

- **232 out of 1,947 Suppliers** (11.9%) have Other_Emails__c populated
- These 232 Suppliers receive automated emails to **BOTH** email addresses
- 1,715 Suppliers (88.1%) only receive emails to Sales_Email__c

**Field Usage Breakdown:**
- **215 Suppliers** (92.7%) use it for a **single email address**
- **17 Suppliers** (7.3%) use it for **multiple semicolon-separated emails**

### Who Manages Other_Emails__c Field:

**Profiles with Edit Access (32 total, same as Sales_Email__c):**

✅ **Finance Team** (Primary users - 76% of all changes):
- 1.0 Finance (6 active users) - 9 changes in last 180 days
- 1.0 Finance Manager (3 active users) - 20 changes
- 1.0 Management Accounts - 40 changes
- 1.0 Credit Control - 12 changes

✅ **Supply Chain Team:**
- 1.0 Supply Chain (2 active users) - 2 changes
- 1.0 Supply Chain Manager (1 user - Gareth)

✅ **Legacy Customer Service:**
- 1.0 Customer Service (CAN edit)
- 1.0 Customer Service Manager (CAN edit)

❌ **Modern Customer Service:**
- **2.0 Customer Service (CANNOT edit - read only)**

### Recent Activity (Last 180 Days):

| Profile | Changes to Other_Emails__c | % of Total |
|---------|---------------------------|------------|
| 1.0 Management Accounts | 40 | 44% |
| 1.0 Finance Manager | 20 | 22% |
| 1.0 Credit Control | 12 | 13% |
| 1.0 Finance | 9 | 10% |
| 2.0 - RLCS | 5 | 5% |
| System Administrator | 3 | 3% |
| 1.0 Supply Chain | 2 | 2% |

### Impact on Customer Service:

**Current Problem:**
- ✅ Customer Service CAN edit Sales_Email__c (primary recipient)
- ❌ Customer Service CANNOT edit Other_Emails__c (additional recipient)
- ⚠️ Other_Emails__c is HIDDEN on Accounting tab (not visible in main view)

**Common Scenarios Where This Causes Issues:**

1. **Supplier reports missing emails:**
   - CS checks Sales_Email__c - it's correct ✓
   - CS doesn't know Other_Emails__c exists (hidden on Accounting tab)
   - CS can't see that Other_Emails__c has an old/incorrect email
   - CS cannot fix it → Must escalate to Finance/Supply Chain

2. **Supplier requests multiple recipients:**
   - "Please send booking confirmations to both operations@supplier.com and accounts@supplier.com"
   - CS can only update Sales_Email__c (one address)
   - CS cannot add second address to Other_Emails__c
   - Must create ticket for Finance team

3. **Email bounces:**
   - Automated system sends to both Sales_Email__c and Other_Emails__c
   - One address bounces (in Other_Emails__c field)
   - CS receives complaint but cannot fix the bounced address

### Recommendation: Grant Customer Service Access to Other_Emails__c

**Why This is Critical:**

1. ✅ **Used in 19 automated email flows** - Not just a reference field, actively sends emails
2. ✅ **Customer Service handles email issues** - First line of contact when Suppliers report missing emails
3. ✅ **Consistency with Sales_Email__c** - Both fields work together, should both be editable
4. ✅ **12% of Suppliers depend on it** - 232 Suppliers have this populated and receive emails there
5. ✅ **Prevents escalations** - CS can resolve email issues without involving Finance/Supply Chain

**Recommended Actions:**

**Option A: Grant Access Only** (Quick fix)
- Update profile: Setup → Profiles → 2.0 Customer Service → Field Permissions → Other Emails → Edit ✓
- Field stays on Accounting tab (still hidden)

**Option B: Grant Access + Improve Visibility** (Recommended)
- Grant edit access via profile
- Move field to Account Information section (next to Sales_Email__c)
- Makes both email fields visible and manageable together
- Requires Lightning page edit

**Current Status**: ⚠️ **NOT IMPLEMENTED** - Other_Emails__c remains read-only and hidden for Customer Service

---

**Final Status**:
- ✅ Customer Service can now edit Sales_Email__c field on all Supplier accounts
- ⚠️ Customer Service CANNOT edit Other_Emails__c field (read-only access only)
- ⚠️ Decision pending on whether to grant access to Other_Emails__c field
