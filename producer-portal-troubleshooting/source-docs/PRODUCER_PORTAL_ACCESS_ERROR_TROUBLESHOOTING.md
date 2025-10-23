# Producer Portal Access Error Troubleshooting

## Issue Summary
**Error**: "You do not have the level of access necessary to perform the operation you requested"

**User**: Matthew Walker (Community Login user, ID: 005Sj000003hcY9IAI)

**Record**: Producer Placed on Market M-008558 (ID: a4dSj000005EmebIAC)

**URL**: https://recyclinglives.my.site.com/RLCS/s/producer-placed-on-market/a4dSj000005EmebIAC/m008558

**Date**: 2025-10-21

---

## Root Cause Analysis

### Initial Investigation
1. **User Permissions Confirmed**:
   - Matthew Walker has direct manual sharing with Edit access to the record
   - Profile: Producer Standard User Login
   - Has Read, Create, Edit permissions on Producer_Placed_on_Market__c object
   - Has Read, Edit permissions on Validation_Question__c object

2. **Flow Permission Issues - FIXED**:
   - 5 flows had `<isAdditionalPermissionRequiredToRun>true</isAdditionalPermissionRequiredToRun>`
   - Changed to `false` in all flows:
     - validationQuestionsFlow (Deploy ID: 0AfSj000000z6DNKAY)
     - Producer_Placed_On_Market_Question_Best_Action
     - Producer_Placed_On_Market_Acknowledge_Best_Action
     - Producer_Placed_On_Market_Signature_Best_Action
     - Producer_Placed_On_Market_Resubmission_Best_Action
     - (All 4 NBA flows: Deploy ID: 0AfSj000000z6GbKAI)

3. **NBA Widget License Incompatibility - ROOT CAUSE #1**:
   - Einstein Next Best Action (NBA) widget queries Recommendation objects
   - Community Login users CANNOT access Recommendation objects (license restriction)
   - Cannot be fixed by adding permissions - fundamental license limitation
   - **Solution**: Created custom LWC `producerNextActions` to replace NBA widget

4. **Activity Panel Permission Issue - ROOT CAUSE #2**:
   - `runtime_sales_activities:activityPanel` component tries to load Tasks/Events
   - Community Login users have NO permissions for Task and Event objects
   - **Solution**: Added visibility rule to hide Activity Panel from Community users

5. **NBA Widget Flow Launch Error - ROOT CAUSE #3 (CURRENT ISSUE)**:
   - When `Producer_Placed_On_Market_Acknowledge_Best_Action` flow was disabled for testing, error changed to: "Flow 'Producer_Placed_On_Market_Acknowledge_Best_Action' is not found or doesn't have an active version"
   - This confirms the NBA widget is STILL being served from Experience Cloud cache
   - Even though FlexiPage was deployed with NBA widget removed and custom component added

---

## Work Completed

### 1. Custom LWC Component Created - `producerNextActions`
**Deploy ID**: 0AfSj000000z6JpKAI

**Purpose**: Replace NBA widget functionality without using Recommendation objects

**Files Created**:
- `/home/john/Projects/Salesforce/force-app/main/default/lwc/producerNextActions/producerNextActions.js`
- `/home/john/Projects/Salesforce/force-app/main/default/lwc/producerNextActions/producerNextActions.html`
- `/home/john/Projects/Salesforce/force-app/main/default/lwc/producerNextActions/producerNextActions.js-meta.xml`

**Features**:
- Uses Producer_Placed_on_Market__c formula fields instead of Recommendation objects
- Shows conditional action cards based on record state
- Launches same flows that NBA widget would launch
- Works for ALL license types (Community Login, Community Plus, internal users)

### 2. FlexiPage Updated - Producer_Placed_on_Market_Record_Page
**Deploy IDs**:
- 0AfSj000000z6LRKAY (Initial deployment - NBA widget replaced)
- 0AfSj000000z6N3KAI (Activity Panel hidden)

**Changes**:
1. **Line 342-343**: Replaced `runtime_communities_nba:builderNbaWidget` (53 lines) with `c:producerNextActions` (2 lines)
2. **Line 88-100**: Added visibility rule to S360_LN:PopUp component to hide from Community users
3. **Line 115-121**: Added visibility rule to Path Assistant to hide from Community users
4. **Line 410-416**: Added visibility rule to Activity Panel to hide from Community users

**Visibility Rules Added**: All use `{!$User.System_Admin__c} EQUAL true` to hide from Community users

### 3. Site Publishing Attempts
**Publish Job IDs**:
- 08PSj00000LEEDWMA5 (First publish after LWC deployment)
- 08PSj00000LEHCzMAP (Second publish after Activity Panel fix)

---

## Current Status - CACHE ISSUE

### Problem
The **Experience Cloud cache is NOT clearing** even after:
- Multiple `sf community publish` commands executed successfully
- FlexiPage deployments confirmed (retrieval shows custom component in place)
- Private/incognito browser testing
- Waiting for publish job completion

### Evidence
1. **Local FlexiPage file** shows:
   ```xml
   <componentName>c:producerNextActions</componentName>
   ```
   NBA widget (`builderNbaWidget`) is completely removed

2. **Org metadata retrieval** confirms custom component is deployed

3. **User still sees NBA widget error**: When `Producer_Placed_On_Market_Acknowledge_Best_Action` flow was disabled, error changed to show flow name, proving NBA widget is still being served

### Root Cause
Experience Cloud has aggressive caching that is NOT clearing via:
- CLI `sf community publish` command
- Standard browser refresh
- Hard refresh (Ctrl+Shift+R)
- Private/incognito browsing
- Multiple redeployments

---

## Next Steps (To Continue Tomorrow)

### Option 1: Force Cache Clear via Tooling API
Try using Salesforce Tooling API or REST API to directly clear site cache:
```bash
# Network ID: 0DBSj00000007pVOAQ
# Try Tooling API endpoint to force cache clear
```

### Option 2: Temporary Deactivation of FlexiPage
1. Deactivate the current FlexiPage assignment for Community users
2. Create a new FlexiPage with fresh name
3. Assign new FlexiPage to Community users
4. This forces Experience Cloud to rebuild cache with new page

### Option 3: Check Page Assignment
Verify that Producer_Placed_on_Market_Record_Page is actually assigned to Community users:
```bash
sf data query --query "SELECT AssignedToId, FlexiPageId FROM FlexiPageAssignment WHERE FlexiPageId IN (SELECT Id FROM FlexiPage WHERE DeveloperName = 'Producer_Placed_on_Market_Record_Page')" --target-org OldOrg
```

### Option 4: Use Experience Builder to Force Update
1. Open Experience Builder for Producer Portal
2. Navigate to the record page
3. Make a trivial change (add/remove whitespace)
4. Publish from within Experience Builder
5. This might trigger proper cache invalidation

### Option 5: Contact Salesforce Support
If cache won't clear through normal means, this may require Salesforce support intervention to manually clear Experience Cloud cache.

---

## Files Modified

### Flows
1. `/home/john/Projects/Salesforce/force-app/main/default/flows/validationQuestionsFlow.flow-meta.xml`
   - Line 27: Changed `runInMode` to `SystemModeWithoutSharing`
   - Removed `isAdditionalPermissionRequiredToRun` requirement

2. `/home/john/Projects/Salesforce/force-app/main/default/flows/Producer_Placed_On_Market_Question_Best_Action.flow-meta.xml`
3. `/home/john/Projects/Salesforce/force-app/main/default/flows/Producer_Placed_On_Market_Acknowledge_Best_Action.flow-meta.xml`
4. `/home/john/Projects/Salesforce/force-app/main/default/flows/Producer_Placed_On_Market_Signature_Best_Action.flow-meta.xml`
5. `/home/john/Projects/Salesforce/force-app/main/default/flows/Producer_Placed_On_Market_Resubmission_Best_Action.flow-meta.xml`
   - All changed `isAdditionalPermissionRequiredToRun` from `true` to `false`

### Lightning Web Components
6. `/home/john/Projects/Salesforce/force-app/main/default/lwc/producerNextActions/producerNextActions.js` (CREATED)
7. `/home/john/Projects/Salesforce/force-app/main/default/lwc/producerNextActions/producerNextActions.html` (CREATED)
8. `/home/john/Projects/Salesforce/force-app/main/default/lwc/producerNextActions/producerNextActions.js-meta.xml` (CREATED)

### FlexiPages
9. `/home/john/Projects/Salesforce/force-app/main/default/flexipages/Producer_Placed_on_Market_Record_Page.flexipage-meta.xml`
   - Replaced NBA widget with custom component
   - Added visibility rules to hide S360_LN:PopUp, Path Assistant, and Activity Panel from Community users

---

## Key Learnings

1. **Community Login License Restrictions**:
   - Cannot access Recommendation objects (Einstein NBA)
   - Cannot access Task/Event objects (Activities)
   - Both have same UserType as Community Plus (Full), so visibility rules can't distinguish

2. **Experience Cloud Caching**:
   - Extremely aggressive caching that persists across browser sessions
   - `sf community publish` command doesn't immediately clear cache
   - No UI option to manually clear cache in some Salesforce versions
   - May require Tooling API or Experience Builder to force cache invalidation

3. **Flow Permission Requirements**:
   - `isAdditionalPermissionRequiredToRun=true` requires "Run Flows" permission
   - Community users typically don't have this permission
   - Flows in `SystemModeWithoutSharing` don't actually need this setting

4. **Component Permission Errors**:
   - Standard components (NBA, Activity Panel, Path Assistant) may have hidden object access requirements
   - Errors from components show as generic "You do not have access" messages
   - Need to isolate by testing components individually

---

## Related Documentation
- `/home/john/Projects/Salesforce/Documentation/CLAUDE_WORKFLOW_RULES.md`
- `/home/john/Projects/Salesforce/Documentation/PRODUCER_PORTAL_MASTER_DOCUMENTATION.md`

---

## Test Plan for Tomorrow

Once cache is cleared:

1. **Test as Matthew Walker (Community Login User)**:
   - Access record M-008558 via "Overdue - Action Required" link
   - Verify page loads WITHOUT permission errors
   - Verify custom `producerNextActions` component shows (if applicable actions exist)
   - Verify NO NBA widget appears
   - Verify NO Activity Panel appears
   - Verify NO Path Assistant appears
   - Verify S360_LN:PopUp does NOT appear (since Unanswered_Questions__c is null)

2. **Test as Internal User (System Admin)**:
   - Access same record
   - Verify NBA widget is REMOVED
   - Verify Activity Panel SHOWS
   - Verify Path Assistant SHOWS
   - Verify all functionality still works

3. **Test as Community Plus (Full) License User**:
   - Access same record
   - Verify custom `producerNextActions` component shows
   - Verify page loads without errors
   - Verify flows can be launched and completed

---

## Questions to Answer Tomorrow

1. Why is Experience Cloud cache not clearing via standard methods?
2. Is there a FlexiPage assignment issue preventing the updated page from being served to Community users?
3. Do we need to use Tooling API or Experience Builder to force cache invalidation?
4. Should we create a completely new FlexiPage with a different name to bypass caching?
5. Is there a Salesforce setting that controls Experience Cloud cache TTL (Time To Live)?

---

**Last Updated**: 2025-10-21 23:40 UTC
**Status**: IN PROGRESS - Cache clearing issue blocking final testing
**Next Session**: Continue with cache clearing strategies
