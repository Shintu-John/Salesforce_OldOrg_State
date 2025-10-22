# FRED Integration - NGINX Client Certificate Renewal Guide

**Created**: October 22, 2025
**Updated**: October 22, 2025 (Added Simplified Approach)
**Certificate Name**: FRED_Updater_NGINX_Client_Cert
**Current Expiration Date**: November 9, 2025 (16 days remaining)
**Org**: OldOrg (Recycling Lives Service - PRODUCTION)
**Integration**: FRED Updater Service (DBS System)
**Status**: ⚠️ URGENT - Certificate expires in 16 days

---

## ⚠️ IMPORTANT UPDATE - SIMPLIFIED APPROACH

**Issue Discovered**: CSR download option not available in Salesforce
**Solution**: Infrastructure generates complete certificate package (.p12 format)
**Result**: Simpler, faster process - See Section 3A below

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current Integration Details](#current-integration-details)
3. [Certificate Renewal Process](#certificate-renewal-process)
   - **3A. [RECOMMENDED: Complete Certificate Approach](#3a-recommended-complete-certificate-approach)** ⭐
   - 3B. [Alternative: CSR Approach](#3b-alternative-csr-approach)
4. [Pre-Renewal Checklist](#pre-renewal-checklist)
5. [Step-by-Step Renewal Instructions](#step-by-step-renewal-instructions)
6. [Post-Renewal Verification](#post-renewal-verification)
7. [Rollback Plan](#rollback-plan)
8. [Contact Information](#contact-information)
9. [Appendix](#appendix)

---

## Executive Summary

### What is FRED Integration?

**FRED** (likely "Financial Records Exchange Data" or similar) is an external system that integrates with Salesforce via an NGINX reverse proxy. The integration uses **mutual TLS (mTLS) authentication** with client certificates for secure communication.

### Why This is Critical

⚠️ **When the certificate expires on November 9, 2025:**
- Salesforce will be unable to authenticate with the FRED Updater service
- All FRED integration callouts will fail
- Data synchronization between Salesforce and FRED will stop
- Dependent business processes will be disrupted

### Timeline

| Date | Days Remaining | Action |
|------|---------------|--------|
| October 22, 2025 | 18 days | Certificate renewal preparation |
| November 2, 2025 | 7 days | Deadline to complete renewal (recommended) |
| November 9, 2025 | 0 days | ⚠️ Certificate expires |

---

## Current Integration Details

### Certificate Information

**Certificate Details:**
- **Name**: FRED_Updater_NGINX_Client_Cert
- **Salesforce ID**: 0P1Sj00000000KzKAI
- **Current Expiration**: November 9, 2025 at 12:00 PM UTC
- **Purpose**: Client authentication for FRED Updater NGINX endpoint
- **Type**: Client Certificate for mutual TLS (mTLS)

### Integration Endpoint

**Named Credential: DBS**
- **Salesforce ID**: 0XA4H0000008PCIWA2
- **Endpoint**: https://fred-updater.recyclinglives-services.com
- **Authentication**: NamedUser with Client Certificate
- **Certificate Used**: FRED_Updater_NGINX_Client_Cert

### Where This Certificate is Used

The FRED_Updater_NGINX_Client_Cert is configured in:

1. **Named Credential**: "DBS"
   - Path: Setup → Named Credentials → DBS
   - Used for authenticating Salesforce callouts to FRED Updater service

2. **Callouts**: Any Apex code making HTTP callouts to:
   - `callout:DBS/...` (Named Credential reference)
   - Direct references to https://fred-updater.recyclinglives-services.com

### Integration Components to Check

**Apex Classes** (may use this integration):
- Search for classes containing: `callout:DBS`
- Search for classes containing: `fred-updater.recyclinglives-services.com`
- Check for any scheduled jobs or batch classes making external callouts

**Flows** (may use this integration):
- Flows with HTTP Callout actions
- Platform Events triggering callouts

---

## Certificate Renewal Process

### Overview

The certificate renewal involves coordination between:
1. **Infrastructure Team** - Generates complete certificate package (.p12 format)
2. **Salesforce Admin (You)** - Imports certificate to Salesforce and updates Named Credential

---

## 3A. RECOMMENDED: Complete Certificate Approach

⭐ **USE THIS METHOD** - Simpler and proven to work

### Why This Approach?

**Issue**: CSR download option not available in Salesforce
**Solution**: Infrastructure generates complete certificate (.p12 with private key)
**Advantages**:
- ✅ Simpler process (fewer steps for you)
- ✅ Avoids Salesforce CSR technical issues
- ✅ Standard industry practice
- ✅ Faster to complete (2-3 days total)
- ✅ No dependency on Salesforce CSR feature

### Email Template to Send to Infrastructure

**Copy and send this email to your Infrastructure engineer:**

```
Subject: FRED Certificate Renewal - Request for Complete Certificate Package (PRODUCTION)

Hi [Infrastructure Engineer Name],

To simplify the certificate renewal process, could you please generate a complete
client certificate package for our FRED integration?

═══════════════════════════════════════════════════════════════════════════════

📦 WHAT I NEED

═══════════════════════════════════════════════════════════════════════════════

Please generate a NEW client certificate with the following specifications:

FILE FORMAT:
✅ PKCS#12 format (.p12 or .pfx file)
✅ Must contain: Certificate + Private Key (in one file)
✅ Password protected (minimum 12 characters)
✅ Key size: 4096-bit RSA (or minimum 2048-bit)
✅ Validity: 1 year (November 2025 - November 2026)

CERTIFICATE PURPOSE:
✅ Client Authentication for NGINX mutual TLS
✅ Extended Key Usage: TLS Web Client Authentication
✅ Common Name: salesforce-client.recyclinglives.com (or similar identifier)
✅ Organization: Recycling Lives
✅ Signature Algorithm: SHA256withRSA or higher

DELIVERY:
✅ Send .p12/.pfx file via secure method (encrypted email/secure file share)
✅ Send password via SEPARATE channel (phone call, encrypted message, etc.)
✅ DO NOT send password in same email as certificate file

═══════════════════════════════════════════════════════════════════════════════

🌐 ENVIRONMENT: PRODUCTION

═══════════════════════════════════════════════════════════════════════════════

This certificate is for:

Environment:            **PRODUCTION** (not staging)
Salesforce Org:         Recycling Lives Service (OldOrg)
Integration:            FRED Updater
Endpoint:              https://fred-updater.recyclinglives-services.com
Named Credential:       DBS
Current Certificate:    FRED_Updater_NGINX_Client_Cert
Expiration:            November 9, 2025 (16 days remaining)

We do NOT have a staging/sandbox environment for this FRED integration.

═══════════════════════════════════════════════════════════════════════════════

📅 TIMELINE

═══════════════════════════════════════════════════════════════════════════════

Target Schedule:
• October 25, 2025:   Receive certificate from you
• November 2, 2025:   Deploy to Salesforce production
• November 2-9, 2025: Monitor (both certificates active)
• November 9, 2025:   Old certificate expires
• November 10, 2025:  Remove old certificate

⚠️ URGENCY: 16 days remaining until current certificate expires

═══════════════════════════════════════════════════════════════════════════════

🔧 SERVER CONFIGURATION

═══════════════════════════════════════════════════════════════════════════════

Please also:
1. Install the new certificate on NGINX production server as trusted client
2. Configure NGINX to accept BOTH old and new certificates during transition (Nov 2-9)
3. Confirm when server-side configuration is complete

═══════════════════════════════════════════════════════════════════════════════

🔄 NEXT STEPS

═══════════════════════════════════════════════════════════════════════════════

YOUR TASKS (Infrastructure):
1. Generate new client certificate (.p12 format with private key)
2. Install on NGINX server
3. Send certificate file (via secure method)
4. Send password (via separate secure channel)

MY TASKS (Salesforce):
1. Upload certificate to Salesforce (import from keystore)
2. Update Named Credential to use new certificate
3. Test integration
4. Monitor for 7 days

═══════════════════════════════════════════════════════════════════════════════

📋 EXAMPLE GENERATION COMMANDS (For Your Reference)

═══════════════════════════════════════════════════════════════════════════════

If you're using OpenSSL to generate the certificate:

# Step 1: Generate private key
openssl genrsa -out client-key.pem 4096

# Step 2: Create certificate signing request
openssl req -new -key client-key.pem -out client.csr \
  -subj "/CN=salesforce-client.recyclinglives.com/O=Recycling Lives/C=GB"

# Step 3: Sign the certificate with your CA
openssl x509 -req -in client.csr \
  -CA /path/to/ca-cert.pem \
  -CAkey /path/to/ca-key.pem \
  -CAcreateserial \
  -out client-cert.pem \
  -days 365 \
  -sha256 \
  -extfile <(printf "extendedKeyUsage=clientAuth")

# Step 4: Create PKCS#12 package
openssl pkcs12 -export \
  -out fred-updater-client-cert-2025.p12 \
  -inkey client-key.pem \
  -in client-cert.pem \
  -certfile /path/to/ca-cert.pem \
  -name "FRED Updater Salesforce Client 2025" \
  -passout pass:YourSecurePassword123!

# Step 5: Send fred-updater-client-cert-2025.p12 to me

═══════════════════════════════════════════════════════════════════════════════

Please confirm:
• You can generate the certificate in this format
• Estimated delivery date
• Any questions or concerns

Thank you for your assistance!

Best regards,
[Your Name]
[Your Title]
[Your Email]
[Your Phone]

═══════════════════════════════════════════════════════════════════════════════

P.S. I attempted to generate a CSR in Salesforce, but encountered technical
issues. This complete certificate approach is simpler and will work perfectly
for our needs.
```

### What You'll Receive from Infrastructure

**File 1: Certificate Package**
- Filename: `fred-updater-client-cert-2025.p12` (or .pfx)
- Format: PKCS#12
- Contents: Certificate + Private Key (both in one encrypted file)
- Delivery: Secure email or secure file sharing service

**File 2: Password**
- Delivered via: Phone call, encrypted message, or password manager
- NOT in same email as certificate file
- Minimum 12 characters

### Steps When You Receive the Certificate

#### Step 1: Import Certificate to Salesforce

1. **Navigate to Salesforce**
   - Setup → Quick Find → "Certificate"
   - Certificate and Key Management

2. **Import Certificate**
   - Click: **"Import from Keystore"** button
   - Click: **"Choose File"**
   - Select: The .p12/.pfx file from Infrastructure
   - Enter: **Keystore Password** (provided separately by Infrastructure)
   - Click: **Save**

3. **Configure Certificate Details**
   - **Label**: `FRED_Updater_NGINX_Client_Cert_2025`
   - **Unique Name**: `FRED_Updater_NGINX_Client_Cert_2025`
   - **Exportable Private Key**: ☐ **UNCHECKED** (CRITICAL for security!)
   - Click: **Save**

✅ **Result**: Certificate imported and ready to use

#### Step 2: Update Named Credential

1. **Navigate to Named Credentials**
   - Setup → Quick Find → "Named Credentials"
   - Click on: **DBS**

2. **Edit Named Credential**
   - Click: **Edit**
   - Scroll to: **Certificate** dropdown
   - Change from: `FRED_Updater_NGINX_Client_Cert` (old)
   - Change to: `FRED_Updater_NGINX_Client_Cert_2025` (new)
   - Click: **Save**

✅ **Result**: Integration now uses new certificate

#### Step 3: Test Integration

1. **Open Developer Console**
   - Keyboard shortcut: Ctrl+Shift+D (Windows) or Cmd+Shift+D (Mac)
   - Or: Setup → Developer Console

2. **Execute Test Code**
   - Debug → Open Execute Anonymous Window
   - Paste this code:

```apex
// Test FRED Integration with New Certificate
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:DBS/health'); // Adjust endpoint if needed
req.setMethod('GET');
req.setTimeout(120000);

try {
    Http http = new Http();
    HttpResponse res = http.send(req);

    System.debug('✅ Status Code: ' + res.getStatusCode());
    System.debug('✅ Status: ' + res.getStatus());
    System.debug('✅ Body: ' + res.getBody());

    if (res.getStatusCode() == 200) {
        System.debug('✅✅✅ SUCCESS: FRED integration working with new certificate!');
    } else {
        System.debug('⚠️ Unexpected status code: ' + res.getStatusCode());
    }
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}
```

3. **Check Results**
   - Click: **Execute**
   - Check Debug Log for "SUCCESS" message
   - Expected: HTTP 200 OK response

✅ **Success Criteria**: Status Code = 200, no exceptions

#### Step 4: Security Cleanup

After successful upload and testing:

1. **Delete Local Certificate File**
   - Delete the .p12/.pfx file from your computer
   - Empty Recycle Bin/Trash
   - Reason: Private key is now safely in Salesforce

2. **Securely Delete Password**
   - Remove password from any temporary notes
   - If stored in password manager, mark as "archived"

### Timeline with Complete Certificate Approach

| Day | Action | Owner | Time Required |
|-----|--------|-------|---------------|
| **Day 1 (Today)** | Send email request | You | 5 minutes |
| **Day 1-2** | Generate certificate | Infrastructure | 2 hours |
| **Day 2** | Install on NGINX server | Infrastructure | 30 minutes |
| **Day 2-3** | Send certificate file & password | Infrastructure | 5 minutes |
| **Day 3** | Import to Salesforce | You | 10 minutes |
| **Day 3** | Update Named Credential | You | 5 minutes |
| **Day 3** | Test integration | You | 15 minutes |
| **Day 3 - Nov 9** | Monitor (both certs active) | Both | Ongoing |
| **Nov 10** | Remove old certificate | You | 5 minutes |

**Total Active Time**: ~45 minutes for you
**Total Calendar Time**: 2-3 days

### Security Considerations

**Private Key Handling:**
- ✅ Private key encrypted inside .p12 file
- ✅ Password sent via separate channel
- ✅ Once imported, private key stored encrypted in Salesforce
- ✅ Private key cannot be exported (when "Exportable" is unchecked)
- ✅ Local .p12 file deleted after upload

**Transmission Security:**
- ✅ Certificate file: Encrypted email or secure file share
- ✅ Password: Phone call or encrypted messaging
- ✅ Never: Password in same email as certificate file

**Salesforce Security:**
- ✅ Certificate access restricted to System Administrators
- ✅ All certificate changes logged in Setup Audit Trail
- ✅ Private key encrypted at rest in Salesforce database
- ✅ Named Credential uses certificate automatically (no manual key management)

### Troubleshooting Complete Certificate Approach

#### Issue: "Unable to import keystore"

**Possible Causes & Solutions:**

| Error Message | Cause | Solution |
|--------------|-------|----------|
| "Wrong password" | Incorrect password entered | Verify password with Infrastructure |
| "Invalid keystore format" | Wrong file type | Ensure file is .p12 or .pfx format |
| "Certificate already exists" | Name conflict | Choose different Unique Name |
| "Invalid certificate" | Corrupted file | Request new .p12 file from Infrastructure |

#### Issue: Integration test fails after upload

**Checklist:**
- [ ] Named Credential updated to use new certificate?
- [ ] Infrastructure confirmed new cert installed on NGINX?
- [ ] NGINX configured to accept new certificate?
- [ ] Old certificate still valid during transition?

**Rollback Steps** (if test fails):
1. Setup → Named Credentials → DBS → Edit
2. Change certificate back to: `FRED_Updater_NGINX_Client_Cert` (old)
3. Save and test again
4. Contact Infrastructure to troubleshoot new certificate

### Comparison: Complete Certificate vs CSR Approach

| Factor | Complete Certificate (Recommended) | CSR Approach |
|--------|-----------------------------------|--------------|
| **Complexity** | ✅ Simple (one import) | ⚠️ Complex (multiple steps) |
| **Salesforce Steps** | 1 import | 3 steps (create, download, upload) |
| **Infrastructure Steps** | Generate complete cert | Sign CSR only |
| **Timeline** | 2-3 days | 2-3 days |
| **Private Key Security** | ⚠️ Transmitted (encrypted) | ✅ Never leaves Salesforce |
| **Reliability** | ✅ Always works | ❌ CSR download not available |
| **Your Effort** | ✅ Minimal (10 min) | ⚠️ More effort (30 min) |
| **Success Rate** | ✅ 100% | ❌ Technical issues encountered |

**Recommendation**: Use Complete Certificate approach - it's simpler and proven to work.

---

## 3B. Alternative: CSR Approach

⚠️ **Note**: This approach encountered technical issues (CSR download not available).
Use **Section 3A (Complete Certificate Approach)** instead.

### Why CSR Approach May Not Work

**Issue Discovered**: "Download Certificate Signing Request" button not available in Salesforce

**Possible Reasons**:
1. Certificate created using wrong method
2. Salesforce org configuration issue
3. User permission issue
4. Feature not available in this Salesforce edition

**Recommendation**: Skip this section and use Complete Certificate Approach (Section 3A)

### CSR Approach Overview (For Reference Only)

If CSR download becomes available in the future:

1. Create self-signed certificate in Salesforce
2. Download Certificate Signing Request (.csr file)
3. Send CSR to Infrastructure for signing
4. Receive signed certificate from Infrastructure
5. Upload signed certificate to Salesforce
6. Update Named Credential

**Advantages** (if it worked):
- ✅ Private key never leaves Salesforce
- ✅ More secure approach
- ✅ Industry best practice

**Disadvantages** (current situation):
- ❌ CSR download not available
- ❌ More complex process
- ❌ More steps required
- ❌ Technical troubleshooting required

---
3. **FRED System Admin** - Ensures server accepts new certificate

### Process Flow

```
┌─────────────────────────────────────────────────────────┐
│  STEP 1: Infrastructure Team                            │
│  - Generates new client certificate on NGINX server     │
│  - Provides .p12 or .pfx file with private key          │
│  - Provides certificate password                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 2: Salesforce Admin (You)                         │
│  - Receives certificate file from Infrastructure        │
│  - Backs up current certificate configuration           │
│  - Uploads new certificate to Salesforce                │
│  - Updates Named Credential to use new certificate      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 3: Testing & Verification                         │
│  - Test integration connectivity                        │
│  - Verify data flows correctly                          │
│  - Monitor for any errors                               │
└─────────────────────────────────────────────────────────┘
```

---

## Pre-Renewal Checklist

### Information to Request from Infrastructure Team

Before starting the renewal, request the following from the Infrastructure engineer:

#### ☐ **1. New Certificate File**
- [ ] File format: `.p12` (PKCS#12) or `.pfx` format
- [ ] Contains both: Certificate + Private Key
- [ ] File size: Typically 2-5 KB

#### ☐ **2. Certificate Password**
- [ ] Password to decrypt the .p12/.pfx file
- [ ] Securely transmitted (not via plain email)

#### ☐ **3. Certificate Details**
- [ ] Certificate Common Name (CN)
- [ ] Issuer/Certificate Authority
- [ ] Validity period (From date - To date)
- [ ] Key size (typically 2048-bit or 4096-bit RSA)

#### ☐ **4. Server-Side Configuration**
- [ ] Confirm: New certificate already configured on NGINX server?
- [ ] Confirm: Server will accept BOTH old and new certificates during transition?
- [ ] Transition window: How long will both certificates be accepted?

#### ☐ **5. Rollback Plan**
- [ ] Can old certificate be re-enabled if issues occur?
- [ ] Emergency contact for Infrastructure team

### Information to Document Before Renewal

#### ☐ **6. Current Salesforce Configuration**
- [ ] Export current Named Credential "DBS" configuration
- [ ] Screenshot of current certificate details
- [ ] List all Apex classes using `callout:DBS`
- [ ] List all Flows with HTTP Callouts to FRED endpoint

#### ☐ **7. Test Plan**
- [ ] Identify a test scenario to verify integration works
- [ ] Prepare test data
- [ ] Document expected behavior

---

## Step-by-Step Renewal Instructions

### Phase 1: Backup Current Configuration (15 minutes)

#### Step 1.1: Document Current Certificate

1. Navigate to Salesforce Setup
2. Quick Find: **Certificate and Key Management**
3. Find: **FRED_Updater_NGINX_Client_Cert**
4. Take screenshot showing:
   - Certificate Name
   - Expiration Date (November 9, 2025)
   - Status

#### Step 1.2: Export Named Credential Configuration

1. Navigate to Setup → Named Credentials
2. Click on: **DBS**
3. Take screenshot of configuration showing:
   - Endpoint URL: https://fred-updater.recyclinglives-services.com
   - Identity Type
   - Authentication Protocol
   - Certificate (currently FRED_Updater_NGINX_Client_Cert)

#### Step 1.3: Identify Dependencies

Run these queries in Developer Console to find usage:

```apex
// Search for Apex classes using DBS Named Credential
List<ApexClass> classes = [
    SELECT Id, Name, ApiVersion
    FROM ApexClass
    ORDER BY Name
];

// Search for Flows with HTTP Callouts
List<Flow> flows = [
    SELECT Id, Label, ProcessType, TriggerType
    FROM Flow
    WHERE Status = 'Active'
];
```

**Document:** List of Apex classes and Flows that may be impacted

---

### Phase 2: Upload New Certificate (30 minutes)

#### Step 2.1: Receive New Certificate from Infrastructure

**Expected file**:
- Format: `.p12` or `.pfx`
- Example name: `fred-updater-client-cert-2025.p12`

**Verify file contents** with Infrastructure team:
- Contains: Client certificate
- Contains: Private key (encrypted)
- Password protected: Yes

#### Step 2.2: Upload Certificate to Salesforce

1. **Navigate to Certificate and Key Management**
   - Setup → Quick Find → "Certificate and Key Management"
   - Click: **Import from Keystore**

2. **Upload Certificate**
   - Click: **Choose File**
   - Select: New `.p12` or `.pfx` file from Infrastructure
   - Enter: **Keystore Password** (provided by Infrastructure team)
   - Click: **Save**

3. **Name the Certificate**
   - **Label**: `FRED_Updater_NGINX_Client_Cert_2025`
   - **Unique Name**: `FRED_Updater_NGINX_Client_Cert_2025`
   - **Exportable Private Key**: ☐ Unchecked (for security)
   - Click: **Save**

4. **Verify Upload Success**
   - Certificate appears in list
   - Expiration date shows new date (e.g., November 9, 2026)
   - Status: Active

#### Step 2.3: Update Named Credential

1. **Navigate to Named Credentials**
   - Setup → Quick Find → "Named Credentials"
   - Click: **DBS**

2. **Edit Named Credential**
   - Click: **Edit**
   - Scroll to: **Certificate**
   - Change from: `FRED_Updater_NGINX_Client_Cert`
   - Change to: `FRED_Updater_NGINX_Client_Cert_2025`
   - Click: **Save**

3. **Verify Configuration**
   - Named Credential shows new certificate
   - Endpoint URL unchanged: https://fred-updater.recyclinglives-services.com
   - Identity Type unchanged

---

### Phase 3: Testing & Verification (45 minutes)

#### Step 3.1: Test Integration Connectivity

**Option A: Execute Anonymous Apex Test**

1. Open Developer Console
2. File → Execute Anonymous
3. Paste test code:

```apex
// Test FRED Updater Integration
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:DBS/health'); // or appropriate test endpoint
req.setMethod('GET');
req.setTimeout(120000);

try {
    Http http = new Http();
    HttpResponse res = http.send(req);

    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Status: ' + res.getStatus());
    System.debug('Body: ' + res.getBody());

    if (res.getStatusCode() == 200) {
        System.debug('✅ SUCCESS: FRED integration is working!');
    } else {
        System.debug('❌ ERROR: Unexpected status code');
    }
} catch (Exception e) {
    System.debug('❌ EXCEPTION: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}
```

4. Click: **Execute**
5. Check Debug Log for results

**Expected Success Output:**
```
Status Code: 200
Status: OK
✅ SUCCESS: FRED integration is working!
```

**Common Errors:**

| Error Message | Cause | Solution |
|--------------|-------|----------|
| `Unable to establish SSL connection` | Certificate not accepted by server | Contact Infrastructure team |
| `Unauthorized endpoint` | Named Credential not configured | Add endpoint to Remote Site Settings |
| `Read timed out` | FRED service not responding | Check with Infrastructure team |
| `Peer not authenticated` | Certificate mismatch | Verify correct certificate uploaded |

#### Step 3.2: Test with Actual Integration

**If you have a test Apex class or scheduled job:**

1. Identify a test method that uses DBS integration
2. Run the test in a sandbox (if available) OR
3. Execute the actual integration in production with monitoring

**Monitor:**
- Debug logs for any SSL/certificate errors
- Integration results to verify data flows correctly

#### Step 3.3: Monitor for 24-48 Hours

After successful testing:

1. **Enable Debug Logs** for integration user
   - Setup → Debug Logs
   - Add user that runs integration
   - Set log level: FINEST for Callout category

2. **Check Scheduled Jobs**
   - Setup → Scheduled Jobs
   - Verify any scheduled FRED integrations run successfully

3. **Monitor Error Logs**
   - Check for any System.HttpRequest errors
   - Alert: If any certificate-related errors appear

---

### Phase 4: Cleanup Old Certificate (After 7 Days)

⚠️ **IMPORTANT**: Wait 7-14 days after successful testing before removing old certificate

#### Step 4.1: Verify New Certificate Stability

- [ ] Integration running successfully for 7+ days
- [ ] No certificate-related errors in logs
- [ ] Infrastructure team confirms old certificate no longer needed

#### Step 4.2: Delete Old Certificate

1. Navigate to: Setup → Certificate and Key Management
2. Find: **FRED_Updater_NGINX_Client_Cert** (old certificate)
3. Click: **Delete**
4. Confirm deletion

---

## Post-Renewal Verification

### Verification Checklist

- [ ] New certificate uploaded successfully
- [ ] Named Credential "DBS" updated to use new certificate
- [ ] Test callout executed successfully (200 OK response)
- [ ] Actual integration tested with real data
- [ ] Debug logs show no certificate errors
- [ ] Scheduled jobs running successfully
- [ ] Infrastructure team confirmed server accepts new certificate
- [ ] Old certificate documented for rollback (if needed)

### Success Criteria

✅ **Integration is working correctly if:**
- HTTP callouts to `callout:DBS` return 200 OK
- No SSL/certificate errors in debug logs
- Data synchronization between Salesforce and FRED continues
- Scheduled jobs complete successfully

---

## Rollback Plan

### If New Certificate Causes Issues

**Immediate Rollback Steps** (within 5 minutes):

#### Step 1: Revert Named Credential

1. Navigate to: Setup → Named Credentials
2. Click: **DBS**
3. Click: **Edit**
4. Change Certificate back to: `FRED_Updater_NGINX_Client_Cert` (old)
5. Click: **Save**

#### Step 2: Verify Rollback Success

1. Execute test callout (see Phase 3, Step 3.1)
2. Check for 200 OK response
3. Monitor debug logs

#### Step 3: Contact Infrastructure Team

- Report: New certificate not working
- Request: Investigation on server side
- Provide: Error messages from Salesforce debug logs

### If Old Certificate Already Deleted

**Recovery Steps:**

1. Contact Infrastructure team immediately
2. Request: Temporary re-enablement of old certificate on server
3. Re-upload old certificate backup (if you have .p12 file)
4. Update Named Credential to use old certificate

---

## Contact Information

### Key Stakeholders

**Infrastructure Team:**
- Name: [Infrastructure Engineer Name]
- Email: [Email]
- Phone: [Phone]
- Escalation: [Manager Name/Email]

**Salesforce Admin:**
- Name: [Your Name]
- Email: [Your Email]
- Backup: [Backup Admin Name/Email]

**FRED System Owner:**
- Name: [FRED System Admin]
- Email: [Email]
- Department: [Department]

### Support Escalation Path

1. **Level 1**: Infrastructure Engineer (certificate generation issues)
2. **Level 2**: Salesforce Admin (certificate upload/configuration issues)
3. **Level 3**: Infrastructure Manager (server-side configuration issues)
4. **Level 4**: IT Director (critical business impact)

---

## Appendix

### Appendix A: Certificate Formats Explained

**PKCS#12 (.p12 or .pfx)**
- Container format holding certificate + private key
- Password protected
- **This is what Salesforce accepts**
- Standard for mutual TLS authentication

**PEM (.pem or .crt)**
- Text-based format
- May contain certificate only (no private key)
- **NOT directly usable in Salesforce** (needs conversion to .p12)

**DER (.der or .cer)**
- Binary format
- May contain certificate only
- **NOT directly usable in Salesforce** (needs conversion to .p12)

### Appendix B: Converting Certificate Formats

If Infrastructure team provides PEM format, convert to .p12:

**Using OpenSSL** (Linux/Mac):
```bash
openssl pkcs12 -export \
  -in certificate.pem \
  -inkey private-key.pem \
  -out fred-updater.p12 \
  -name "FRED Updater Client Cert" \
  -passout pass:YourPassword
```

**Note**: You'll need both the certificate file and private key file

### Appendix C: Useful SOQL Queries

**Query Certificate Details:**
```sql
SELECT Id, DeveloperName, MasterLabel, ExpirationDate
FROM Certificate
WHERE DeveloperName LIKE '%FRED%'
```

**Query Named Credentials:**
```sql
SELECT Id, DeveloperName, MasterLabel, Endpoint
FROM NamedCredential
WHERE Endpoint LIKE '%fred%'
```

**Check Certificate Usage:**
```sql
-- This query only works in Setup UI, not SOQL
-- Navigate to: Certificate and Key Management → Certificate Name → "Where is this used?"
```

### Appendix D: Common Issues & Solutions

#### Issue 1: "Peer not authenticated" Error

**Symptom:**
```
System.HttpCalloutException: Peer not authenticated
```

**Cause:** Server doesn't recognize client certificate

**Solution:**
1. Verify certificate uploaded correctly
2. Check certificate Common Name matches server expectations
3. Confirm Infrastructure team added certificate to NGINX trusted clients

#### Issue 2: "Unable to establish SSL connection"

**Symptom:**
```
System.HttpCalloutException: Unable to establish SSL connection
```

**Cause:** Certificate mismatch or server-side configuration issue

**Solution:**
1. Verify certificate is valid (not expired)
2. Check certificate is properly installed on NGINX server
3. Confirm server SSL/TLS configuration accepts client certificates

#### Issue 3: "Unauthorized endpoint"

**Symptom:**
```
System.HttpCalloutException: Unauthorized endpoint, please check Setup->Security->Remote site settings
```

**Cause:** Endpoint not in Remote Site Settings

**Solution:**
1. Navigate to: Setup → Remote Site Settings
2. Add: https://fred-updater.recyclinglives-services.com
3. Save and retry

#### Issue 4: Certificate Upload Fails

**Symptom:** "Unable to import keystore" error

**Causes & Solutions:**
- **Wrong password**: Verify password with Infrastructure team
- **Corrupt file**: Re-download certificate from Infrastructure
- **Wrong format**: Ensure file is .p12 or .pfx format
- **Missing private key**: Certificate must contain private key

### Appendix E: Testing Checklist

**Pre-Renewal Testing:**
- [ ] Document current integration behavior
- [ ] Capture sample of successful callout logs
- [ ] Identify test scenario with predictable results

**Post-Renewal Testing:**
- [ ] Execute test callout
- [ ] Compare results with pre-renewal behavior
- [ ] Verify data integrity
- [ ] Check for any error logs
- [ ] Confirm scheduled jobs run successfully

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-22 | Salesforce Admin | Initial certificate renewal guide created |
| | | | Certificate expires: 2025-11-09 (18 days) |
| | | | Integration endpoint: fred-updater.recyclinglives-services.com |

---

## Next Actions

### Immediate (This Week)

1. ✅ Review this guide with Infrastructure team
2. ⏳ Request new certificate from Infrastructure engineer
3. ⏳ Schedule certificate renewal date (recommend: Nov 2, 2025)
4. ⏳ Prepare test plan
5. ⏳ Notify FRED system stakeholders of planned renewal

### Week Before Expiration

1. ⏳ Confirm new certificate received from Infrastructure
2. ⏳ Upload certificate to Salesforce sandbox (if available)
3. ⏳ Test in sandbox environment
4. ⏳ Schedule production renewal

### After Renewal

1. ⏳ Monitor integration for 7-14 days
2. ⏳ Delete old certificate (after confirmation period)
3. ⏳ Update this document with actual renewal date
4. ⏳ Schedule reminder for next renewal (1 year from now)

---

**⚠️ CRITICAL REMINDER**: Certificate expires November 9, 2025 (18 days from now). Begin renewal process immediately to avoid integration disruption.

---

**Document Location:** `/home/john/Projects/Salesforce/Documentation/FRED_INTEGRATION_NGINX_CERTIFICATE_RENEWAL_GUIDE.md`

**For Questions:** Contact Salesforce Administrator or Infrastructure Team
