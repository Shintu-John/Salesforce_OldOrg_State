# Dashboard Access Request - R&L SLT Update

**Date**: 2025-10-08
**Org**: OldOrg (Current Production)
**Status**: ⏳ **PENDING - Waiting for Lucas to make folder public**

---

## Request Details

**Requesters**:
- Nikesh Jhala
- Stacey

**Dashboard**:
- **Title**: R&L SLT Update
- **Dashboard ID**: 01ZSj000001LczNMAS
- **URL**: https://recyclinglives.lightning.force.com/lightning/r/Dashboard/01ZSj000001LczNMAS/view?queryScope=userFolders

---

## Issue Identified

**Problem**: Admin cannot share the dashboard

**Root Cause**:
- Dashboard is in a **private folder**: "RLS) Lucas Hargreaves Dashboards"
- Folder ID: 00lSj000001K6zxIAC
- Folder Access Type: **Hidden** (private)
- Created by: Glen Bagshaw
- Last Modified by: Lucas Hargreaves

**Why Admin Can't Share**:
- Private folders (AccessType = "Hidden") don't allow sharing individual dashboards
- Only the folder owner can see and access the dashboards
- Sharing options are not available for dashboards in private folders

---

## Solution Approach

### Step 1: Lucas Makes Folder Public ⏳ (In Progress)

**Action**: Lucas Hargreaves to change folder from "Hidden" to "Public" or "Shared"

**How Lucas Can Do This**:
1. Go to **Dashboards** tab in Salesforce
2. Find folder: "RLS) Lucas Hargreaves Dashboards"
3. Click on the folder dropdown menu
4. Select **Share**
5. Change folder access from "Hidden" to:
   - **Public** (everyone can see), OR
   - **Shared** (specific people can see)
6. Click **Save**

**Status**: ⏳ Request sent to Lucas

---

### Step 2: Share Folder with Users (Pending)

**Once Lucas makes the folder public**, admin (Shintu) will:

1. Go to **Dashboards** tab
2. Navigate to "RLS) Lucas Hargreaves Dashboards" folder
3. Click **Share**
4. Add users with Viewer access:
   - Nikesh Jhala - Viewer
   - Stacey - Viewer
5. Click **Share**

---

## Technical Details

**Dashboard Query Results**:
```sql
SELECT Id, Title, FolderId, Folder.Name, Folder.Type, Folder.AccessType,
       CreatedBy.Name, LastModifiedBy.Name
FROM Dashboard
WHERE Id = '01ZSj000001LczNMAS'
```

| Field | Value |
|-------|-------|
| ID | 01ZSj000001LczNMAS |
| Title | R&L SLT Update |
| FolderId | 00lSj000001K6zxIAC |
| Folder.Name | RLS) Lucas Hargreaves Dashboards |
| Folder.Type | Dashboard |
| **Folder.AccessType** | **Hidden** (Private) |
| CreatedBy.Name | Lucas Hargreaves |
| LastModifiedBy.Name | Lucas Hargreaves |

**Folder Query Results**:
```sql
SELECT Id, Name, Type, AccessType, DeveloperName, CreatedBy.Name
FROM Folder
WHERE Id = '00lSj000001K6zxIAC'
```

| Field | Value |
|-------|-------|
| ID | 00lSj000001K6zxIAC |
| Name | RLS) Lucas Hargreaves Dashboards |
| Type | Dashboard |
| **AccessType** | **Hidden** |
| DeveloperName | RLSLucasHargreavesDashboards |
| CreatedBy.Name | Glen Bagshaw |

---

## Alternative Solutions (Not Chosen)

### Option 1: Clone Dashboard to Shared Folder
- **Pros**: Quick fix, doesn't require Lucas
- **Cons**: Creates duplicate dashboard, need to maintain 2 copies
- **Decision**: Not chosen - prefer to keep single source

### Option 2: Admin Changes Folder via API
- **Pros**: Can be done without Lucas
- **Cons**: Affects all dashboards in Lucas's folder, requires API call
- **Decision**: Not chosen - better to have folder owner manage access

### Option 3: Move Dashboard to Different Folder
- **Pros**: Dashboard moves to shared location
- **Cons**: Removes from Lucas's folder structure
- **Decision**: Not chosen - Lucas should maintain folder organization

---

## Next Steps

1. ⏳ **Wait for Lucas** to make folder public/shared
2. **Admin (Shintu)** shares folder with:
   - Nikesh Jhala (Viewer)
   - Stacey (Viewer)
3. **Verify access** by asking users to confirm they can see the dashboard
4. **Close ticket**

---

## Contact Information

**Requesters**:
- Nikesh Jhala
- Stacey

**Folder Owner**:
- Lucas Hargreaves

**Admin**:
- Shintu John (shintu.john@recyclinglives-services.com)

**Org**:
- OldOrg (recyclinglives.my.salesforce.com)

---

## Reference Links

- Dashboard URL: https://recyclinglives.lightning.force.com/lightning/r/Dashboard/01ZSj000001LczNMAS/view?queryScope=userFolders
- Salesforce Help: [Sharing Dashboards and Reports](https://help.salesforce.com/s/articleView?id=sf.analytics_share_dashboard_report.htm)

---

**STATUS**: ⏳ Waiting for Lucas to make folder public, then admin will share with users

**Last Updated**: 2025-10-08
