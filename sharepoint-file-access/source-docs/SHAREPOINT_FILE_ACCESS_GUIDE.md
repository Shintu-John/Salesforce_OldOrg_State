# SharePoint File Access & Navigation Guide

**Created:** 2025-10-07
**Last Updated:** 2025-10-07
**Org:** OldOrg
**Purpose:** Enable users to view/download files from SharePoint within Salesforce and navigate SharePoint folders

---

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Understanding External Files](#understanding-external-files)
3. [How to Make Files Viewable in Salesforce](#how-to-make-files-viewable-in-salesforce)
4. [How to Find Files in SharePoint](#how-to-find-files-in-sharepoint)
5. [SharePoint Folder Structure](#sharepoint-folder-structure)
6. [User Guide](#user-guide)
7. [Admin Configuration](#admin-configuration)
8. [Troubleshooting](#troubleshooting)

---

## Quick Reference

### Current Configuration

**SharePoint Site:** https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage

**External Data Source:**
- Name: `SharePoint_Salesforce_FS`
- ID: `0XCSj000000006TOAQ`
- Type: `ContentHubSharepointOffice365`
- Authentication: `NamedUser` (requires SharePoint permissions)

**File Retention Policy:**
- Customer Account files older than **730 days (2 years)** are automatically moved to SharePoint
- Moved daily at 1:00 AM UTC
- Original files deleted from Salesforce, replaced with external links

---

## Understanding External Files

### What Are External Files?

When you see a file in Salesforce with **0 bytes**, it's an **external link** to a file stored in SharePoint, not an empty file.

**Characteristics of External Files:**
- ContentSize = 0 bytes
- ExternalDataSourceId populated
- ExternalDocumentInfo1 contains SharePoint URL
- Cannot be downloaded directly from Salesforce (yet)

### Why Files Are Moved to SharePoint

**Business Reasons:**
- **Storage Optimization:** Reduce Salesforce storage costs
- **Long-term Archival:** Keep historical files accessible without consuming Salesforce storage
- **Compliance:** Maintain files beyond Salesforce retention limits

**Technical Process:**
- Automated batch runs daily at 1:00 AM UTC
- Files older than 2 years on Customer Accounts are moved
- External link created in Salesforce pointing to SharePoint
- Original file deleted from Salesforce

---

## How to Make Files Viewable in Salesforce

There are **two approaches** to enable file viewing within Salesforce:

### Option 1: Configure Salesforce Files Connect (Recommended)

**What is Files Connect?**
Salesforce Files Connect allows users to access external files (like SharePoint) directly from Salesforce UI without leaving the platform.

**Requirements:**
1. ✅ External Data Source configured (already exists: `SharePoint_Salesforce_FS`)
2. ✅ Named credentials for authentication
3. ⚠️ **User SharePoint permissions** - Each user needs SharePoint access
4. ⚠️ **External file preview enabled** in Salesforce

#### Steps to Enable Files Connect Preview

**Step 1: Verify External Data Source**
```
Setup → External Data Sources → SharePoint_Salesforce_FS
```

**Check that:**
- Type = `Salesforce Files Connect: SharePoint Online`
- Authentication configured
- Connection successful

**Step 2: Grant Users SharePoint Permissions**

Users must have:
- Access to SharePoint site: `recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage`
- Read permissions on `Shared Documents` library
- Valid Microsoft 365 license

**How to check/grant access:**
1. Go to SharePoint site
2. Site Permissions → Members
3. Add users who need file access
4. Assign "Read" or higher permissions

**Step 3: Enable File Preview in User Profile**

```
Setup → Users → [User] → Edit
```

Enable:
- ✅ Salesforce Files Connect
- ✅ View External Files

**Step 4: Configure File Component on Page Layouts**

Add the **Files** component to Account/Job/Order/Site page layouts:
1. Setup → Object Manager → Account → Page Layouts
2. Edit page layout
3. Ensure "Files" related list is visible
4. Save

**Step 5: Test File Access**

1. Navigate to an Account with external files
2. Click Files tab
3. External files should show with SharePoint icon
4. Click file to preview/download

#### Expected Behavior After Configuration

**Before:**
- User clicks file → Error or no response
- File shows 0 bytes
- Download fails

**After:**
- User clicks file → Opens in SharePoint preview
- File shows SharePoint icon
- Download button available
- File opens in browser or downloads

---

### Option 2: Add Direct SharePoint Link to Page Layout (Quick Fix)

If Files Connect setup is complex, add a direct link to SharePoint as a temporary solution.

#### Implementation Steps

**Step 1: Create Formula Field on Account**

```
Field Label: SharePoint Files Link
API Name: SharePoint_Files_Link__c
Type: Formula (Text)
Formula:
HYPERLINK(
  "https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Account/" &
  Sharepoint_Folder_Name__c,
  "View Files in SharePoint",
  "_blank"
)
```

**Step 2: Add Field to Page Layout**

1. Setup → Object Manager → Account → Page Layouts
2. Edit "Customer Account Layout"
3. Add "SharePoint Files Link" field
4. Place in "Files" section
5. Save

**Step 3: Test**

1. Open Account record
2. Click "View Files in SharePoint" link
3. SharePoint folder opens in new tab
4. Files are directly accessible

#### Pros & Cons

**Pros:**
- ✅ Quick to implement (5 minutes)
- ✅ No permission configuration needed
- ✅ Works immediately
- ✅ Users familiar with SharePoint navigate easily

**Cons:**
- ❌ Leaves Salesforce UI
- ❌ Not integrated experience
- ❌ Still requires SharePoint permissions
- ❌ Users must know SharePoint navigation

---

## How to Find Files in SharePoint

### Direct URL Method (Fastest)

**For a specific Account:**

**URL Pattern:**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Account/[Sharepoint_Folder_Name__c]/
```

**Example:**
```
Account: Gunite Eastern Ltd (0018e00000APPvzAAH)
Folder Name: Gunite Eastern Ltd - 0018e00000APPvzAAH

URL:
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Account/Gunite%20Eastern%20Ltd%20-%200018e00000APPvzAAH/
```

**How to get the URL:**
1. Open Account in Salesforce
2. Note the `Sharepoint_Folder_Name__c` field value
3. URL encode spaces and special characters:
   - Space → `%20`
   - & → `%26`
   - . → `.` (no encoding needed)
4. Build URL using pattern above

### Navigate from SharePoint Home

**Step 1: Access SharePoint Site**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage
```

**Step 2: Navigate to Shared Documents**
- Click "Shared Documents" in left navigation
- Or click "Documents" → "Shared Documents"

**Step 3: Browse Object Folders**

You'll see folders for each Salesforce object:
```
Shared Documents/
├── Account/
├── Job__c/
├── Order/
├── Site__c/
├── iparseio__ProcessedDocument__c/
├── File_Import__c/
└── iparseio__DocumentPage__c/
```

**Step 4: Find Specific Account Folder**

Click `Account/` folder, then:

**Option A - Search:**
- Use SharePoint search bar
- Search for Account name or ID
- Example: "Gunite Eastern Ltd" or "0018e00000APPvzAAH"

**Option B - Browse:**
- Folders are sorted alphabetically by Account name
- Scroll or use filter
- Find folder: `[Account Name] - [Account ID]`

**Step 5: Access Files**

Click folder to see all files for that Account.

---

## SharePoint Folder Structure

### Folder Naming Convention

**Format:**
```
[Object Name]/[Record Identifier]/[File Name]
```

**Examples:**

**Accounts:**
```
Account/Gunite Eastern Ltd - 0018e00000APPvzAAH/GUNITE (EASTERN) LIMITED Application Form 04.04.23.pdf
Account/1 Car 1 - 0012400001H3UrsAAF/Invoice_2023.pdf
```

**Jobs:**
```
Job__c/JOB-123456/Weighbridge Ticket.pdf
```

**Orders:**
```
Order/ORD-789/Order Confirmation.pdf
```

**Sites:**
```
Site__c/Preston Site - a0XSj000001ABC123/Site Inspection Report.pdf
```

### Finding Folder Name for Any Record

**Query in Salesforce (Dev Console):**

**For Account:**
```apex
Account acc = [SELECT Id, Name, Sharepoint_Folder_Name__c
               FROM Account
               WHERE Id = '0018e00000APPvzAAH'];
System.debug('Folder: ' + acc.Sharepoint_Folder_Name__c);
```

**For Job:**
```apex
Job__c job = [SELECT Id, Name FROM Job__c WHERE Id = 'a0dXXXXXXXXXXXX'];
System.debug('Folder: ' + job.Name);
```

**Via SOQL Query:**
```sql
-- Account
SELECT Id, Name, Sharepoint_Folder_Name__c
FROM Account
WHERE Id = '0018e00000APPvzAAH'

-- Job
SELECT Id, Name
FROM Job__c
WHERE Id = 'a0dXXXXXXXXXXXX'
```

### Folder Name Rules

**Characters Removed:**
- `*` (asterisk)
- `:` (colon)
- `<` `>` (angle brackets)
- `?` (question mark)
- `/` `\` (slashes)
- `|` (pipe)
- Tabs → converted to spaces

**Example:**
```
Original Account Name: "ABC/DEF Company: Special*Products?"
SharePoint Folder: "ABCDEF Company SpecialProducts - 0018e00000ABCDEFG"
```

---

## User Guide

### For End Users: How to Access Old Files

#### Scenario: You need a file older than 2 years

**Step 1: Check if File is External**

Open the Account/Job/Order/Site record in Salesforce:
1. Go to Files tab
2. Look for files with 0 bytes
3. These are external files stored in SharePoint

**Step 2: Get SharePoint Folder Name**

On the Account record, find the field:
- **Sharepoint_Folder_Name__c** (usually: `[Account Name] - [Account ID]`)

Example: `Gunite Eastern Ltd - 0018e00000APPvzAAH`

**Step 3: Access SharePoint**

**Method A - Direct URL (Fastest):**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Account/[Folder Name]/
```

Replace `[Folder Name]` with the value from Step 2 (use `%20` for spaces).

**Method B - Navigate from SharePoint:**
1. Go to: https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage
2. Click "Shared Documents"
3. Click "Account" folder
4. Find your Account folder (alphabetical order)
5. Access files

**Step 4: Download File**

In SharePoint:
1. Find the file you need
2. Right-click → Download
3. Or click file → Download button

### For Power Users: Bookmarklet (Optional)

Create a browser bookmarklet to jump directly from Salesforce to SharePoint:

**JavaScript:**
```javascript
javascript:(function(){
  var folder = document.querySelector('[data-field-api-name="Sharepoint_Folder_Name__c"]');
  if(folder) {
    var name = encodeURIComponent(folder.textContent.trim());
    var url = 'https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Account/' + name + '/';
    window.open(url, '_blank');
  } else {
    alert('Sharepoint_Folder_Name__c field not found on page');
  }
})();
```

**How to Use:**
1. Create browser bookmark
2. Set URL to JavaScript above
3. Name it "Open SharePoint Folder"
4. On any Account page, click bookmark → Opens SharePoint folder

---

## Admin Configuration

### Current Configuration Details

**External Data Source:**
```
Name: SharePoint_Salesforce_FS
ID: 0XCSj000000006TOAQ
Type: ContentHubSharepointOffice365
Principal Type: NamedUser
Endpoint: (configured in Named Credential)
```

**SharePoint Configuration (Custom Setting):**
```
Object: SharePointConfiguration__c
File_Path__c: https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents
Path__c: /sites/SalesforceFileStorage
ExternalDataSourceId__c: 0XCSj000000006TOAQ
Delete_File_From_Salesforce__c: true
```

### Retention Rules

**Active Rules (7 total):**

| Rule Name | Object | Age Threshold | Criteria |
|-----------|--------|---------------|----------|
| Client Account Retention Rule | Account | 730 days | RecordType = 'Customer' |
| Client Account Job Retention Rule | Job__c | 730 days | Account RecordType = 'Customer' |
| Client Account Order Retention Rule | Order | 730 days | Account RecordType = 'Customer' |
| Client Account Site Retention Rule | Site__c | 730 days | Account RecordType = 'Customer' |
| Processed Document Retention Rule | ProcessedDocument | 60 days | All records |
| File Import Retention Rule | File_Import__c | 60 days | All records |
| Document Page Retention Rule | DocumentPage | 60 days | All records |

**To modify retention rules:**
```
Setup → Custom Settings → SharePoint Retention Rule → Manage
```

### Scheduled Job

**Job Name:** Sharepoint_SyncBatch at 1AM

**Schedule:** Daily at 1:00 AM UTC (0 0 1 ? * 1,2,3,4,5,6,7)

**To modify schedule:**
1. Setup → Apex Classes → Sharepoint_SyncBatch
2. View scheduled jobs
3. Delete and reschedule if needed

**Or via Developer Console:**
```apex
// Abort current job
System.abortJob('08eSj000008RF1cIAG');

// Reschedule
System.schedule('Sharepoint_SyncBatch at 1AM',
  '0 0 1 ? * 1,2,3,4,5,6,7',
  new Sharepoint_SyncBatch()
);
```

---

## Troubleshooting

### Issue 1: User Cannot Access SharePoint Files

**Symptoms:**
- User clicks SharePoint link → Access denied
- SharePoint folder shows "You need permission"

**Cause:** User doesn't have SharePoint permissions

**Solution:**
1. Go to SharePoint site as admin
2. Site Settings → Site Permissions
3. Grant user "Read" access to site
4. Specifically grant access to "Shared Documents" library

---

### Issue 2: Files Don't Preview in Salesforce

**Symptoms:**
- External files show 0 bytes
- No preview available
- Download fails

**Cause:** Files Connect not configured or user not authenticated

**Solutions:**

**A) Check External Data Source Connection:**
```
Setup → External Data Sources → SharePoint_Salesforce_FS → Validate and Sync
```

**B) Check User Permissions:**
```
Setup → Users → [User] → Permission Sets
```
Ensure user has:
- Salesforce Files Connect permission
- View External Files permission

**C) Re-authenticate to SharePoint:**
1. User logs out of Salesforce
2. User logs out of SharePoint
3. User logs back into Salesforce
4. When accessing external file, will prompt for SharePoint authentication

---

### Issue 3: Cannot Find Account Folder in SharePoint

**Symptoms:**
- SharePoint folder doesn't exist for Account
- Search returns no results

**Possible Causes & Solutions:**

**A) No files have been moved yet**
- Files only moved after 730 days
- Check Account creation date and file upload dates
- Query: `SELECT CreatedDate FROM ContentVersion WHERE ContentDocumentId IN (SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = 'ACCOUNT_ID')`

**B) Folder name contains special characters**
- SharePoint removes: `* : < > ? / \ |`
- Search using simplified name without special characters

**C) Files failed to sync**
- Check SharePoint sync logs:
  ```sql
  SELECT Id, CV_Id__c, Error_Message__c, CreatedDate
  FROM SharePoint_Log__c
  WHERE CreatedDate >= LAST_N_DAYS:7
  ORDER BY CreatedDate DESC
  ```

---

### Issue 4: File Moved to SharePoint But Link Doesn't Work

**Symptoms:**
- External file exists in Salesforce (0 bytes)
- ExternalDocumentInfo1 URL returns 404
- SharePoint folder exists but file missing

**Cause:** Upload failed but external link was created

**Solution:**

**Step 1: Check SharePoint Logs**
```sql
SELECT Id, CV_Id__c, Error_Message__c
FROM SharePoint_Log__c
WHERE CV_Id__c = 'CONTENTVERSION_ID'
```

**Step 2: If Error Found**
- Common errors:
  - "Exceeded max size limit" → File too large for SharePoint API
  - "Read timed out" → Network issue during upload
  - "Unexpected character" → JSON parsing error

**Step 3: Re-upload Manually**
1. Find original file backup (if available)
2. Upload directly to SharePoint folder
3. Update ContentVersion.ExternalDocumentInfo1 with correct URL

---

### Issue 5: Multiple Accounts Share Same Folder Name

**Symptoms:**
- Two Accounts with same name
- SharePoint folder collision

**Solution:**

Folder names include Account ID to prevent collisions:
```
Account 1: "ABC Company - 0018e00000AAAAAAA"
Account 2: "ABC Company - 0018e00000BBBBBBB"
```

If collision occurs:
1. Check Sharepoint_Folder_Name__c field on Account
2. Verify folder limit counter in Retention Rule
3. Batch adds suffix if needed: "ABC Company-1", "ABC Company-2"

---

## Appendices

### A. Useful Queries

**Find all external files for an Account:**
```sql
SELECT Id, Title, ContentSize, ExternalDocumentInfo1,
       ExternalDataSourceId, CreatedDate
FROM ContentVersion
WHERE IsLatest = true
  AND ContentDocumentId IN (
    SELECT ContentDocumentId
    FROM ContentDocumentLink
    WHERE LinkedEntityId = '0018e00000APPvzAAH'
  )
  AND ExternalDataSourceId = '0XCSj000000006TOAQ'
```

**Find Accounts with external files:**
```sql
SELECT LinkedEntityId, COUNT(Id)
FROM ContentDocumentLink
WHERE ContentDocument.LatestPublishedVersion.ExternalDataSourceId = '0XCSj000000006TOAQ'
  AND LinkedEntityId LIKE '001%'
GROUP BY LinkedEntityId
```

**Find files eligible for archival (older than 730 days):**
```sql
SELECT ContentDocument.Title, ContentDocument.ContentSize,
       ContentDocument.CreatedDate, LinkedEntityId
FROM ContentDocumentLink
WHERE LinkedEntityId IN (
    SELECT Id FROM Account WHERE RecordType.Name = 'Customer'
  )
  AND ContentDocument.LatestPublishedVersion.ExternalDataSourceId = null
  AND ContentDocument.LatestPublishedVersion.CreatedDate < LAST_N_DAYS:730
```

### B. SharePoint Direct Links

**Main SharePoint Site:**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage
```

**Shared Documents Library:**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents
```

**Account Folders:**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Account/
```

**Job Folders:**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Job__c/
```

**Order Folders:**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Order/
```

**Site Folders:**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Site__c/
```

### C. File Access Checklist for New Users

When onboarding new users who need file access:

- [ ] User has Microsoft 365 license
- [ ] User added to SharePoint site members
- [ ] User granted "Read" permission on Shared Documents
- [ ] User has Salesforce license with Files permission
- [ ] User profile enables "View External Files"
- [ ] User tested accessing external file from Account
- [ ] User bookmarked SharePoint site for easy access
- [ ] User trained on folder navigation
- [ ] User knows to contact admin if "Access Denied"

---

**Last Updated:** 2025-10-07
**Maintained By:** System Admin
**Related Docs:** [SHAREPOINT_FILE_SYNC_INVESTIGATION.md](SHAREPOINT_FILE_SYNC_INVESTIGATION.md)
