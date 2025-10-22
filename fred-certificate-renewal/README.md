# FRED Integration Certificate Renewal - OldOrg Configuration

⚠️ **SCENARIO TYPE: CONFIGURATION/CERTIFICATE RENEWAL - NOT A CODE DEPLOYMENT**

**Certificate Name**: FRED_Updater_NGINX_Client_Cert
**Current Expiration**: November 9, 2025 (16 days remaining as of Oct 22, 2025)
**Org**: OldOrg (Recycling Lives Service - PRODUCTION)
**Integration**: FRED Updater Service (DBS System)
**Status**: ⚠️ URGENT - Certificate expires in 16 days
**Type**: Configuration/Procedure Documentation

---

## ⚠️ Important: This is a Configuration Scenario

**What This Document Is**:
- Certificate renewal procedure for FRED Integration
- Configuration guide for Salesforce certificate management
- Step-by-step instructions for certificate import and Named Credential update

**What This Is NOT**:
- NOT a code deployment
- NOT Apex/Trigger/Flow changes
- NOT new functionality

**Action Required**: Certificate renewal before November 9, 2025

---

## Overview

The FRED Integration uses mutual TLS (mTLS) authentication with a client certificate to communicate securely between Salesforce and an external FRED Updater service through an NGINX reverse proxy.

### Current Certificate Status (OldOrg)

**Certificate Details**:
- **Certificate Name**: FRED_Updater_NGINX_Client_Cert
- **Salesforce ID**: 0P1Sj00000000KzKAI
- **Expiration Date**: November 9, 2025 at 12:00 PM UTC
- **Days Remaining**: 16 days (as of October 22, 2025)
- **Purpose**: Client authentication for NGINX mutual TLS
- **Type**: X.509 Client Certificate

**Certificate Location in Salesforce**:
- Setup → Certificate and Key Management
- Certificate Name: FRED_Updater_NGINX_Client_Cert

---

## Integration Architecture

### Named Credential Configuration

**Named Credential: DBS**
- **Salesforce ID**: 0XA4H0000008PCIWA2
- **URL**: https://fred-updater.recyclinglives-services.com
- **Authentication Protocol**: NamedUser
- **Identity Type**: Named Principal
- **Certificate**: FRED_Updater_NGINX_Client_Cert (current)

**Purpose**: This Named Credential is used by Apex code to make callouts to the FRED Updater service.

---

### Components Using This Certificate

**Apex Callouts**:
Any Apex classes making HTTP callouts to:
- `callout:DBS/...` (using Named Credential)
- Direct references to `https://fred-updater.recyclinglives-services.com`

**To Find Components**:
```sql
-- Search for Apex classes using this Named Credential
SELECT Id, Name, Body
FROM ApexClass
WHERE Body LIKE '%callout:DBS%'
OR Body LIKE '%fred-updater.recyclinglives-services.com%'
```

**Potential Integration Points**:
- Scheduled Apex jobs
- Batch Apex classes
- Platform Events
- Flows with HTTP Callout actions

---

## Why This Certificate is Critical

### What Happens When Certificate Expires

⚠️ **On November 9, 2025 at 12:00 PM UTC:**

1. **Authentication Failure**:
   - Salesforce will no longer be able to authenticate with FRED Updater service
   - NGINX server will reject all requests from Salesforce
   - SSL/TLS handshake will fail

2. **Integration Breakdown**:
   - All callouts to `callout:DBS` will fail
   - Data synchronization between Salesforce and FRED will stop
   - Any automated processes relying on FRED data will fail

3. **Business Impact**:
   - Loss of real-time data exchange
   - Potential data inconsistencies
   - Manual workarounds required until certificate is renewed

---

## Certificate Renewal Timeline

| Date | Days Remaining | Milestone | Action Required |
|------|---------------|-----------|-----------------|
| October 22, 2025 | 18 days | Documentation Created | Review renewal procedure |
| October 25, 2025 | 15 days | Target: Receive New Certificate | Infrastructure team generates certificate |
| November 2, 2025 | 7 days | **Deadline: Deploy New Certificate** | Import to Salesforce, update Named Credential |
| November 2-9, 2025 | 0-7 days | Transition Period | NGINX accepts both old and new certificates |
| November 9, 2025 | 0 days | ⚠️ **OLD CERTIFICATE EXPIRES** | Must be complete by this date |

**Recommended Completion**: By November 2, 2025 (7 days before expiration)

---

## Certificate Renewal Process Overview

### Two Approaches Available

#### Approach A: Complete Certificate Package (RECOMMENDED ⭐)

**Process**:
1. Infrastructure team generates complete certificate package (.p12 format)
2. Package includes both certificate and private key
3. Salesforce Admin imports .p12 file to Salesforce
4. Update Named Credential to use new certificate

**Advantages**:
- ✅ Simpler (fewer steps)
- ✅ Faster (2-3 days total)
- ✅ Avoids Salesforce CSR technical issues
- ✅ Standard industry practice
- ✅ Less prone to errors

**Timeline**:
- Day 1: Request certificate from Infrastructure
- Day 2-3: Infrastructure generates and delivers .p12 file
- Day 3: Import to Salesforce and test
- Day 4: Deploy to production

---

#### Approach B: CSR-Based Approach (ALTERNATIVE)

**Process**:
1. Salesforce Admin generates CSR (Certificate Signing Request)
2. Send CSR to Infrastructure team
3. Infrastructure signs CSR and returns certificate
4. Salesforce Admin imports signed certificate

**Challenges**:
- ⚠️ CSR download option not available in Salesforce UI (technical limitation)
- ⚠️ More complex process
- ⚠️ More prone to compatibility issues

**Status**: Not recommended due to Salesforce CSR limitations

---

## Detailed Renewal Instructions (Approach A - Recommended)

### Step 1: Request Certificate from Infrastructure

**Email Template** (copy and send):

```
Subject: FRED Certificate Renewal - Request for Complete Certificate Package (PRODUCTION)

Hi [Infrastructure Engineer Name],

Could you please generate a complete client certificate package for our FRED integration?

WHAT I NEED:
• File Format: PKCS#12 (.p12 or .pfx file)
• Must contain: Certificate + Private Key
• Password protected (minimum 12 characters)
• Key size: 4096-bit RSA
• Validity: 1 year (Nov 2025 - Nov 2026)
• Purpose: Client Authentication for NGINX mutual TLS

ENVIRONMENT: PRODUCTION
• Salesforce Org: Recycling Lives Service (OldOrg)
• Integration: FRED Updater
• Endpoint: https://fred-updater.recyclinglives-services.com
• Current Certificate Expiration: November 9, 2025 (16 days remaining)

DELIVERY:
• Send .p12 file via secure method (encrypted email/secure file share)
• Send password via SEPARATE channel (phone, encrypted message)

NGINX CONFIGURATION:
• Install new certificate on NGINX server
• Accept BOTH old and new certificates during transition (Nov 2-9)

TARGET TIMELINE:
• October 25: Receive certificate
• November 2: Deploy to Salesforce
• November 9: Old certificate expires

Please confirm you can generate this and provide an estimated delivery date.

Thank you!
[Your Name]
[Your Email]
[Your Phone]
```

---

### Step 2: Receive and Verify Certificate

**You'll Receive**:
- File: `fred-updater-client-cert-2025.p12` (or similar name)
- Password: Via separate secure channel

**Pre-Import Verification**:

1. **Verify file integrity**:
   ```bash
   # On Mac/Linux, verify .p12 file
   openssl pkcs12 -in fred-updater-client-cert-2025.p12 -noout -info
   # Enter password when prompted
   # Should show certificate and key information
   ```

2. **Check certificate details**:
   ```bash
   openssl pkcs12 -in fred-updater-client-cert-2025.p12 -nokeys -clcerts | openssl x509 -noout -text
   # Verify:
   # - Subject/Issuer information
   # - Validity dates (should be Nov 2025 - Nov 2026)
   # - Key size (should be 4096-bit RSA)
   ```

---

### Step 3: Import Certificate to Salesforce

**Import Steps**:

1. **Navigate to Certificate Management**:
   - Setup → Quick Find → "Certificate"
   - Click: Certificate and Key Management

2. **Import from Keystore**:
   - Click: **"Import from Keystore"** button
   - Browse and select: `fred-updater-client-cert-2025.p12`
   - Enter password (received separately)
   - Click: **Next**

3. **Configure Certificate**:
   - **Certificate Unique Name**: `FRED_Updater_NGINX_Client_Cert_2025`
   - **Certificate Label**: `FRED Updater NGINX Client Certificate 2025`
   - **Description**: `Client certificate for FRED Updater mTLS authentication. Valid Nov 2025 - Nov 2026. Replaces cert expiring Nov 9, 2025.`
   - **Exportable Private Key**: ⚠️ **UNCHECK THIS** (security best practice)
   - Click: **Save**

4. **Verify Import**:
   - Confirm certificate appears in list
   - Check expiration date matches expected (Nov 2026)
   - Verify certificate ID is generated

---

### Step 4: Update Named Credential

**Update Steps**:

1. **Navigate to Named Credentials**:
   - Setup → Quick Find → "Named Credentials"
   - Click: Named Credentials

2. **Edit DBS Named Credential**:
   - Find: **DBS** Named Credential
   - Click: **Edit** (dropdown arrow → Edit)

3. **Change Certificate**:
   - **Certificate**: Change from `FRED_Updater_NGINX_Client_Cert` to `FRED_Updater_NGINX_Client_Cert_2025`
   - **DO NOT change** any other settings
   - Click: **Save**

---

### Step 5: Test Integration

**Test Method 1: Anonymous Apex**

```apex
// Execute in Developer Console → Execute Anonymous

HttpRequest req = new HttpRequest();
req.setEndpoint('callout:DBS/test'); // Adjust path as needed
req.setMethod('GET');
req.setTimeout(10000);

try {
    Http http = new Http();
    HTTPResponse res = http.send(req);
    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Status: ' + res.getStatus());
    System.debug('Body: ' + res.getBody());

    if(res.getStatusCode() == 200) {
        System.debug('✅ SUCCESS: Certificate authentication working');
    } else {
        System.debug('⚠️ WARNING: Unexpected status code');
    }
} catch(Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
}
```

**Expected Result**: Status Code 200 (or expected response from FRED service)

---

**Test Method 2: Check Existing Scheduled Jobs**

```sql
-- Find scheduled jobs that might use FRED integration
SELECT Id, Name, State, NextFireTime, CronExpression
FROM CronTrigger
WHERE State = 'WAITING'
ORDER BY NextFireTime ASC
```

Monitor job executions after certificate renewal to ensure no failures.

---

### Step 6: Monitor Integration

**Monitoring Period**: November 2-9, 2025 (transition period)

**What to Monitor**:

1. **Apex Logs**:
   - Setup → Debug Logs
   - Create debug logs for users making FRED callouts
   - Monitor for SSL/certificate errors

2. **System Debug Logs**:
   ```sql
   SELECT Id, Application, DurationMilliseconds, Operation, Status, StartTime
   FROM ApexLog
   WHERE Operation LIKE '%FRED%' OR Request LIKE '%callout:DBS%'
   AND StartTime >= TODAY
   ORDER BY StartTime DESC
   ```

3. **Callout Errors**:
   - Check for `System.CalloutException`
   - Check for SSL handshake failures
   - Check for authentication errors

---

### Step 7: Decommission Old Certificate (After Nov 9, 2025)

**Post-Expiration Cleanup**:

1. **Wait until November 10, 2025** (day after old cert expires)

2. **Verify new certificate is working**:
   - No integration errors reported
   - All FRED callouts succeeding
   - Business processes operating normally

3. **Optional: Delete old certificate**:
   - Setup → Certificate and Key Management
   - Find: `FRED_Updater_NGINX_Client_Cert` (old cert)
   - Click: **Delete**
   - Confirm deletion

**Note**: Salesforce does not automatically delete expired certificates. Manual cleanup is optional but recommended for security hygiene.

---

## Rollback Plan

### If New Certificate Doesn't Work

**Symptoms**:
- Callouts to `callout:DBS` fail
- SSL/TLS handshake errors
- Authentication failures

**Rollback Steps** (only works BEFORE November 9, 2025):

1. **Revert Named Credential**:
   - Setup → Named Credentials → DBS → Edit
   - Change Certificate back to: `FRED_Updater_NGINX_Client_Cert` (old cert)
   - Save

2. **Verify Old Certificate Works**:
   - Run test callouts (Step 5 above)
   - Monitor for errors

3. **Troubleshoot New Certificate**:
   - Contact Infrastructure team
   - Verify NGINX configuration
   - Check certificate format/compatibility

4. **Retry with Fixed Certificate**:
   - Obtain corrected certificate from Infrastructure
   - Re-import and test

**Important**: Rollback only works BEFORE old certificate expires. After November 9, 2025, old certificate will not work regardless.

---

## Contact Information

### Infrastructure Team

**Primary Contact**: [Infrastructure Engineer Name]
- **Email**: [email@recyclinglives-services.com]
- **Phone**: [phone number]
- **Responsibilities**: Certificate generation, NGINX configuration

### Salesforce Admin Team

**Primary Contact**: [Salesforce Admin Name]
- **Email**: [email@recyclinglives-services.com]
- **Phone**: [phone number]
- **Responsibilities**: Certificate import, Named Credential updates

---

## Post-Renewal Documentation

### Certificate Details (After Renewal)

**New Certificate**:
- **Name**: FRED_Updater_NGINX_Client_Cert_2025
- **Salesforce ID**: [To be recorded after import]
- **Expiration Date**: November 2026 (exact date TBD)
- **Imported Date**: [To be recorded]
- **Imported By**: [To be recorded]

**Named Credential Update**:
- **Named Credential**: DBS
- **Updated Date**: [To be recorded]
- **Updated By**: [To be recorded]
- **New Certificate**: FRED_Updater_NGINX_Client_Cert_2025

---

## Next Renewal

**Certificate Expiration**: November 2026 (exact date TBD after renewal)
**Renewal Timeline**: Start renewal process by October 2026 (30 days before expiration)
**Renewal Procedure**: Use this document as reference

**Reminder**: Set calendar reminder for October 1, 2026 to begin next renewal cycle.

---

## Appendix: Technical Details

### Certificate Specifications

**Format**: PKCS#12 (.p12 or .pfx)
**Key Algorithm**: RSA
**Key Size**: 4096-bit
**Signature Algorithm**: SHA-256 with RSA
**Validity Period**: 1 year
**Purpose**: Client Authentication (TLS Web Client Authentication)

### NGINX Configuration Requirements

**Server-Side Configuration** (managed by Infrastructure):
- Accept both old and new client certificates during transition period
- Verify client certificate against trusted CA
- Mutual TLS (mTLS) enabled
- Strong cipher suites configured

---

## Related Documentation

- **Quick Start Guide**: FRED_CERTIFICATE_RENEWAL_QUICK_START.md
- **Complete Renewal Guide**: FRED_INTEGRATION_NGINX_CERTIFICATE_RENEWAL_GUIDE.md (source documentation)

---

**Document Version**: 1.0
**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Status**: Ready for Action - Certificate Expires in 16 Days
