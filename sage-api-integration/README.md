# Sage API Integration - OldOrg State Documentation

**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Org**: OldOrg (recyclinglives.my.salesforce.com)
**Status**: ✅ Production (V2 - includes Oct 6 RLCS fix + Oct 15 OAuth re-auth)
**Implementation Version:** V2 (RLCS batch export fix deployed Oct 6, 2025)

---

## Related Documentation

**This scenario consolidates the following documentation** (component-based analysis):

1. **[SAGE_API_HTTP_401_AUTHENTICATION_FIX.md](source-docs/SAGE_API_HTTP_401_AUTHENTICATION_FIX.md)** - OAuth authentication issue fix (Oct 15, 2025)
2. **[RLCS_VENDOR_INVOICE_SAGE_EXPORT_FIX.md](source-docs/RLCS_VENDOR_INVOICE_SAGE_EXPORT_FIX.md)** - RLCS batch export SOQL fix (Oct 6, 2025)

**Component Analysis - Why Consolidated**:
- Core components: SageAPIClient.cls (OAuth auth), ExportVendorInvoiceSageBatch.cls (SOQL query)
- Both docs address different issues in the same Sage API integration system
- OAuth fix (Oct 15) is infrastructure issue affecting all Sage integrations
- SOQL fix (Oct 6) is implementation bug in RLCS batch export
- Part of same external integration system (Sage accounting software)
- Must be deployed together as complete Sage API integration

**Deployment Strategy**: Single deployment of V2 includes both fixes and complete Sage API integration.

**Complete Scenario Index**: See [DOCUMENTATION_MAPPING_AND_SCENARIOS.md](../../Documentation/DOCUMENTATION_MAPPING_AND_SCENARIOS.md) for all migration scenarios.

---

## Executive Summary

**System Purpose**: Bi-directional integration between Salesforce and Sage 200 accounting system for invoice management and account synchronization.

**Key Functionality**:
- Export vendor invoices to Sage (RLES and RLCS)
- Export customer invoices to Sage
- Sync suppliers from Sage to Salesforce
- Sync customers from Sage to Salesforce
- Automated daily synchronization via scheduled jobs

**Recent Fixes**:
- **Oct 6, 2025**: Fixed RLCS vendor invoice batch export (SOQL missing fields)
- **Oct 15, 2025**: Re-authenticated OAuth token in Named Credential

**Current State**: Fully operational with 6 scheduled jobs running daily

---

## System Overview

### Integration Flow

```
SALESFORCE → SAGE (Invoice Export)
┌───────────────────────────┐
│ Vendor_Invoice__c        │
│ Invoice__c               │ →  SageAPIClient.sendRequest()
│ (RLES & RLCS)           │ →  OAuth via Named Credential "SIA"
└───────────────────────────┘ →  POST to Sage API
                               ↓
                          Sage 200 Purchase/Sales Invoices

SAGE → SALESFORCE (Account Sync)
┌───────────────────────────┐
│ Sage Suppliers           │
│ Sage Customers           │ ←  SageAPIClient.getSuppliers/Customers()
└───────────────────────────┘ ←  OAuth via Named Credential "SIA"
                               ↓
                          Salesforce Account records
```

### Export Modes

**Vendor Invoice Export**:
- **≤5 invoices**: Real-time non-batch export
- **>5 invoices**: Batch export (ExportVendorInvoiceSageBatch)

**Customer Invoice Export**:
- Always real-time export

---

## Components Inventory

### Apex Classes (9 total)

| Class Name | Lines | Last Modified | Purpose |
|------------|-------|---------------|---------|
| **SageAPIClient** | 23,773 | Sep 11, 2025 | Core API client with OAuth |
| ExportVendorInvoiceSage | 6,979 | Jul 14, 2025 | Controller for vendor invoice export |
| ExportVendorInvoiceSageBatch | 7,814 | **Oct 6, 2025** | Batch export (RLCS fix) |
| SageRLCSSupplierQueueable | 282 | Jul 14, 2025 | Queueable for RLCS supplier sync |
| SageCustomerQueueable | 257 | Jul 14, 2025 | Queueable for customer sync |
| SageRLCSSupplierScheduler | 2,563 | Jul 14, 2025 | Scheduler for RLCS supplier sync |
| SageCustomerScheduler | 4,131 | Jul 14, 2025 | Scheduler for customer sync |
| SageAPIClientTest | - | Sep 11, 2025 | Test class for API client |
| ExportVendorInvoiceSageTest | 975 | Jul 14, 2025 | Test class for export |

**Key Methods in SageAPIClient**:
- `sendRequest()` - OAuth authentication and HTTP request
- `SendInvoice()` - Export customer invoice
- `SendPurchaseInvoice()` - Export vendor invoice (uses RLCS fields)
- `getCustomerShortViews()` - Retrieve customers from Sage
- `getSuppliersShortViews()` - Retrieve suppliers from Sage

### Named Credentials (1)

| Name | Endpoint | Auth Type | Status |
|------|----------|-----------|--------|
| **SIA** | https://api.columbus.sage.com/uk/sage200extra/accounts/v1/ | OAuth 2.0 | ✅ Active (re-authenticated Oct 15) |

### Scheduled Jobs (6 active)

| Job Name | CRON Expression | Next Fire Time | Purpose |
|----------|-----------------|----------------|---------|
| Sage RLCS Supplier Sync | 0 55 5 * * ? | 5:55 AM daily | Sync RLCS suppliers |
| Sage Supplier Sync | 0 30 5 * * ? | 5:30 AM daily | Sync standard suppliers |
| Sage RLCS Customer Sync | 0 45 5 * * ? | 5:45 AM daily | Sync RLCS customers |
| Sage Customer Sync | 0 15 5 * * ? | 5:15 AM daily | Sync standard customers |
| Sage Supplier Invoice Sync | 0 5 6 * * ? | 6:05 AM daily | Sync supplier invoices |
| Sage Customer Invoice Sync | 0 15 6 * * ? | 6:15 AM daily | Sync customer invoices |

---

## Current State Verification

### Apex Class Query Results

**Query Date**: October 22, 2025

All 7 main classes + 2 test classes verified present in OldOrg.

**Most Recent Modification**: ExportVendorInvoiceSageBatch.cls on **Oct 6, 2025** by John Shintu (RLCS SOQL fix)

### Named Credential Verification

**Query Date**: October 22, 2025

**SIA Named Credential**:
- ✅ Present and configured
- ✅ OAuth re-authenticated on Oct 15, 2025
- ✅ Endpoint: https://api.columbus.sage.com/uk/sage200extra/accounts/v1/
- ⚠️ **Migration Note**: OAuth tokens cannot be deployed; must be manually reconfigured in NewOrg

### Scheduled Jobs Status

**Query Date**: October 22, 2025

All 6 scheduled jobs in **WAITING** state (healthy):
- ✅ Next fire times scheduled for Oct 23, 2025
- ✅ CRON expressions documented for migration
- ⚠️ **Migration Note**: Scheduled jobs must be manually created in NewOrg post-deployment

---

## Implementation History

### Version 1: Initial Implementation (Before Oct 2025)

**When**: July 2025 (based on class modification dates)
**Who**: Vesium Gerry Gregoire
**What**:
- Initial Sage API integration implementation
- SageAPIClient with OAuth authentication
- Vendor and customer invoice export
- Supplier and customer sync
- 6 scheduled jobs for daily sync

### Version 2: RLCS Batch Export Fix (Oct 6, 2025)

**WHY**:
- Users (Chantal Cook) couldn't export RLCS vendor invoices when >5 invoices selected
- Error: "SObject row was retrieved via SOQL without querying the requested field"
- Blocked month-end RLCS invoice processing

**WHAT**:
- Added `RLCS_Nominal_Code__c` to ExportVendorInvoiceSageBatch.cls SOQL query
- Added `RLCS_Cost_Centre__c` to ExportVendorInvoiceSageBatch.cls SOQL query
- Updated CSV button visibility rules on RLCS_Vendor_Invoice.flexipage

**WHEN**:
- Reported: October 6, 2025
- Fixed: October 6, 2025 at 16:19:35 UTC
- Deploy ID: **0AfSj000000yACbKAM**
- Completed: 16:21:45 UTC (2 min 10 sec)

**TESTING**:
- Tested with invoices 19225, 19332
- Verified >5 invoice batch export works
- Verified ≤5 invoice non-batch export still works
- Verified CSV button visibility after "Released For Payment" status

**METRICS**:
- Before: RLCS batch exports >5 invoices failed 100%
- After: All RLCS exports work regardless of batch size
- Impact: Unblocked month-end RLCS invoice processing

### Version 2.1: OAuth Re-Authentication (Oct 15, 2025)

**WHY**:
- OAuth token in Named Credential "SIA" expired
- ALL Sage API integrations failed simultaneously
- Reported by user (Ania) + admin email alerts (2 queueable job failures)

**WHAT**:
- Re-authenticated OAuth connection in Named Credential "SIA"
- No code changes required (configuration fix)

**WHEN**:
- Occurred: October 15, 2025
- Fixed: October 15, 2025 (same day)
- Deploy ID: N/A (configuration change, not deployment)

**TESTING**:
- Verified invoice export works (tested by Ania)
- Verified supplier sync queueable runs successfully
- Verified customer sync queueable runs successfully
- Monitored for 24 hours - no recurrence

**METRICS**:
- Before: 100% of Sage API calls returned HTTP 401 Unauthorized
- After: All Sage API integrations restored
- Downtime: <2 hours
- Root Cause: External (Sage OAuth token expiration)

---

## Business Logic

### Invoice Export Logic

**Decision Point**: Batch vs. Non-Batch
```apex
if (selectedInvoices.size() <= 5) {
    // Non-batch: Real-time export
    // Uses ExportVendorInvoiceSage.cls
    // SOQL query includes RLCS fields (always worked)
} else {
    // Batch: Async export
    // Uses ExportVendorInvoiceSageBatch.cls
    // SOQL query FIXED on Oct 6 to include RLCS fields
}
```

**RLCS vs. RLES**:
- **RLES**: Standard nominal code and cost center
- **RLCS**: Separate RLCS_Nominal_Code__c and RLCS_Cost_Centre__c fields
- Both must be included in SOQL for batch export

### OAuth Authentication Flow

```
1. User/Scheduled Job triggers Sage API call
2. SageAPIClient.sendRequest() checks Named Credential "SIA"
3. Salesforce handles OAuth token refresh automatically
4. If token expired: Admin must manually re-authenticate
5. HTTP request sent to Sage API with OAuth bearer token
6. Response processed and data updated in Salesforce
```

**Token Expiration**:
- OAuth tokens can expire (external Sage API policy)
- Requires manual re-authentication in Setup
- No code deployment needed to fix

---

## Configuration

### Named Credential Setup (Critical for Migration)

**Name**: SIA
**URL**: https://api.columbus.sage.com/uk/sage200extra/accounts/v1/
**Identity Type**: Named Principal
**Authentication Protocol**: OAuth 2.0
**Auth Provider**: [Sage OAuth Provider - must be configured]

**⚠️ Migration Critical**:
- OAuth tokens are org-specific
- Cannot be deployed via metadata
- Must manually reconfigure in NewOrg
- Requires Sage admin credentials to generate new OAuth token

### Custom Fields Required

**On Vendor_Invoice__c**:
- RLCS_Nominal_Code__c (used in batch export)
- RLCS_Cost_Centre__c (used in batch export)
- Nominal_Code__c (standard field)
- Cost_Centre__c (standard field)
- Invoice_Status__c (affects CSV button visibility)

### Scheduled Job Configuration

All jobs scheduled for early morning (5:00 AM - 6:15 AM) to avoid business hours:

**Suppliers First** (5:30 AM - 5:55 AM):
- Standard suppliers at 5:30 AM
- RLCS suppliers at 5:55 AM

**Customers Second** (5:15 AM - 5:45 AM):
- Standard customers at 5:15 AM
- RLCS customers at 5:45 AM

**Invoices Last** (6:05 AM - 6:15 AM):
- Supplier invoices at 6:05 AM
- Customer invoices at 6:15 AM

**Rationale**: Sync accounts before invoices to avoid lookup failures

---

## Integration Points

### External Dependencies

**Sage 200 API**:
- External system (not controlled by Salesforce)
- OAuth authentication required
- API endpoint: api.columbus.sage.com
- May have different credentials for different environments

### Internal Dependencies

**Objects Used**:
- Vendor_Invoice__c (export to Sage purchase invoices)
- Invoice__c (export to Sage sales invoices)
- Account (sync with Sage customers/suppliers)

**Flows/Processes**:
- None directly related (Sage integration is Apex-only)

**Lightning Pages**:
- RLCS_Vendor_Invoice.flexipage (CSV button visibility - updated Oct 6)

---

## Testing Scenarios

### Test Case 1: RLCS Batch Export (>5 Invoices)

**Setup**:
1. Create/select 6+ RLCS vendor invoices
2. Set status to "Released For Payment"
3. Ensure RLCS_Nominal_Code__c and RLCS_Cost_Centre__c populated

**Execute**:
1. Select all invoices
2. Click "Export to Sage" button
3. Batch job executes

**Expected Result**:
- ✅ Batch completes successfully
- ✅ All invoices exported to Sage
- ✅ CSV button becomes visible
- ✅ No SOQL errors

**Verified**: October 6, 2025 (post-fix)

### Test Case 2: OAuth Token Validity

**Setup**:
1. Trigger any Sage API call (invoice export, sync job)

**Execute**:
1. SageAPIClient.sendRequest() called
2. OAuth token validated

**Expected Result**:
- ✅ HTTP 200 response (not 401)
- ✅ API call succeeds
- ✅ Data synced/exported correctly

**Verified**: October 15, 2025 (post-reauth)

### Test Case 3: Scheduled Jobs Execution

**Setup**:
1. Wait for next scheduled fire time
2. Monitor job execution

**Execute**:
1. Scheduled job triggers at configured time
2. Queueable executes
3. API calls made to Sage

**Expected Result**:
- ✅ Job status: Completed
- ✅ No errors in debug logs
- ✅ Accounts synced successfully
- ✅ Next fire time scheduled correctly

**Verified**: Ongoing (jobs run daily)

---

## Files and Metadata

### Apex Classes Location

All classes retrieved from OldOrg:
```
/home/john/Projects/Salesforce/force-app/main/default/classes/
├── SageAPIClient.cls
├── SageAPIClient.cls-meta.xml
├── SageAPIClientTest.cls
├── SageAPIClientTest.cls-meta.xml
├── ExportVendorInvoiceSage.cls
├── ExportVendorInvoiceSage.cls-meta.xml
├── ExportVendorInvoiceSageBatch.cls (FIXED Oct 6)
├── ExportVendorInvoiceSageBatch.cls-meta.xml
├── ExportVendorInvoiceSageTest.cls
├── ExportVendorInvoiceSageTest.cls-meta.xml
├── SageRLCSSupplierQueueable.cls
├── SageRLCSSupplierQueueable.cls-meta.xml
├── SageCustomerQueueable.cls
├── SageCustomerQueueable.cls-meta.xml
├── SageRLCSSupplierScheduler.cls
├── SageRLCSSupplierScheduler.cls-meta.xml
├── SageCustomerScheduler.cls
└── SageCustomerScheduler.cls-meta.xml
```

**Total**: 18 files (9 classes * 2 files each)

### Source Documentation

Complete issue documentation available in `source-docs/`:
- SAGE_API_HTTP_401_AUTHENTICATION_FIX.md (OAuth issue details)
- RLCS_VENDOR_INVOICE_SAGE_EXPORT_FIX.md (SOQL fix details)

---

## Known Issues and Limitations

### OAuth Token Expiration

**Issue**: OAuth tokens can expire without warning
**Frequency**: Rare (months between expirations)
**Impact**: ALL Sage integrations fail simultaneously
**Detection**: Admin email alerts, user reports
**Resolution**: Manual re-authentication in Named Credential setup
**Prevention**: Not possible (external Sage API policy)

### Named Credential Cannot Be Deployed

**Issue**: Named Credentials with OAuth cannot be deployed via metadata API
**Impact**: Must be manually reconfigured in every org
**Workaround**: Document OAuth setup steps in migration plan
**Requirement**: Sage admin access to generate OAuth credentials

### Scheduled Jobs Not Deployable

**Issue**: Scheduled jobs (CronTrigger) don't deploy via metadata
**Impact**: Must manually schedule in target org post-deployment
**Workaround**: Document CRON expressions for manual setup
**Requirement**: System admin access to schedule jobs

### Batch Export Threshold Hard-Coded

**Issue**: 5-invoice threshold is hard-coded in ExportVendorInvoiceSage.cls
**Impact**: Cannot be adjusted without code change
**Current Value**: Works well for current volume
**Future**: Consider making threshold configurable

---

## Migration Considerations

### Critical Pre-Migration Steps

1. **Sage Admin Access**: Obtain credentials to generate OAuth token for NewOrg
2. **Auth Provider Setup**: Create Sage OAuth provider in NewOrg first
3. **Custom Fields**: Ensure RLCS_Nominal_Code__c and RLCS_Cost_Centre__c exist in NewOrg
4. **Test Data**: Prepare test invoices in NewOrg for validation

### Cannot Be Automated

- ❌ Named Credential OAuth configuration
- ❌ Scheduled job creation
- ❌ OAuth token generation (requires external Sage portal)

### Can Be Deployed

- ✅ All 9 Apex classes
- ✅ Test classes
- ✅ Custom field definitions (if not already in NewOrg)
- ✅ Lightning page modifications

### Post-Deployment Manual Steps

1. Configure Sage OAuth Provider
2. Create Named Credential "SIA" with OAuth
3. Authenticate OAuth connection with Sage
4. Schedule 6 jobs with documented CRON expressions
5. Test invoice export (≤5 and >5)
6. Monitor scheduled job executions for 1 week

---

## Risk Assessment

### Overall Risk: MEDIUM

**Complexity Factors**:
- External API dependency (Sage)
- OAuth authentication (org-specific)
- Manual configuration required
- 9 classes to deploy
- 6 scheduled jobs to configure
- Two separate issues fixed in V2

**Mitigation Strategies**:
- Test in sandbox first
- Have Sage admin available during OAuth setup
- Document exact CRON expressions
- Prepare rollback plan (deactivate scheduled jobs if issues)
- Monitor closely for 1 week post-migration

**Success Probability**: HIGH (code is stable, V2 tested in production)

**Estimated Migration Time**: 4-6 hours
- 1 hour: Deploy Apex classes
- 2 hours: OAuth setup and troubleshooting
- 1 hour: Schedule jobs and test
- 1-2 hours: Validation and monitoring

---

## Contact Information

**Issue #1 (RLCS Fix)**:
- Reported By: Chantal Cook
- Fixed By: John Shintu
- Date: October 6, 2025

**Issue #2 (OAuth)**:
- Reported By: Ania (user) + Admin alerts
- Fixed By: [Admin who re-authenticated]
- Date: October 15, 2025

**Current System Owner**: [To be confirmed]
**Sage Admin Contact**: [To be confirmed]

---

## Version History

| Version | Date | Changes | Deploy ID |
|---------|------|---------|-----------|
| V1.0 | Jul 2025 | Initial implementation | - |
| V2.0 | Oct 6, 2025 | RLCS batch export SOQL fix | 0AfSj000000yACbKAM |
| V2.1 | Oct 15, 2025 | OAuth re-authentication | N/A (config) |

---

**END OF OLDORG STATE DOCUMENTATION**
