# Sage API Integration - OAuth Authentication Configuration

**Created**: October 23, 2025
**Scenario Type**: ⚙️ **Configuration** (OAuth Re-authentication Procedure)
**Organization**: OldOrg (Recycling Lives Service)
**Status**: ✅ Resolved (October 17, 2025)

---

## Executive Summary

**What This Documents**: OAuth authentication procedure for Sage API Named Credential when access token expires and requires manual re-authentication.

**Critical Information**:
- **NOT a code deployment scenario** - This is pure configuration/authentication
- **Incident Date**: October 15, 2025 - HTTP 401 authentication failures
- **Affected Systems**: All Sage API integrations (invoice export, customer/supplier sync)
- **Root Cause**: OAuth access token expired, refresh token unable to auto-refresh
- **Resolution**: Manual re-authentication of "SIA" Named Credential via Setup UI
- **Resolution Date**: October 17, 2025 - All systems restored

**Business Impact**:
- **During Failure**: Users unable to export invoices to Sage, scheduled jobs failing
- **Affected Users**: Ania (invoice export) + all scheduled sync jobs
- **Duration**: ~2 days (Oct 15-17, 2025)
- **Failed Jobs**: 8+ scheduled job failures with identical HTTP 401 errors

---

## System Overview

### What is This Integration?

**Sage 200 Extra API Integration** connects Salesforce OldOrg to Sage 200 accounting system for:

1. **Invoice Export** - Export customer and vendor invoices from Salesforce to Sage
2. **Customer Sync** - Sync customer data from Sage to Salesforce (scheduled)
3. **Supplier Sync** - Sync RLCS supplier data from Sage to Salesforce (scheduled)
4. **Account Management** - Bidirectional account synchronization

### Authentication Architecture

```
Salesforce OldOrg
├── SageAPIClient.cls (Apex Class)
│   └── Uses: callout:SIA/<endpoint>
│
├── Named Credential: "SIA"
│   ├── Endpoint: api.columbus.sage.com/uk/sage200extra/accounts/v1/
│   ├── Protocol: OAuth 2.0
│   ├── Principal Type: NamedUser (org-wide authentication)
│   └── Scopes: openid profile email offline_access
│
└── Auth Provider: "Sage"
    ├── Type: OpenIdConnect (OAuth 2.0)
    ├── Consumer Key: HfbzYzoh2jxTGkLfSG6T3Z8Qdh41Gesb
    ├── Token URL: https://id.sage.com/oauth/token
    └── Auth URL: https://id.sage.com/authorize

                    ↓ OAuth Authentication ↓

Sage Identity Service (https://id.sage.com)
├── Issues Access Token (expires ~1 hour)
└── Issues Refresh Token (expires 60-90 days)

                    ↓ API Access ↓

Sage 200 Extra API (https://api.columbus.sage.com)
├── Accounts API
├── Invoices API
├── Suppliers API
└── Customers API
```

**Critical Point**: Both RLES and RLCS use the **same Named Credential** ("SIA"), meaning one authentication failure affects all Sage integrations organization-wide.

---

## Incident Details (October 15-17, 2025)

### Symptoms

**User-Reported Error (Ania)**:
```
HTTP request failed: HTTP Error: 401 -
Class.SageAPIClient.sendRequest: line 18
Class.SageAPIClient.SendInvoice: line 461
```
- **When**: Attempting to export RLCS Vendor Invoices using "Send to Sage" button
- **Result**: Invoice export failed, no data sent to Sage

**Admin Email Alerts**:
- `SageRLCSSupplierQueueable` - Failed with HTTP 401
- `SageCustomerQueueable` - Failed with HTTP 401
- Multiple scheduled jobs failing simultaneously

**Common Pattern**:
- ✅ Same error code: HTTP 401 Unauthorized
- ✅ Same failing point: SageAPIClient.sendRequest:18
- ✅ Same timing: Occurring across all integration points
- ✅ Affects both RLES and RLCS systems

### Root Cause

**OAuth Access Token Expired** and refresh token unable to automatically refresh.

**Normal OAuth Flow**:
1. Admin authenticates Named Credential → Sage issues access token + refresh token
2. Access token expires after ~1 hour
3. Salesforce automatically uses refresh token to get new access token
4. Process repeats seamlessly

**Failure Scenario** (What Happened):
1. Access token expired
2. Refresh token expired OR invalid
3. Salesforce cannot get new access token
4. All API calls return HTTP 401
5. **Manual re-authentication required**

**Common Causes**:
- Refresh token expired (typically valid 60-90 days)
- User credentials changed in Sage (password reset, account locked)
- OAuth app credentials changed (client secret rotated)
- Permissions revoked in Sage
- Named Credential not authenticated initially

---

## Affected Systems

### 1. Invoice Export to Sage

**User Impact**: Users cannot export invoices to Sage using "Send to Sage" button

**Affected Apex Classes**:
- `ExportInvoiceSageBatch.cls` - Exports customer invoices
- `ExportVendorInvoiceSageBatch.cls` - Exports vendor invoices

**User-Facing Features**:
- "Send to Sage" button on Invoice records
- "Send to Sage" button on Vendor Invoice records
- Batch invoice export functionality

### 2. Supplier Synchronization (RLCS)

**Scheduled Job**: `SageRLCSSupplierScheduler` (Daily/Hourly)

**Affected Classes**:
- `SageRLCSSupplierQueueable.cls`
- `SageRLCSSupplierScheduler.cls`

**Impact**: RLCS supplier data not syncing from Sage to Salesforce

### 3. Customer Synchronization

**Scheduled Job**: `SageCustomerScheduler` (Daily/Hourly)

**Affected Classes**:
- `SageCustomerQueueable.cls`
- `SageCustomerScheduler.cls`

**Impact**: Customer data not syncing from Sage to Salesforce

### 4. All Other Sage API Integrations

Any functionality using `SageAPIClient.cls` will fail with HTTP 401:
- Customer creation/updates in Sage
- Invoice posting to Sage
- Supplier data retrieval
- Any custom integrations

---

## Resolution Steps (Re-Authentication Procedure)

### Step 1: Re-authenticate the Named Credential

**As Salesforce Administrator:**

1. Navigate to **Setup** (gear icon, top right)
2. In Quick Find, search for **"Named Credentials"**
3. Click **Named Credentials**
4. Find and click **SIA** in the list
5. Click **Edit** button
6. Look for the **Authentication Status** section
7. Click **Authenticate** or **Re-authenticate** button
8. You will be redirected to Sage login page: `https://id.sage.com/authorize`
9. **Log in with Sage 200 Extra credentials:**
   - Use the service account credentials for Sage API access
   - **Important**: Use the account that has API permissions in Sage 200
10. **Authorize the application:**
    - Review requested permissions: `openid profile email offline_access`
    - Click **Allow** or **Authorize**
11. You'll be redirected back to Salesforce
12. Verify authentication status shows **Connected** or **Authenticated**
13. Click **Save**

**Expected Result**:
- Named Credential status: ✅ Authenticated
- OAuth token successfully obtained
- All Sage API integrations resume working

### Step 2: Verify Auth Provider Configuration (If Re-auth Fails)

**Check Auth Provider settings:**

1. Navigate to **Setup** → Quick Find → **Auth. Providers**
2. Click **Sage**
3. Verify the following settings:

| Setting | Expected Value |
|---------|----------------|
| Provider Type | OpenIdConnect |
| Name | Sage |
| Consumer Key | `HfbzYzoh2jxTGkLfSG6T3Z8Qdh41Gesb` |
| Consumer Secret | **(Must be valid, not "Placeholder_Value")** |
| Authorize Endpoint URL | `https://id.sage.com/authorize?audience=s200ukipd/sage200` |
| Token Endpoint URL | `https://id.sage.com/oauth/token` |
| Default Scopes | `openid profile email offline_access` |

**Critical Check**: If **Consumer Secret** shows `Placeholder_Value` or is incorrect:
1. Retrieve the actual consumer secret from Sage developer portal
2. Update the Auth Provider with the correct secret
3. Re-authenticate the Named Credential

### Step 3: Test Invoice Export

**Have user test:**

1. Navigate to an RLCS Vendor Invoice record
2. Click **"Send to Sage"** button
3. Expected result: ✅ Invoice exports successfully, no HTTP 401 error

**Alternative Test (as Admin):**

```apex
// Anonymous Apex to test connection
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:SIA/sales_customers');
req.setMethod('GET');
req.setHeader('ocp-apim-subscription-key', '2234c7d0d9bf4cc4bb732b0e070d2ad3');
req.setHeader('X-Site', 'b25b8b8a-9688-47b1-bb1c-48ed4a1fc5c9');
req.setHeader('X-Company', '13');

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Status Code: ' + res.getStatusCode());
System.debug('Response Body: ' + res.getBody());

// Expected: Status Code 200 (not 401)
```

**Expected Result**:
- Status Code: `200`
- Response Body: JSON with customer data

### Step 4: Verify Scheduled Jobs Resume

**Check Queueable job status:**

1. Navigate to **Setup** → Quick Find → **Apex Jobs**
2. Look for recent jobs:
   - `SageRLCSSupplierQueueable`
   - `SageCustomerQueueable`
3. Verify status: **Completed** (not Failed)
4. Check completion time is recent (after re-authentication)

**Alternative: Monitor via SOQL**

```soql
SELECT Id, ApexClassName, Status, CompletedDate, ExtendedStatus, NumberOfErrors
FROM AsyncApexJob
WHERE ApexClass.Name IN ('SageRLCSSupplierQueueable', 'SageCustomerQueueable')
ORDER BY CreatedDate DESC
LIMIT 10
```

**Expected**: Recent jobs show `Status = 'Completed'` with `NumberOfErrors = 0`

---

## Configuration Details

### Named Credential: SIA

**Configuration** (from OldOrg metadata):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<NamedCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <allowMergeFieldsInBody>false</allowMergeFieldsInBody>
    <allowMergeFieldsInHeader>false</allowMergeFieldsInHeader>
    <authProvider>Sage</authProvider>
    <calloutStatus>Enabled</calloutStatus>
    <endpoint>https://api.columbus.sage.com/uk/sage200extra/accounts/v1/</endpoint>
    <generateAuthorizationHeader>true</generateAuthorizationHeader>
    <label>SIA</label>
    <oauthScope>openid profile email offline_access</oauthScope>
    <principalType>NamedUser</principalType>
    <protocol>Oauth</protocol>
</NamedCredential>
```

**Key Configuration Points**:
- **Protocol**: OAuth (automatic authorization header generation)
- **Principal Type**: NamedUser (org-wide, requires one authenticated user)
- **Auth Provider**: Sage (references Auth Provider configuration)
- **Scopes**: Includes `offline_access` for refresh token capability

### Auth Provider: Sage

**Configuration** (from OldOrg metadata):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<AuthProvider xmlns="http://soap.sforce.com/2006/04/metadata">
    <authorizeUrl>https://id.sage.com/authorize?audience=s200ukipd/sage200</authorizeUrl>
    <consumerKey>HfbzYzoh2jxTGkLfSG6T3Z8Qdh41Gesb</consumerKey>
    <consumerSecret>Placeholder_Value</consumerSecret>
    <defaultScopes>openid profile email offline_access</defaultScopes>
    <friendlyName>Sage</friendlyName>
    <isPkceEnabled>true</isPkceEnabled>
    <providerType>OpenIdConnect</providerType>
    <sendAccessTokenInHeader>true</sendAccessTokenInHeader>
    <tokenUrl>https://id.sage.com/oauth/token</tokenUrl>
</AuthProvider>
```

**Important**: The `consumerSecret` showing `Placeholder_Value` is normal in metadata (stored securely). However, if authentication fails, verify the actual secret is correctly configured in Setup UI.

### Sage API Settings (Custom Settings)

**Current Configuration from OldOrg**:

| Field | RLES Value | RLCS Value |
|-------|------------|------------|
| Endpoint_Prefix | `SIA` | `SIA` |
| Subscription_Key | `2234c7d0d9bf4cc4bb732b0e070d2ad3` | `2234c7d0d9bf4cc4bb732b0e070d2ad3` |
| Site_Id | `b25b8b8a-9688-47b1-bb1c-48ed4a1fc5c9` | `b25b8b8a-9688-47b1-bb1c-48ed4a1fc5c9` |
| Company_Id | `13` | `9` |

**Query to Verify**:

```bash
sf data query --query "SELECT Endpoint_Prefix__c, Endpoint_Prefix_RLCS__c, Subscription_Key__c, Subscription_Key_RLCS__c, Site_Id__c, Site_Id_RLCS__c, Company_Id__c, Company_Id_RLCS__c FROM Sage_API_Settings__c" --target-org OldOrg --use-tooling-api
```

**Note**: Both RLES and RLCS use the same subscription key and site ID, but different Company IDs (13 vs 9) to differentiate business units within Sage 200.

---

## Verification Results (October 17, 2025)

### Before Fix (October 15-16, 2025)

**Failed Jobs History**:

| Date/Time | Job | Status | Error |
|-----------|-----|--------|-------|
| 2025-10-15 (multiple) | SageRLCSSupplierQueueable | ❌ Failed | `HTTP Error: 401 -` |
| 2025-10-15 (multiple) | SageCustomerQueueable | ❌ Failed | `HTTP Error: 401 -` |
| 2025-10-16 04:15:00 | SageCustomerQueueable | ❌ Failed | `HTTP Error: 401 -` |
| 2025-10-16 04:55:00 | SageRLCSSupplierQueueable | ❌ Failed | `HTTP Error: 401 -` |

**Total Failed Jobs**: 8+ scheduled job failures with identical HTTP 401 errors

### After Fix (October 17, 2025)

**Successful Jobs**:

| Date/Time | Job | Status | Errors |
|-----------|-----|--------|--------|
| 2025-10-17 04:15:10 | SageCustomerQueueable | ✅ Completed | 0 |
| 2025-10-17 04:55:02 | SageRLCSSupplierQueueable | ✅ Completed | 0 |
| 2025-10-17 07:10:52 | ExportInvoiceSageBatch | ✅ Completed | 0 |

**API Connection Test**:
- ✅ No HTTP 401 errors detected
- ✅ OAuth authentication successful for both RLES and RLCS
- ✅ Named Credential "SIA" properly authenticated

**Resolution**: Manual re-authentication of SIA Named Credential via Setup → Named Credentials → SIA → Authenticate (October 17, 2025)

---

## Prevention & Monitoring

### Best Practices

1. **Regular Token Refresh Monitoring**
   - OAuth refresh tokens typically expire after 60-90 days
   - Set calendar reminder to check authentication status monthly
   - Document the service account credentials used for Sage API

2. **Proactive Re-authentication**
   - Re-authenticate Named Credential before token expiration
   - Test connection after any Sage system updates
   - Verify after password resets on Sage service account

3. **Monitoring & Alerts**
   - Set up email alerts for Apex job failures (Setup → Email Administration)
   - Monitor scheduled job success rates (Setup → Apex Jobs)
   - Create dashboard for Sage integration health

4. **Documentation**
   - Keep Sage API credentials documented securely
   - Document which service account is used for OAuth
   - Record Consumer Key/Secret for Auth Provider

### Scheduled Jobs to Monitor

Track these scheduled jobs in **Setup → Apex Jobs**:

| Job Name | Frequency | Purpose | Alert If Failed |
|----------|-----------|---------|-----------------|
| SageRLCSSupplierScheduler | Daily/Hourly | Sync RLCS suppliers from Sage | ✅ Yes |
| SageCustomerScheduler | Daily/Hourly | Sync customers from Sage | ✅ Yes |

### Recommended Monitoring

**Query to Check Recent Failures**:

```soql
SELECT Id, ApexClassName, Status, CompletedDate, ExtendedStatus, NumberOfErrors
FROM AsyncApexJob
WHERE ApexClass.Name IN (
    'SageRLCSSupplierQueueable',
    'SageCustomerQueueable',
    'ExportInvoiceSageBatch',
    'ExportVendorInvoiceSageBatch'
)
AND Status = 'Failed'
AND CreatedDate = TODAY
ORDER BY CreatedDate DESC
```

**Expected**: No recent failures with HTTP 401 errors

### Next Authentication Review

**Schedule**: **December 16, 2025** (60 days from October 17, 2025 resolution)

**Action**: Proactively re-authenticate SIA Named Credential before token expiration

---

## Referenced Components

### Apex Classes (No Changes Needed)

**Core Integration Class**:
- `SageAPIClient.cls` - Core API client where HTTP 401 occurs (line 18)
- Contains methods: `sendRequest()`, `handleResponse()`, `getRequest()`

**Invoice Export Classes**:
- `ExportInvoiceSageBatch.cls` - Customer invoice export batch job
- `ExportVendorInvoiceSageBatch.cls` - Vendor invoice export batch job

**Sync Classes**:
- `SageRLCSSupplierQueueable.cls` - RLCS supplier sync
- `SageRLCSSupplierScheduler.cls` - RLCS supplier scheduler
- `SageCustomerQueueable.cls` - Customer sync
- `SageCustomerScheduler.cls` - Customer scheduler

**Note**: No code changes required for this issue. All classes are working correctly. This is purely an OAuth authentication configuration issue.

### Configuration Components

**Named Credential**:
- Metadata: `namedCredentials/SIA.namedCredential-meta.xml`
- Configuration: Setup → Named Credentials → SIA

**Auth Provider**:
- Metadata: `authproviders/Sage.authprovider-meta.xml`
- Configuration: Setup → Auth. Providers → Sage

**Custom Settings**:
- `Sage_API_Settings__c` - Stores endpoint prefixes, subscription keys, site IDs, company IDs

---

## Related Documentation

### Source Documentation

- [source-docs/SAGE_API_HTTP_401_AUTHENTICATION_FIX.md](source-docs/SAGE_API_HTTP_401_AUTHENTICATION_FIX.md) - Original incident documentation

### NewOrg Migration

**⚠️ IMPORTANT**: This is a **configuration scenario**, NOT a code deployment.

**For NewOrg**:
1. Verify Named Credential "SIA" exists and is configured
2. Verify Auth Provider "Sage" exists with correct Consumer Key/Secret
3. Authenticate Named Credential using NewOrg Sage credentials
4. Test connection with API query
5. Schedule monitoring for authentication status

See: [NewOrg sage-api-integration Configuration Guide](https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/sage-api-integration)

---

## Troubleshooting Guide

### Issue: Re-authentication Doesn't Fix 401 Error

**Possible Causes**:
1. Consumer Secret in Auth Provider is incorrect
2. Sage service account locked or disabled
3. OAuth app configuration changed in Sage portal
4. Network/firewall blocking OAuth flow

**Steps**:
1. Verify Consumer Key and Consumer Secret in Auth Provider (Setup → Auth. Providers → Sage)
2. Test Sage credentials by logging into Sage web UI
3. Check Sage developer portal for OAuth app status
4. Review Salesforce Setup Audit Trail for configuration changes

### Issue: OAuth Flow Redirects to Error Page

**Possible Causes**:
1. Callback URL mismatch in Sage OAuth app
2. Scopes changed or invalid
3. Sage API permissions not granted to service account

**Steps**:
1. Verify callback URL in Sage matches Salesforce Auth Provider URL
2. Check scopes in Auth Provider match Sage OAuth app: `openid profile email offline_access`
3. Verify service account has API access permissions in Sage 200

### Issue: Scheduled Jobs Still Failing After Re-auth

**Possible Causes**:
1. Scheduled jobs running under different user context
2. Queueable jobs queued before re-authentication
3. Different Sage API endpoint having issues

**Steps**:
1. Check **Setup → Scheduled Jobs** to see which user runs the job
2. Cancel and re-queue any queued jobs
3. Test individual API endpoints with Anonymous Apex
4. Check Sage API status page for service disruptions

---

## Files and Metadata

### Configuration Files (No Code Deployment)

**Named Credential**:
- `force-app/main/default/namedCredentials/SIA.namedCredential-meta.xml`

**Auth Provider**:
- `force-app/main/default/authproviders/Sage.authprovider-meta.xml`

**Note**: These metadata files are for reference only. OAuth authentication is managed via Setup UI in Salesforce, not through code deployment.

### Referenced Apex Classes (Existing Code - No Changes)

All these classes exist in OldOrg and use the SIA Named Credential:

- `force-app/main/default/classes/SageAPIClient.cls`
- `force-app/main/default/classes/ExportInvoiceSageBatch.cls`
- `force-app/main/default/classes/ExportVendorInvoiceSageBatch.cls`
- `force-app/main/default/classes/SageRLCSSupplierQueueable.cls`
- `force-app/main/default/classes/SageRLCSSupplierScheduler.cls`
- `force-app/main/default/classes/SageCustomerQueueable.cls`
- `force-app/main/default/classes/SageCustomerScheduler.cls`

**Code Deployment**: Not required - all code is already deployed and working correctly

---

## Key Learnings

### 1. OAuth Authentication is Organization-Wide

Unlike per-user credentials, Named Credentials with **NamedUser** principal type require:
- One authenticated user for the entire org
- That user must have valid Sage credentials
- If that user's Sage access is revoked, all integrations fail

### 2. Refresh Tokens Have Expiration

Even with `offline_access` scope:
- Refresh tokens can expire (typically 60-90 days)
- Some OAuth providers revoke tokens after inactivity
- Manual re-authentication required after expiration

### 3. Centralized Authentication = Single Point of Failure

Both RLES and RLCS use the same Named Credential:
- **Advantage**: Single place to manage authentication
- **Disadvantage**: One authentication failure affects all systems
- Consider separate Named Credentials if systems need independent auth

### 4. HTTP 401 vs HTTP 403

- **HTTP 401 Unauthorized**: Authentication failed (invalid/expired credentials)
- **HTTP 403 Forbidden**: Authenticated but not authorized (permission issue)

This scenario is 401, meaning the OAuth token is the issue, not Sage permissions.

### 5. Monitoring is Critical for Scheduled Jobs

Scheduled jobs fail silently unless monitored:
- Enable email alerts for Apex job failures
- Create dashboards for integration health
- Set up proactive authentication checks

---

**Resolution Status**: ✅ **RESOLVED** (October 17, 2025)
**Resolved By**: Shintu John (Administrator)
**Next Review**: December 16, 2025 (60 days from resolution)
**Affected Users**: Ania + all Sage integration users
**Business Impact**: All Sage integrations restored to full functionality

---

**Last Updated**: October 23, 2025
**Documentation Type**: Configuration Guide (OAuth Re-authentication)
**Scenario Classification**: Configuration / Troubleshooting (NOT code deployment)
