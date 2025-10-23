# Sage API HTTP 401 Authentication Fix

**Date:** 2025-10-15
**Reported By:** Ania (user), Shintu John (admin - via email alerts)
**Affected Org:** OldOrg (Production - recyclinglives.my.salesforce.com)
**Status:** ✅ RESOLVED - Authentication Restored

---

## Table of Contents

1. [Issue Summary](#issue-summary)
2. [Root Cause Analysis](#root-cause-analysis)
3. [Affected Systems](#affected-systems)
4. [Resolution Steps](#resolution-steps)
5. [Technical Context](#technical-context)
6. [Verification Steps](#verification-steps)
7. [Prevention & Monitoring](#prevention--monitoring)
8. [Related Files](#related-files)

---

## Issue Summary

Multiple Sage API integration failures occurring simultaneously across OldOrg with identical HTTP 401 authentication errors.

### User-Reported Error (Ania)

**When:** Attempting to export RLCS Vendor Invoices to Sage using "Send to Sage" button

**Error Message:**
```
HTTP request failed: HTTP Error: 401 -
Class.SageAPIClient.sendRequest: line 18, column 1
Class.SageAPIClient.SendInvoice: line 461, column 1
Class.SageAPIClient.SendInvoice: line 106, column 1
Class.ExportInvoiceSageBatch.execute: line 41, column 1
```

### Admin Email Alerts

**Alert #1: SageRLCSSupplierQueueable Failure**

```
Apex script unhandled exception by user/organization: 0054H000005dwlO/00D24000000j5Yh

Organization: Recycling Lives (recyclinglives.my.salesforce.com)

Failed to process Queueable job for class SageRLCSSupplierQueueable for job ID 707Sj00000qxxI5.

caused by: SageAPIClient.SageAPIException: HTTP request failed: HTTP Error: 401 -

Class.SageAPIClient.sendRequest: line 18, column 1
Class.SageAPIClient.getSuppliersShortViews: line 443, column 1
Class.SageRLCSSupplierScheduler.<init>: line 8, column 1
Class.SageRLCSSupplierQueueable.execute: line 4, column 1
```

**Alert #2: SageCustomerQueueable Failure**

```
Apex script unhandled exception by user/organization: 0054H000005dwlO/00D24000000j5Yh

Organization: Recycling Lives (recyclinglives.my.salesforce.com)

Failed to process Queueable job for class SageCustomerQueueable for job ID 707Sj00000qxlvi.

caused by: SageAPIClient.SageAPIException: HTTP request failed: HTTP Error: 401 -

Class.SageAPIClient.sendRequest: line 18, column 1
Class.SageAPIClient.getCustomerShortViews: line 450, column 1
Class.SageCustomerScheduler.<init>: line 15, column 1
Class.SageCustomerQueueable.execute: line 4, column 1
```

### Common Pattern

All three errors:
- ✅ Same error code: **HTTP 401 Unauthorized**
- ✅ Same failing point: [SageAPIClient.sendRequest:18](../force-app/main/default/classes/SageAPIClient.cls#L18)
- ✅ Same timing: Occurring simultaneously across different integration points
- ✅ Affect both RLES and RLCS systems

---

## Root Cause Analysis

### Primary Cause: OAuth Token Expiration

**The OAuth access token used by Named Credential "SIA" has expired and cannot be refreshed.**

### Authentication Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Salesforce OldOrg                        │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         SageAPIClient.cls (Apex Class)               │  │
│  │  - SendInvoice()                                     │  │
│  │  - getSuppliersShortViews()                          │  │
│  │  - getCustomerShortViews()                           │  │
│  │                                                      │  │
│  │  Uses: callout:SIA/<endpoint>                       │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │    Named Credential: SIA                             │  │
│  │    - Endpoint: api.columbus.sage.com/...            │  │
│  │    - Protocol: OAuth                                 │  │
│  │    - Principal: NamedUser                            │  │
│  │    - Scopes: openid profile email offline_access    │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │    Auth Provider: Sage                               │  │
│  │    - Type: OpenIdConnect (OAuth 2.0)                 │  │
│  │    - Consumer Key: HfbzYzoh2jxTGkLfSG6T3Z8Qdh41Gesb  │  │
│  │    - Token URL: https://id.sage.com/oauth/token      │  │
│  │    - Auth URL: https://id.sage.com/authorize         │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │                                           │
└─────────────────┼───────────────────────────────────────────┘
                  │
                  │ OAuth 2.0 Authentication
                  ▼
┌─────────────────────────────────────────────────────────────┐
│              Sage Identity Service                          │
│              https://id.sage.com                            │
│                                                             │
│  Issues:                                                    │
│  - Access Token (expires ~1 hour)                          │
│  - Refresh Token (long-lived)                              │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  │ Valid Token Required
                  ▼
┌─────────────────────────────────────────────────────────────┐
│         Sage 200 Extra API                                  │
│         https://api.columbus.sage.com/uk/sage200extra/      │
│                                                             │
│  - Accounts API                                             │
│  - Invoices API                                             │
│  - Suppliers API                                            │
│  - Customers API                                            │
└─────────────────────────────────────────────────────────────┘
```

### Why HTTP 401 Occurs

At [SageAPIClient.cls:9-21](../force-app/main/default/classes/SageAPIClient.cls#L9):

```apex
private static HttpResponse sendRequest(HttpRequest req) {
    Http http = new Http();
    HttpResponse res;

    try {
        res = http.send(req);  // ← Line 14: HTTP callout happens here
        System.debug('Req Body'+ req.getBody());
        return handleResponse(res);  // ← Line 16: Goes to handleResponse
    } catch (Exception e) {
        System.debug('Error: ' + e.getMessage());
        throw new SageAPIException('HTTP request failed: ' + e.getMessage());  // ← Line 19: Error thrown
    }
}
```

At [SageAPIClient.cls:23-32](../force-app/main/default/classes/SageAPIClient.cls#L23):

```apex
private static HttpResponse handleResponse(HttpResponse res) {
    System.debug('HTTP Response Code: ' + res.getStatusCode());
    System.debug('HTTP Response Body: ' + res.getBody());

    if (res.getStatusCode() != 200) {
        throw new SageAPIException('HTTP Error: ' + res.getStatusCode() + ' - ' + res.getBody());  // ← Line 28: Throws 401 error
    }

    return res;
}
```

**What Happens:**
1. Salesforce makes callout to `callout:SIA/...`
2. Named Credential tries to add OAuth access token
3. Access token expired, refresh token also expired/invalid
4. Sage API returns HTTP 401 Unauthorized
5. `handleResponse()` throws `SageAPIException`
6. User sees error, scheduled jobs fail

### Why Both RLES and RLCS Affected

Looking at [SageAPIClient.cls:34-62](../force-app/main/default/classes/SageAPIClient.cls#L34), both systems use the **same Named Credential**:

```apex
private static HttpRequest getRequest(string method, string url) {
    HttpRequest req = new HttpRequest();

    if(isRLCS == null || isRLCS == false) {
        // RLES Configuration
        req.setEndpoint('callout:' + settings.Endpoint_Prefix__c + '/' + url);  // callout:SIA/...
        req.setHeader('ocp-apim-subscription-key', settings.Subscription_Key__c);
        req.setHeader('X-Site', settings.Site_Id__c);
        req.setHeader('X-Company', settings.Company_Id__c);  // Company 13
    }
    else {
        // RLCS Configuration
        req.setEndpoint('callout:' + settings.Endpoint_Prefix_RLCS__c + '/' + url);  // callout:SIA/...
        req.setHeader('ocp-apim-subscription-key', settings.Subscription_Key_RLCS__c);
        req.setHeader('X-Site', settings.Site_Id_RLCS__c);
        req.setHeader('X-Company', settings.Company_Id_RLCS__c);  // Company 9
    }

    req.setMethod(method);
    return req;
}
```

**Current Settings (from OldOrg):**

| Setting | RLES Value | RLCS Value |
|---------|------------|------------|
| Endpoint_Prefix | `SIA` | `SIA` |
| Subscription_Key | `2234c7d0d9bf4cc4bb732b0e070d2ad3` | `2234c7d0d9bf4cc4bb732b0e070d2ad3` |
| Site_Id | `b25b8b8a-9688-47b1-bb1c-48ed4a1fc5c9` | `b25b8b8a-9688-47b1-bb1c-48ed4a1fc5c9` |
| Company_Id | `13` | `9` |

**Key Point:** Both use `Endpoint_Prefix = "SIA"`, meaning they both rely on the same Named Credential authentication. When the SIA OAuth token expires, **all Sage integrations fail**.

### OAuth Token Lifecycle

**Normal Flow:**
1. Admin authenticates Named Credential → Sage issues access token + refresh token
2. Access token expires after ~1 hour
3. Salesforce automatically uses refresh token to get new access token
4. Process repeats seamlessly

**Failure Scenario (Current):**
1. Access token expired
2. Refresh token expired OR invalid OR credentials changed
3. Salesforce cannot get new access token
4. All API calls return HTTP 401
5. Manual re-authentication required

### Common Reasons for OAuth Failure

1. **Refresh token expired** - Typically valid for 60-90 days, but can vary
2. **User credentials changed** - Password reset, account locked in Sage
3. **OAuth app credentials changed** - Client secret rotated in Sage developer portal
4. **Permissions revoked** - User access removed in Sage
5. **Named Credential not authenticated** - Initial setup incomplete or authentication lost

---

## Affected Systems

### 1. Invoice Export to Sage

**User Impact:** Users (like Ania) cannot export invoices to Sage

**Affected Classes:**
- [ExportInvoiceSageBatch.cls](../force-app/main/default/classes/ExportInvoiceSageBatch.cls) - Exports customer invoices
- [ExportVendorInvoiceSageBatch.cls](../force-app/main/default/classes/ExportVendorInvoiceSageBatch.cls) - Exports vendor invoices

**User-Facing Features:**
- "Send to Sage" button on Invoice records
- "Send to Sage" button on Vendor Invoice records
- Batch invoice export functionality

### 2. Supplier Synchronization (RLCS)

**Scheduled Job:** `SageRLCSSupplierScheduler`

**Affected Classes:**
- [SageRLCSSupplierQueueable.cls](../force-app/main/default/classes/SageRLCSSupplierQueueable.cls)
- [SageRLCSSupplierScheduler.cls](../force-app/main/default/classes/SageRLCSSupplierScheduler.cls)

**Impact:** RLCS supplier data not syncing from Sage to Salesforce

### 3. Customer Synchronization

**Scheduled Job:** `SageCustomerScheduler`

**Affected Classes:**
- [SageCustomerQueueable.cls](../force-app/main/default/classes/SageCustomerQueueable.cls)
- [SageCustomerScheduler.cls](../force-app/main/default/classes/SageCustomerScheduler.cls)

**Impact:** Customer data not syncing from Sage to Salesforce

### 4. All Other Sage API Integrations

Any functionality using [SageAPIClient.cls](../force-app/main/default/classes/SageAPIClient.cls) will fail with HTTP 401:
- Customer creation/updates in Sage
- Invoice posting to Sage
- Supplier data retrieval
- Any custom integrations

---

## Resolution Steps

### Step 1: Re-authenticate the Named Credential (Primary Fix)

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
   - **Important:** Use the account that has API permissions in Sage 200
10. **Authorize the application:**
    - Review requested permissions: `openid profile email offline_access`
    - Click **Allow** or **Authorize**
11. You'll be redirected back to Salesforce
12. Verify authentication status shows **Connected** or **Authenticated**
13. Click **Save**

**Expected Result:**
- Named Credential status: ✅ Authenticated
- OAuth token successfully obtained
- All Sage API integrations resume working

### Step 2: Verify Auth Provider Configuration

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

**Critical Check:** If **Consumer Secret** shows `Placeholder_Value`, you need to:
1. Retrieve the actual consumer secret from Sage developer portal
2. Update the Auth Provider with the correct secret
3. Re-authenticate the Named Credential

### Step 3: Test Invoice Export

**Have Ania (or another user) test:**

1. Navigate to an RLCS Vendor Invoice record
2. Click **"Send to Sage"** button
3. Expected result: ✅ Invoice exports successfully, no HTTP 401 error

**Alternative Test (as Admin):**

1. Navigate to any test invoice record
2. Use **"Send to Sage"** functionality
3. Check for successful export

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

### Step 5: Enable Debug Logging (Optional)

**To capture detailed OAuth flow:**

1. Navigate to **Setup** → **Debug Logs**
2. Click **New**
3. Select your user
4. Set log levels:
   - **Callout**: DEBUG
   - **System**: DEBUG
5. Reproduce the issue or wait for scheduled job
6. Review debug logs for OAuth token details

---

## Technical Context

### Named Credential Configuration

**File:** [force-app/main/default/namedCredentials/SIA.namedCredential-meta.xml](../force-app/main/default/namedCredentials/SIA.namedCredential-meta.xml)

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

**Key Points:**
- Uses OAuth protocol with automatic authorization header generation
- References Auth Provider "Sage" for OAuth configuration
- Principal Type: NamedUser (requires specific user authentication)
- Scopes include `offline_access` (needed for refresh tokens)

### Auth Provider Configuration

**File:** [force-app/main/default/authproviders/Sage.authprovider-meta.xml](../force-app/main/default/authproviders/Sage.authprovider-meta.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<AuthProvider xmlns="http://soap.sforce.com/2006/04/metadata">
    <authorizeUrl>https://id.sage.com/authorize?audience=s200ukipd/sage200</authorizeUrl>
    <consumerKey>HfbzYzoh2jxTGkLfSG6T3Z8Qdh41Gesb</consumerKey>
    <consumerSecret>Placeholder_Value</consumerSecret>
    <defaultScopes>openid profile email offline_access</defaultScopes>
    <friendlyName>Sage</friendlyName>
    <includeOrgIdInIdentifier>false</includeOrgIdInIdentifier>
    <isPkceEnabled>true</isPkceEnabled>
    <providerType>OpenIdConnect</providerType>
    <requireMfa>false</requireMfa>
    <sendAccessTokenInHeader>true</sendAccessTokenInHeader>
    <sendClientCredentialsInHeader>false</sendClientCredentialsInHeader>
    <sendSecretInApis>true</sendSecretInApis>
    <tokenUrl>https://id.sage.com/oauth/token</tokenUrl>
</AuthProvider>
```

**Important:** The `consumerSecret` showing `Placeholder_Value` indicates this value is stored securely in Salesforce and not exposed in metadata. However, if authentication fails, this secret may need to be re-entered.

### Sage API Settings (Custom Settings)

**Query Results from OldOrg:**

```soql
SELECT Endpoint_Prefix__c, Endpoint_Prefix_RLCS__c,
       Subscription_Key__c, Subscription_Key_RLCS__c,
       Site_Id__c, Site_Id_RLCS__c,
       Company_Id__c, Company_Id_RLCS__c
FROM Sage_API_Settings__c
```

| Field | RLES | RLCS |
|-------|------|------|
| Endpoint_Prefix | SIA | SIA |
| Subscription_Key | 2234c7d0d9bf4cc4bb732b0e070d2ad3 | 2234c7d0d9bf4cc4bb732b0e070d2ad3 |
| Site_Id | b25b8b8a-9688-47b1-bb1c-48ed4a1fc5c9 | b25b8b8a-9688-47b1-bb1c-48ed4a1fc5c9 |
| Company_Id | 13 | 9 |

**Note:** The subscription key and site ID are the same for both RLES and RLCS, but they use different Company IDs to differentiate the business units within Sage 200.

### HTTP Request Headers

When authenticated correctly, requests to Sage API include:

```
POST https://api.columbus.sage.com/uk/sage200extra/accounts/v1/sales_invoices
Headers:
  Authorization: Bearer <access_token_from_named_credential>
  ocp-apim-subscription-key: 2234c7d0d9bf4cc4bb732b0e070d2ad3
  Content-Type: application/json
  X-Site: b25b8b8a-9688-47b1-bb1c-48ed4a1fc5c9
  X-Company: 13  (RLES) or 9 (RLCS)
```

The `Authorization` header with Bearer token is automatically added by the Named Credential. When this token is invalid/expired, Sage returns HTTP 401.

---

## Verification Steps

### 1. Verify Named Credential Authentication Status

**Via UI:**
1. Setup → Named Credentials → SIA
2. Look for authentication status indicator
3. Should show: ✅ **Connected** or **Authenticated**

### 2. Test API Connection with Anonymous Apex

```apex
// Test Sage API connection
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

**Expected Result:**
- Status Code: `200`
- Response Body: JSON with customer data

**If Still Failing:**
- Status Code: `401`
- Response Body: Authentication error details

### 3. Check Recent Apex Job Failures

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

**Expected After Fix:** No recent failures with HTTP 401 errors

### 4. Monitor User Reports

**Check with Ania:**
- Can she successfully export invoices to Sage?
- Does the "Send to Sage" button work without errors?

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
   - Set up email alerts for Apex job failures
   - Monitor scheduled job success rates
   - Create dashboard for Sage integration health

4. **Documentation**
   - Keep Sage API credentials documented securely
   - Document which service account is used for OAuth
   - Record Consumer Key/Secret for Auth Provider

### Create Custom Monitoring

**Option 1: Scheduled Apex Job to Test Connection**

```apex
public class SageConnectionHealthCheck implements Schedulable {
    public void execute(SchedulableContext ctx) {
        try {
            // Test connection
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:SIA/sales_customers');
            req.setMethod('GET');
            req.setHeader('ocp-apim-subscription-key', 'YOUR_KEY');
            req.setHeader('X-Site', 'YOUR_SITE_ID');
            req.setHeader('X-Company', '13');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                // Send alert email to admins
                sendAlertEmail('Sage API connection failing: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            sendAlertEmail('Sage API connection error: ' + e.getMessage());
        }
    }

    private void sendAlertEmail(String message) {
        // Implement email alert logic
    }
}
```

**Option 2: Process Builder / Flow**
- Monitor AsyncApexJob records for Sage-related failures
- Send email alerts on repeated 401 errors

**Option 3: External Monitoring**
- Use Salesforce monitoring tools (e.g., Salesforce Shield Event Monitoring)
- Set up alerts in Splunk, Datadog, or similar if integrated

### Scheduled Jobs to Monitor

Track these scheduled jobs in **Setup → Apex Jobs**:

| Job Name | Frequency | Purpose | Alert If Failed |
|----------|-----------|---------|-----------------|
| SageRLCSSupplierScheduler | Daily/Hourly | Sync RLCS suppliers from Sage | Yes |
| SageCustomerScheduler | Daily/Hourly | Sync customers from Sage | Yes |

### Dashboard Recommendations

Create a Salesforce Dashboard with:
1. **Sage Export Success Rate** - Count of successful vs failed invoice exports
2. **Recent Sage API Errors** - Log chart showing 401 errors over time
3. **Scheduled Job Health** - Success/failure of Sage sync jobs
4. **Last Successful Sync** - Timestamp of last successful Sage data sync

---

## Related Files

### Modified Files
*None - This is a configuration/authentication issue, not a code issue*

### Referenced Files

**Apex Classes:**
- [force-app/main/default/classes/SageAPIClient.cls](../force-app/main/default/classes/SageAPIClient.cls) - Core API client where HTTP 401 occurs
- [force-app/main/default/classes/ExportInvoiceSageBatch.cls](../force-app/main/default/classes/ExportInvoiceSageBatch.cls) - Invoice export batch job
- [force-app/main/default/classes/ExportVendorInvoiceSageBatch.cls](../force-app/main/default/classes/ExportVendorInvoiceSageBatch.cls) - Vendor invoice export batch job
- [force-app/main/default/classes/SageRLCSSupplierQueueable.cls](../force-app/main/default/classes/SageRLCSSupplierQueueable.cls) - RLCS supplier sync
- [force-app/main/default/classes/SageCustomerQueueable.cls](../force-app/main/default/classes/SageCustomerQueueable.cls) - Customer sync

**Configuration Files:**
- [force-app/main/default/namedCredentials/SIA.namedCredential-meta.xml](../force-app/main/default/namedCredentials/SIA.namedCredential-meta.xml) - Named Credential configuration
- [force-app/main/default/authproviders/Sage.authprovider-meta.xml](../force-app/main/default/authproviders/Sage.authprovider-meta.xml) - OAuth Auth Provider configuration

**Custom Settings:**
- `Sage_API_Settings__c` - Custom setting with endpoint prefixes and API keys

### Related Documentation

- [RLCS_VENDOR_INVOICE_SAGE_EXPORT_FIX.md](RLCS_VENDOR_INVOICE_SAGE_EXPORT_FIX.md) - Previous RLCS Vendor Invoice issue (different root cause)

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
- **Advantage:** Single place to manage authentication
- **Disadvantage:** One authentication failure affects all systems
- Consider separate Named Credentials if systems need independent auth

### 4. HTTP 401 vs HTTP 403

- **HTTP 401 Unauthorized:** Authentication failed (invalid/expired credentials)
- **HTTP 403 Forbidden:** Authenticated but not authorized (permission issue)

This scenario is 401, meaning the OAuth token is the issue, not Sage permissions.

### 5. Monitoring is Critical for Scheduled Jobs

Scheduled jobs fail silently unless monitored:
- Enable email alerts for Apex job failures
- Create dashboards for integration health
- Set up proactive authentication checks

---

## Recommendations

### Immediate Actions

1. ✅ **Re-authenticate SIA Named Credential** (resolves current issue)
2. ✅ **Test invoice export with Ania** (verify fix)
3. ✅ **Monitor scheduled jobs for 48 hours** (ensure stability)
4. ✅ **Document Sage service account credentials** (for future re-auth)

### Short-Term Improvements

1. **Set Up Monitoring**
   - Create health check scheduled job
   - Enable email alerts for Sage API failures
   - Build Salesforce dashboard for integration metrics

2. **Document Process**
   - Create runbook for re-authenticating Named Credential
   - Document Sage service account details (securely)
   - Record Consumer Key/Secret locations

3. **Test Backup Access**
   - Verify multiple admins can re-authenticate
   - Test re-authentication process in Sandbox first
   - Document step-by-step with screenshots

### Long-Term Considerations

1. **Evaluate Separate Named Credentials**
   - Consider separate Named Credentials for RLES vs RLCS
   - Pros: Isolated authentication, independent failure
   - Cons: More complex management, duplicate configuration

2. **Implement Proactive Re-authentication**
   - Schedule quarterly re-authentication
   - Set calendar reminders before 60-day mark
   - Create checklist for authentication renewal

3. **OAuth Token Refresh Handling**
   - Verify `offline_access` scope is working
   - Test if Salesforce successfully refreshes tokens
   - Check Sage API token expiration policies

4. **Consider Certificate-Based Auth**
   - Evaluate if Sage API supports certificate authentication
   - Certificates don't expire as frequently as OAuth tokens
   - More secure than password-based OAuth

---

## Troubleshooting Guide

### Issue: Re-authentication Doesn't Fix 401 Error

**Possible Causes:**
1. Consumer Secret in Auth Provider is incorrect
2. Sage service account locked or disabled
3. OAuth app configuration changed in Sage portal
4. Network/firewall blocking OAuth flow

**Steps:**
1. Verify Consumer Key and Consumer Secret in Auth Provider
2. Test Sage credentials by logging into Sage web UI
3. Check Sage developer portal for OAuth app status
4. Review Salesforce Setup Audit Trail for configuration changes

### Issue: OAuth Flow Redirects to Error Page

**Possible Causes:**
1. Callback URL mismatch in Sage OAuth app
2. Scopes changed or invalid
3. Sage API permissions not granted to service account

**Steps:**
1. Verify callback URL in Sage matches Salesforce Auth Provider URL
2. Check scopes in Auth Provider match Sage OAuth app
3. Verify service account has API access permissions in Sage

### Issue: Works for Some Users, Not Others

**Possible Causes:**
1. Named Credential Principal Type is **NamedUser** (not **PerUser**)
2. Named Credential authenticated by one user, not available to others

**Steps:**
1. Check Named Credential Principal Type
2. If PerUser, each user needs to authenticate individually
3. If NamedUser, verify the authenticated user account is still valid

### Issue: Scheduled Jobs Still Failing After Re-auth

**Possible Causes:**
1. Scheduled jobs running under different user context
2. Queueable jobs queued before re-authentication
3. Different Sage API endpoint having issues

**Steps:**
1. Check **Setup → Scheduled Jobs** to see which user runs the job
2. Cancel and re-queue any queued jobs
3. Test individual API endpoints with Anonymous Apex
4. Check Sage API status page for service disruptions

---

**Resolution Date:** 2025-10-17
**Resolved By:** Shintu John (Administrator)
**Documented By:** Shintu John (via Claude Code)
**Affected Users:** Ania, all users exporting to Sage, scheduled sync jobs
**Status:** ✅ **RESOLVED - Authentication Successfully Restored**

---

## Follow-Up Checklist

After re-authentication, complete these steps:

- [x] Re-authenticate SIA Named Credential *(Completed 2025-10-17)*
- [x] Test invoice export (Ania or admin) *(Verified via API test)*
- [x] Verify scheduled jobs succeed (check Apex Jobs) *(All jobs completing successfully)*
- [ ] Monitor for 48 hours for any recurring 401 errors *(In progress)*
- [x] Update this document with resolution date and deployment details *(Completed 2025-10-17)*
- [ ] Create monitoring dashboard (recommended)
- [ ] Document Sage service account credentials (securely)
- [ ] Schedule next authentication check (60 days) - **Due: 2025-12-16**
- [ ] Send notification email to users confirming fix
- [x] Update status in this document to ✅ Resolved *(Completed 2025-10-17)*

### Verification Results (2025-10-17)

**API Connection Test:**
- ✅ No HTTP 401 errors detected
- ✅ OAuth authentication successful for both RLES and RLCS
- ✅ Named Credential "SIA" properly authenticated

**Scheduled Jobs Status (Today):**
- ✅ `ExportInvoiceSageBatch` - Completed at 07:10:52 UTC (0 errors)
- ✅ `SageRLCSSupplierQueueable` - Completed at 04:55:02 UTC (0 errors)
- ✅ `SageCustomerQueueable` - Completed at 04:15:10 UTC (0 errors)

**Comparison:** Previously these jobs were failing with HTTP 401 errors. Now all completing successfully.

### Failure Timeline (Before Fix)

**Failed Jobs History:**

| Date/Time | Job | Status | Error |
|-----------|-----|--------|-------|
| 2025-10-15 (multiple) | SageRLCSSupplierQueueable | ❌ Failed | `HTTP Error: 401 -` |
| 2025-10-15 (multiple) | SageCustomerQueueable | ❌ Failed | `HTTP Error: 401 -` |
| 2025-10-16 04:15:00 | SageCustomerQueueable | ❌ Failed | `HTTP Error: 401 -` |
| 2025-10-16 04:55:00 | SageRLCSSupplierQueueable | ❌ Failed | `HTTP Error: 401 -` |
| **2025-10-17 (After Fix)** | | | |
| 2025-10-17 04:15:10 | SageCustomerQueueable | ✅ **Completed** | 0 errors |
| 2025-10-17 04:55:02 | SageRLCSSupplierQueueable | ✅ **Completed** | 0 errors |

**Total Failed Jobs Found:** 8+ job failures with identical HTTP 401 errors

**Root Cause:** OAuth access token expired, refresh token could not refresh automatically

**Resolution:** Re-authenticated SIA Named Credential via Setup → Named Credentials → SIA → Authenticate

---

**Last Updated:** 2025-10-17
**Resolution Completed:** 2025-10-17
**Next Authentication Review:** 2025-12-16 (60 days from resolution)
