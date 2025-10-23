# SharePoint File Sync Investigation - Account File Download Issue

**Date:** 2025-10-07
**Reported By:** Shintu John (Glen Bagshaw login)
**Affected Org:** OldOrg
**Status:** ✅ Resolved

---

## Table of Contents

1. [Issue Summary](#issue-summary)
2. [Investigation Process](#investigation-process)
3. [Root Cause Analysis](#root-cause-analysis)
4. [SharePoint Sync Batch Process](#sharepoint-sync-batch-process)
5. [Solutions & Resolution](#solutions--resolution)
6. [Technical Details](#technical-details)
7. [Key Learnings](#key-learnings)
8. [Related Files](#related-files)
9. [Recommendations](#recommendations)

---

## Issue Summary

### Problem Statement

**Date Reported:** 2025-10-07, 16:04:14 UTC
**Reported By:** Shintu John (System Admin)
**User Context:** Logged in as Glen Bagshaw
**Affected Record:** Account "Gunite Eastern Ltd" (0018e00000APPvzAAH)
**Issue:** Unable to download a PDF file from the Files section of an Account record

### Initial Observations

- File name: "GUNITE (EASTERN) LIMITED Application Form 04.04.23.pdf"
- File appeared in Files section
- Download attempt failed
- File showed "Content modified by Glen Bagshaw, today" (October 7, 2025)
- User did not manually modify the file

### Business Impact

- User unable to access customer application form
- Required manual navigation to SharePoint to retrieve file
- Confusion about file modification tracking
- Need to understand automated processes for file management

---

## Investigation Process

### Step 1: Initial File Metadata Query

**Query:**
```sql
SELECT Id, Title, VersionNumber, ContentSize, FileType,
       CreatedDate, CreatedBy.Name,
       LastModifiedDate, LastModifiedBy.Name,
       ContentModifiedDate, ContentModifiedBy.Name
FROM ContentVersion
WHERE ContentDocumentId = '069Sj00000DlcSFIAZ'
```

**Results:**
```
ContentVersion ID: 068Sj00000DnLohIAF
Title: GUNITE (EASTERN) LIMITED Application Form 04.04.23.pdf
VersionNumber: 1
ContentSize: 0 bytes ⚠️
FileType: PDF
CreatedDate: 2025-04-04T00:00:12.000+0000
CreatedBy: Vesium Gerry Gregoire
LastModifiedDate: 2025-10-07T16:04:14.000+0000
LastModifiedBy: Glen Bagshaw
ContentModifiedDate: 2025-10-07T16:04:14.000+0000
ContentModifiedBy: Glen Bagshaw
```

**Key Finding:** ContentSize = 0 bytes (file appears empty)

### Step 2: Checking File Origin and Source

**Query:**
```sql
SELECT Id, Title, VersionData, CreatedDate, CreatedBy.Name,
       FirstPublishLocationId, Origin
FROM ContentVersion
WHERE Id = '068Sj00000DnLohIAF'
```

**Results:**
```
Origin: H (Chatter/API upload)
FirstPublishLocationId: 0018e00000APPvzAAH (directly published to Account)
```

### Step 3: Login History Analysis

**Query:**
```sql
SELECT Id, Application, LoginTime, UserId, Status
FROM LoginHistory
WHERE UserId = '0054H000005dwlOQAQ'
  AND LoginTime >= 2025-04-03T00:00:00.000Z
  AND LoginTime <= 2025-04-05T00:00:00.000Z
```

**Results:** No login records for Vesium Gerry Gregoire on April 4, 2025

**Conclusion:** File was created by an automated process, not manual user action

### Step 4: Scheduled Job Discovery

**Query:**
```sql
SELECT Id, CronJobDetail.Name, State, CronExpression,
       NextFireTime, PreviousFireTime, CreatedBy.Name
FROM CronTrigger
WHERE State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
```

**Critical Finding:**
```
Job Name: Sharepoint_SyncBatch at 1AM
Created By: Vesium Gerry Gregoire
Cron Expression: 0 0 1 ? * 1,2,3,4,5,6,7
Runs: Daily at 1:00 AM UTC (midnight local time)
```

### Step 5: External Data Source Discovery

**Query:**
```sql
SELECT Id, ExternalDataSourceId, ExternalDocumentInfo1,
       ExternalDocumentInfo2, ContentUrl, External_ID__c
FROM ContentVersion
WHERE Id = '068Sj00000DnLohIAF'
```

**Results:**
```
ExternalDataSourceId: 0XCSj000000006TOAQ
ExternalDocumentInfo1: https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Forms/DispForm.aspx?ID=13526753
ExternalDocumentInfo2: item:L3NpdGVzL1NhbGVzZm9yY2VGaWxlU3RvcmFnZQ==:e4652ad0-328f-478f-8e23-7a1bacdf45dd:4d96b835-ce04-435b-90a1-03a8940091d3:0e4d06a5-83f0-4bcc-9e93-79d5d22425d0
External_ID__c: 0688e0000077spyAAA (original ContentVersion ID)
```

**BREAKTHROUGH:** This is a SharePoint external link file, not an empty file!

---

## Root Cause Analysis

### The Real Story

1. **Original Upload:** A PDF file was manually uploaded to the Account at some point before April 4, 2025
2. **Retention Rule Triggered:** On April 4, 2025 at 00:00:12 UTC, the SharePoint Sync Batch detected this file was older than 730 days (2 years)
3. **File Moved to SharePoint:** The batch uploaded the file to SharePoint successfully
4. **External Link Created:** A new ContentVersion was created as a pointer to the SharePoint file
5. **Original Deleted:** The original ContentVersion with actual file data was deleted from Salesforce
6. **User Access Attempt:** On October 7, 2025, Glen Bagshaw attempted to download the file, which triggered the "content modified" timestamp

### Why File Shows 0 Bytes

The ContentVersion in Salesforce is an **external link**, not the actual file. Key fields:
- `VersionData = null` (no binary data)
- `ContentSize = 0`
- `ExternalDataSourceId` points to SharePoint
- `ContentLocation = 'E'` (External)
- `Origin = 'H'` (set by batch process)

### Why Modified Date Updated

The "content modified by Glen Bagshaw today" timestamp occurred because:
- Glen accessed/viewed the file record
- Salesforce logged this as a content access event
- No actual content was modified

---

## SharePoint Sync Batch Process

### Process Overview

**File:** [Sharepoint_SyncBatch.cls](../force-app/main/default/classes/Sharepoint_SyncBatch.cls)

**Schedule:** Daily at 1:00 AM UTC (0 0 1 ? * 1,2,3,4,5,6,7)

**Created By:** Vesium Gerry Gregoire

### How It Works

1. **Query Active Retention Rules**
   ```apex
   SELECT Id, Name, Object_API_Name__c, File_Where_Clause__c,
          Object_Where_Clause__c
   FROM SharePoint_Retention_Rule__c
   WHERE Active__c = true
   ```

2. **For Each Rule:**
   - Find files matching criteria (age, object type)
   - Upload to SharePoint folder structure
   - Create external link ContentVersion
   - Delete original file from Salesforce

3. **Folder Structure in SharePoint:**
   ```
   [Object]/[RecordName]/[FileName]
   Example: Account/Gunite Eastern Ltd - 0018e00000APPvzAAH/GUNITE (EASTERN) LIMITED Application Form 04.04.23.pdf
   ```

### Active Retention Rules (OldOrg)

**Query:**
```sql
SELECT Id, Name, Active__c, Object_API_Name__c,
       File_Where_Clause__c, Object_Where_Clause__c,
       Folder_Name_Field__c
FROM SharePoint_Retention_Rule__c
WHERE Active__c = true
```

**Results (7 Active Rules):**

| Rule Name | Object | File Criteria | Object Criteria |
|-----------|--------|---------------|-----------------|
| Client Account Retention Rule | Account | Files older than 730 days | RecordType.Name = 'Customer' |
| Client Account Job Retention Rule | Job__c | Files older than 730 days | Account__r.RecordType.Name = 'Customer' |
| Client Account Order Retention Rule | Order | Files older than 730 days | Account.RecordType.Name = 'Customer' |
| Client Account Site Retention Rule | Site__c | Files older than 730 days | Account__r.RecordType.Name = 'Customer' |
| Processed Document Retention Rule | iparseio__ProcessedDocument__c | Files older than 60 days | CreatedDate != null |
| File Import Retention Rule | File_Import__c | Files older than 60 days | CreatedDate != null |
| Document Page Retention Rule | iparseio__DocumentPage__c | Files older than 60 days | CreatedDate != null |

### Code Logic (Key Sections)

**External Link Creation (lines 93-109):**
```apex
ContentVersion cv = new ContentVersion();
for(String fName : fieldMap.keySet()){
    if(fieldMap.get(fName).getDescribe().isUpdateable()){
        cv.put(fName, cvRec.get(fName));
    }
}
cv.External_ID__c = cvRec.Id;
cv.VersionData = null;  // ⬅️ No binary data
cv.PathOnClient = cvRec.PathOnClient;
cv.ContentUrl = null;
cv.ExternalDataSourceId = config.ExternalDataSourceId__c;
cv.ExternalDocumentInfo1 = config.File_Path__c + '/Forms/DispForm.aspx?ID=' + uniqueId;
cv.ExternalDocumentInfo2 = buildIdentifier(uniqueId);
cv.ContentLocation = 'E';  // ⬅️ External
cv.FirstPublishLocationId = recordId;
cv.Origin = 'H';  // ⬅️ Batch process origin
insert cv;
```

**File Deletion (lines 112-124):**
```apex
if(processToDeleteDocument && config.Delete_File_From_Salesforce__c == true){
    delete rec;  // Delete ContentDocumentLink

    // Check if safe to delete ContentDocument
    List<ContentDocumentLink> cdLinks = [
        SELECT Id, LinkedEntityId, IsDeleted
        FROM ContentDocumentLink
        WHERE ContentDocumentId = :cvRec.ContentDocumentId
    ];

    if(deleteCV){
        delete new ContentDocument(Id = cvRec.ContentDocumentId);
    }
}
```

---

## Solutions & Resolution

### Solution 1: Access via SharePoint (✅ USED)

**SharePoint URL:**
```
https://recyclinglivesservices.sharepoint.com/sites/SalesforceFileStorage/Shared%20Documents/Forms/DispForm.aspx?ID=13526753
```

**Folder Location:**
```
Account/Gunite Eastern Ltd - 0018e00000APPvzAAH/
```

**Result:** ✅ User successfully downloaded file from SharePoint

### Solution 2: Configure External Data Source (Future Enhancement)

**External Data Source ID:** 0XCSj000000006TOAQ

**Configuration Required:**
1. Verify SharePoint external data source connection
2. Ensure user permissions for external file access
3. Test external file preview/download in Salesforce UI

### Solution 3: Restore from Backup (Not Needed)

If file was not in SharePoint:
1. Query original ContentVersion: 0688e0000077spyAAA
2. Check backup systems
3. Restore from backup if available

---

## Technical Details

### SharePoint Configuration

**Custom Object:** SharePointConfiguration__c (Org Defaults)

**Key Fields:**
- `ExternalDataSourceId__c`: External data source ID
- `File_Path__c`: SharePoint site path
- `Path__c`: Base64 encoded path
- `UUId__c`: SharePoint site UUID
- `UUID_File__c`: SharePoint file UUID
- `Delete_File_From_Salesforce__c`: Boolean flag

### Account Details

**Query:**
```sql
SELECT Id, Name, Type, RecordType.Name, Sharepoint_Folder_Name__c
FROM Account
WHERE Id = '0018e00000APPvzAAH'
```

**Results:**
```
Name: Gunite Eastern Ltd
Type: Customer
RecordType: Customer
Sharepoint_Folder_Name__c: Gunite Eastern Ltd - 0018e00000APPvzAAH
Created: 2023-03-29 by Phillip Ryan
Last Modified: 2025-09-26
```

### File Sharing Details

**Query:**
```sql
SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility
FROM ContentDocumentLink
WHERE ContentDocumentId = '069Sj00000DlcSFIAZ'
```

**Results:**
- Linked to Account: 0018e00000APPvzAAH (All Users, Inferred)
- Linked to Owner: Cristina Belso (All Users, Inferred)

### SharePoint Logs

**Query:**
```sql
SELECT Id, CV_Id__c, Error_Message__c, CreatedDate
FROM SharePoint_Log__c
WHERE CreatedDate >= 2025-04-03T00:00:00.000Z
  AND CreatedDate <= 2025-04-05T00:00:00.000Z
```

**Results:** No errors logged for this specific file (successful upload)

**Other Errors During Same Period:**
- Several "Exceeded max size limit of 12000000" errors
- Multiple "Unexpected character" JSON parsing errors
- File upload timeouts

---

## Key Learnings

### 1. External Link Files Appear Empty

Files with 0 bytes and `ExternalDataSourceId` are **external links**, not empty files:
- Check `ExternalDataSourceId` field
- Check `ExternalDocumentInfo1` for URL
- Check `External_ID__c` for original file reference
- Check `ContentLocation = 'E'`

### 2. File Retention Automation

The SharePoint Sync Batch automatically moves old files:
- Runs daily at 1:00 AM UTC
- Uses retention rules to determine which files
- Creates external links in Salesforce
- Deletes original files to save storage
- **730 days (2 years)** is standard retention for Customer records

### 3. "Modified Today" Misleading

ContentVersion `LastModifiedDate` updates when:
- User views the file record
- User attempts to download
- File metadata is accessed
- **Does NOT mean content was edited**

### 4. User Context in Automation

Files created by scheduled jobs:
- Show user who scheduled the job as creator
- No login history for that user at creation time
- `Origin = 'H'` indicates programmatic creation
- Timestamp at exact midnight suggests scheduled process

### 5. Investigation Process

**Effective Investigation Steps:**
1. Check ContentVersion metadata (size, origin, dates)
2. Check for ExternalDataSourceId (external link indicator)
3. Query login history for "creator" at creation time
4. Search for scheduled jobs around creation time
5. Check for Apex batch processes
6. Review SharePoint integration logs

### 6. SharePoint Integration Architecture

**Components:**
- Apex Batch Class: `Sharepoint_SyncBatch.cls`
- Retention Rules: `SharePoint_Retention_Rule__c`
- Configuration: `SharePointConfiguration__c`
- Logs: `SharePoint_Log__c`
- API Integration: `SharePointApi` class (referenced)
- External Data Source: Configured in Setup

---

## Related Files

### Apex Classes
- [Sharepoint_SyncBatch.cls](../force-app/main/default/classes/Sharepoint_SyncBatch.cls) - Main batch process
- [Sharepoint_SyncBatchTest.cls](../force-app/main/default/classes/Sharepoint_SyncBatchTest.cls) - Test class
- [SharePointApi.cls](../force-app/main/default/classes/) - API integration (referenced, not examined)

### Custom Objects
- `SharePoint_Retention_Rule__c` - Defines retention policies
- `SharePointConfiguration__c` - Org-level configuration
- `SharePoint_Log__c` - Error logging

### Standard Objects Referenced
- `ContentVersion` - File versions
- `ContentDocument` - File documents
- `ContentDocumentLink` - File-to-record links
- `Account` - Customer records

### Triggers
- `ContentVersionTrigger` (3 active triggers found on ContentVersion)
- `ContentVersion_Trigger`
- `ContentVersionTriggerHandler`

---

## Recommendations

### 1. User Training & Documentation

**Action:** Create user documentation explaining:
- Files older than 2 years are automatically moved to SharePoint
- How to access SharePoint files
- Why files show 0 bytes
- How to identify external link files

**Priority:** High
**Owner:** System Admin / Training Team

### 2. External Data Source Configuration

**Action:** Configure and test external file access in Salesforce UI
- Enable seamless file preview/download from Salesforce
- Verify user permissions
- Test with sample external files

**Priority:** Medium
**Owner:** System Admin

### 3. Retention Rule Review

**Action:** Review 730-day retention policy with business
- Confirm 2-year retention meets compliance requirements
- Consider different retention periods for different file types
- Document approved retention policies

**Priority:** Medium
**Owner:** Business Owner / Compliance Team

### 4. SharePoint Log Monitoring

**Action:** Regular review of SharePoint sync errors
- Several file size limit errors detected
- JSON parsing errors occurring
- Set up alerts for critical failures

**Priority:** Medium
**Owner:** System Admin

### 5. ContentVersion Metadata Display

**Action:** Customize Files related list to show:
- External file indicator
- SharePoint link (if available)
- ContentSize with explanation
- Clear visual distinction for external files

**Priority:** Low
**Owner:** Admin / Developer

### 6. Error Handling Improvements

**Action:** Enhance SharePoint batch error handling
- Better logging for parsing errors
- Retry logic for timeouts
- Alert admin for repeated failures
- File size pre-check before upload

**Priority:** Low
**Owner:** Developer

---

## Appendices

### A. Account Record Details

```
Account ID: 0018e00000APPvzAAH
Account Name: Gunite Eastern Ltd
Record Type: Customer
Created Date: 2023-03-29T15:48:28.000+0000
Created By: Phillip Ryan
Last Modified: 2025-09-26T07:56:36.000+0000
SharePoint Folder: Gunite Eastern Ltd - 0018e00000APPvzAAH
```

### B. ContentVersion Timeline

```
Original File (0688e0000077spyAAA):
  - Created: Unknown (before April 4, 2023)
  - Deleted: April 4, 2025 by SharePoint Sync Batch

External Link File (068Sj00000DnLohIAF):
  - Created: 2025-04-04T00:00:12.000+0000
  - Created By: Vesium Gerry Gregoire (automated)
  - Last Accessed: 2025-10-07T16:04:14.000+0000
  - Accessed By: Glen Bagshaw
  - SharePoint ID: 13526753
```

### C. Scheduled Job Details

```
Job Name: Sharepoint_SyncBatch at 1AM
Cron Trigger ID: 08eSj000008RF1cIAG
Cron Expression: 0 0 1 ? * 1,2,3,4,5,6,7
Schedule: Daily at 1:00 AM UTC
State: WAITING
Next Fire Time: 2025-10-08T00:00:00.000+0000
Previous Fire Time: 2025-10-07T00:00:01.034+0000
Created By: Vesium Gerry Gregoire (0054H000005dwlOQAQ)
```

### D. Retention Rule Applied

```
Rule ID: a07Sj00000FejzCIAR
Rule Name: Client Account Retention Rule
Active: Yes
Object: Account
File Criteria: CreatedDate < LAST_N_DAYS:730
Object Criteria: RecordType.Name = 'Customer'
Folder Field: Sharepoint_Folder_Name__c
```

### E. Useful Queries

**Find all external link files on an Account:**
```sql
SELECT Id, Title, ContentSize, ExternalDataSourceId, ExternalDocumentInfo1
FROM ContentVersion
WHERE IsLatest = true
  AND ContentDocumentId IN (
    SELECT ContentDocumentId
    FROM ContentDocumentLink
    WHERE LinkedEntityId = '0018e00000APPvzAAH'
  )
  AND ExternalDataSourceId != null
```

**Find files eligible for SharePoint sync:**
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

**Check SharePoint sync errors in last 7 days:**
```sql
SELECT Id, CV_Id__c, Error_Message__c, CreatedDate
FROM SharePoint_Log__c
WHERE CreatedDate >= LAST_N_DAYS:7
ORDER BY CreatedDate DESC
```

---

**Resolution Date:** 2025-10-07
**Resolved By:** Claude (System Admin Investigation)
**Status:** ✅ Resolved - User successfully accessed file via SharePoint
**Follow-up:** User training and external data source configuration recommended
