# Salesforce OldOrg State Documentation

**Organization**: OldOrg (Recycling Lives Service - recyclinglives.my.salesforce.com)
**Purpose**: Document current state of all implementations in OldOrg before migration to NewOrg
**Created**: October 22, 2025
**Status**: 🔄 Fresh Start - Enhanced Workflow Implementation

---

## Repository Purpose

This repository serves as a **snapshot and documentation** of all customizations, features, and implementations currently deployed in **OldOrg** (the legacy Salesforce organization being migrated FROM).

### Why This Repository Exists

1. **Historical Record**: Captures the exact state of OldOrg implementations
2. **Migration Reference**: Provides source of truth for what needs to be migrated
3. **Knowledge Transfer**: Documents business logic, configurations, and decisions
4. **Comparison Baseline**: Enables gap analysis between OldOrg and NewOrg
5. **Audit Trail**: Maintains record of what was implemented, when, and why

### What This Repository Contains

- **Current deployed code** from OldOrg (Apex, Triggers, Flows, etc.)
- **Complete documentation** of each scenario/feature
- **Configuration details** (Custom Settings, Custom Fields, etc.)
- **Verification data** (deployment IDs, active versions, test results)
- **Business logic explanations** (why things were built the way they were)
- **Code content verification** (line-by-line confirmation of documented changes)

---

## Repository Structure

```
Salesforce_OldOrg_State/
├── README.md (this file)
├── producer-portal/                     ← Each scenario gets its own folder
│   ├── README.md                        ← Complete documentation of current state
│   ├── source-docs/                     ← Original documentation (archived)
│   │   └── ORIGINAL_DOCS.md
│   └── code/                            ← Actual code retrieved from OldOrg
│       ├── classes/
│       ├── triggers/
│       ├── flows/
│       └── objects/
├── email-to-case-assignment/            ← Another scenario
│   ├── README.md
│   ├── source-docs/
│   └── code/
└── [more scenarios...]
```

### Folder Naming Convention

- **Flat structure**: All scenarios at root level
- **Kebab-case names**: `email-to-case-assignment`, `producer-portal`
- **Descriptive**: Folder name clearly indicates the feature/scenario
- **README.md standard**: Always use README.md (never DEPLOYMENT_VERIFICATION.md or GAP_ANALYSIS.md)

---

## Scenarios Documented

### Status Legend
- ✅ **Complete**: Fully documented with code verification
- 🔄 **In Progress**: Currently being documented
- 📋 **Planned**: Not yet started

### Scenario Type Legend
- **Deployment Scenarios**: Code changes, bug fixes, new features to migrate from OldOrg to NewOrg
- ⚠️ **Analysis Scenarios**: Data analysis, recommendations, documentation of existing systems (NOT code deployments)

---

## Current Scenarios (Fresh Start - Oct 22, 2025)

### Analysis & Configuration Scenarios (5 Complete ✅)

**Purpose**: Documentation of existing systems, data quality analysis, troubleshooting, and user training guides (NOT code deployments)

| Scenario | Status | Last Updated | Type | Description |
|----------|--------|--------------|------|-------------|
| [smartwaste-integration](smartwaste-integration/) | ✅ Complete | Oct 22, 2025 | Analysis | SmartWaste Integration data quality analysis - 2,283 error logs analyzed with recommendations for master data cleanup |
| [quote-pricing-notification](quote-pricing-notification/) | ✅ Complete | Oct 22, 2025 | Troubleshooting | Email delivery failure root cause analysis (Sept 24 - Oct 16, 2025) - Deleted org-wide email address - Manual UI configuration fix |
| [quote-to-order-process](quote-to-order-process/) | ✅ Complete | Oct 22, 2025 | User Training | Quote-to-Order process documentation - User error analysis (wrong PO selection) - Training guide and best practices |
| [fred-certificate-renewal](fred-certificate-renewal/) | ✅ Complete | Oct 22, 2025 | Configuration/Certificate | FRED Integration certificate renewal procedure - Certificate expires Nov 9, 2025 (16 days) - Complete renewal process with step-by-step instructions |
| [sage-api-integration](sage-api-integration/) | ✅ Complete | Oct 23, 2025 | Configuration/OAuth | Sage API OAuth authentication procedure - HTTP 401 authentication failures resolved Oct 15-17, 2025 - Manual re-authentication of "SIA" Named Credential - Refresh token expiration cycle (60-90 days) |

### Deployment Scenarios (12 Complete ✅)

**Purpose**: Code changes, bug fixes, new features that need to be migrated from OldOrg to NewOrg.

| Scenario | Status | Last Updated | Components | Description |
|----------|--------|--------------|------------|-------------|
| [producer-portal](producer-portal/) | ✅ Complete | Oct 22, 2025 | 8 classes, 4 triggers, 5 objects, 3 flows | WEEE compliance Producer Portal - 102 contracts, quarterly tonnage submissions. **All 5 stakeholder issues fixed (Oct 20-21).** Includes sharing automation for Login license users. |
| [email-to-case-assignment](email-to-case-assignment/) | ✅ Complete | Oct 23, 2025 | 2 classes, 1 flow, 1 custom setting, 6 fields | Email-to-Case automatic assignment system - Workload distribution for 8 Customer Service users. **V3 includes SOQL optimization, recursion prevention, Kaylie Morris exemption.** Threshold-based assignment (20-case soft limit) with same-day previous owner logic. |
| [invoice-email-portal-access](invoice-email-portal-access/) | ✅ Complete | Oct 23, 2025 | 5 classes, 1 trigger, 1 page | Invoice Portal enhancement - Enables customers to view and download invoice PDFs from public portal. **Implemented Oct 9, 2025.** Includes automatic ContentDistribution creation via trigger, invoice PDF deduplication logic, and portal UI updates. |
| [daily-reminder-emails](daily-reminder-emails/) | ✅ Complete | Oct 23, 2025 | 2 new classes, 1 modified class, 2 test classes | Two-tier consolidated email reporting system. **Implemented Oct 20, 2025.** Reduces email volume 99.6% (556 → 2 daily reports). Tier 1: Delivery Confirmation (438 Jobs, 8 AM). Tier 2: Schedule Creation (133 Jobs, 9 AM). Eliminates record locking errors. |
| [portal-exchange-email](portal-exchange-email/) | ✅ Complete | Oct 23, 2025 | 2 classes, 1 trigger, 6 flows | SPF/DMARC email fix for portal exchanges. **Implemented Oct 16, 2025.** Resolves email rejection for customers with strict SPF policies (Amey Highways). Portal flows now send from org-wide address. Handler extracts portal user email for Contact/Account matching. |
| [transport-charges](transport-charges/) | ✅ Complete | Oct 23, 2025 | 2 classes (819+2400 lines), 1 validation rule | RLCS Transport & Data Issues - **3 critical bugs fixed (Oct 14-15).** Issue 1: Missing charges (£919K recovered). Issue 3: Hybrid calculation bug (£870K saved). **Financial impact: £1.79M.** OrderItem now single source of truth for rates and flags. Line-by-line code verification complete. |
| [cs-invoicing](cs-invoicing/) | ✅ Complete | Oct 23, 2025 | 3 classes (142+819+153 lines), 2 test classes, 1 field | CS Invoicing Date & Description auto-population - **Implemented Oct 10-13, 2025.** Adds buildChargeDescription() method, Collection_Date__c field. Method signature change: createAutoJobCharge(Job object) eliminates inline SOQL (performance gain). **75.65% coverage.** Invoice filtering via "Raised Between" now works. CS Invoicing team gets automatic visibility. |
| [secondary-transport](secondary-transport/) | ✅ Complete | Oct 23, 2025 | 4 classes (819+325+621+149 lines), 3 fields, 1 validation rule | Secondary Transport & CSV Upload Fix - **Two-phase implementation (Oct 7-8, 2025).** Phase 1: Secondary transport charges (TWO charges per job). Phase 2: CSV columns 14-15 mapping fix. **100% test coverage.** Resolved 97 invalid Jobs issue (£19K-£29K). Prevents NULL weight/units from CSV uploads. Eliminates manual data entry. |
| [po-consumption-emails](po-consumption-emails/) | ✅ Complete | Oct 23, 2025 | 1 custom setting (5 fields), 1 flow, 6 Order fields, 3 formulas | PO Consumption Email Notifications - **Implemented Oct 14, 2025.** Multi-threshold monitoring system (50%, 75%, 90%). Alerts 4 stakeholders when Purchase Orders reach critical consumption levels. **Option B reset logic** enables re-notification if consumption fluctuates. Scalable configuration via Custom Setting. Currently monitoring PO #00059438 (£63K max value). System active and operational. |
| [job-charge-credit-on-account](job-charge-credit-on-account/) | ✅ Complete | Oct 23, 2025 | 1 flow (198 lines), 11 field dependencies, 3 Account IDs | Job Charge Credit on Account Data Integrity Fix - **Implemented Oct 22, 2025 at 11:30 UTC.** Removed "Credit on Account" from Flow entry criteria. Flow now executes ONLY on Rebate charges (as intended). **Fixed 3 broken charges (1.08% of 279).** Changed filterLogic from "1 AND (2 OR 3)" to "1 AND 2 AND 3 AND 4 AND 5". Prevents Cost__c field corruption on Credit on Account charges. **26 new charges post-fix with zero issues.** Line-by-line XML verification complete. |
| [rlcs-vendor-invoice-sage](rlcs-vendor-invoice-sage/) | ✅ Complete | Oct 23, 2025 | 1 class (163 lines), 1 FlexiPage (1369 lines), 34 field dependencies | RLCS Vendor Invoice Sage Export Fix - **Implemented Oct 6, 2025 at 16:19 UTC.** Two-part fix: (1) Added RLCS_Nominal_Code__c and RLCS_Cost_Centre__c to batch SOQL query (line 21). (2) Removed Invoice_Status restrictions from CSV button visibility (lines 167-179). **Batch export now works for >5 invoices.** CSV button always visible (matches RLES). **213 RLCS invoices processed successfully since fix.** Test-first deployment strategy (NewOrg 45 min before OldOrg). |
| [bam-construct-portal-license](bam-construct-portal-license/) | ✅ Complete | Oct 23, 2025 | 1 formula field, 1 layout (401 lines), 1 class (296 lines), 1 LWC (291 lines) | BAM Construct Portal License Visibility Fix - **Implemented Oct 15, 2025.** Enables HQ portal users to view supplier waste carrier licenses for UK compliance. Created formula field Waste_Carrier_License_Expiry__c on Job object. Updated Job portal layout (lines 96-100), Utility_Community.cls (lines 23, 40-41), and depotViewCommunity LWC (lines 40-41, 64-72). **137 HQ users can now verify supplier licenses.** Deploy IDs: 0AfSj000000yqlJKAQ, 0AfSj000000yqtNKAQ. |

---

## Fresh Start - Enhanced Workflow (Oct 22, 2025)

### Why Fresh Start?

Previous documentation lacked critical verification steps:
- ❌ No line-by-line code content verification
- ❌ Incomplete dependency analysis from actual code
- ❌ Missing CLI vs Manual UI deployment step distinction
- ❌ Inconsistent file naming conventions

### Enhanced Workflow Now Includes

✅ **Step 3b: Code Dependency Analysis**
- Read actual Apex classes to find SOQL queries (extract fields/objects)
- Find Custom Settings accessed
- Find Queues, Record Types, Custom Labels referenced
- Read Flow metadata for dependencies
- Create complete dependency list with line numbers

✅ **Step 3c: Implementation Verification (CRITICAL)**
- Date verification: Compare LastModifiedDate with documented deployment date
- Line-by-line code verification: Use sed, grep to find documented code snippets
- Logic flow verification: Verify trigger→method→field flow
- Functional verification: Query data to prove feature works in OldOrg
- Dependency verification: Query for all dependencies
- **STOP and ASK USER if any verification fails**

✅ **Professional Documentation Standards**
- ALWAYS use README.md (never DEPLOYMENT_VERIFICATION.md)
- No AI references in commits or documentation
- Working cross-repo GitHub links
- Clear marking of CLI vs Manual UI steps

---

## How to Use This Repository

### For Migration Planning

1. **Review scenario README**: Understand what's currently deployed in OldOrg
2. **Check source-docs folder**: See original documentation (archived)
3. **Check code folder**: See actual deployed code (verified)
4. **Verify versions**: Confirm active flow versions, trigger statuses
5. **Understand dependencies**: Review integration points and related scenarios

### For Gap Analysis

1. Compare OldOrg state (this repo) with NewOrg current state
2. Identify missing components
3. Identify version mismatches
4. Plan migration order based on dependencies

### For Reference

1. **Historical lookup**: "How did we implement X in OldOrg?"
2. **Configuration reference**: "What were the custom setting values?"
3. **Business logic**: "Why was this built this way?"
4. **Code verification**: "Does the deployed code match the documentation?"

---

## Documentation Standard

Each scenario folder contains:

### Folder Structure

```
scenario-name/
├── README.md                        ← Complete OldOrg state documentation
├── source-docs/                     ← Original documentation (archived)
│   └── ORIGINAL_DOCS.md
└── code/                            ← Verified code from OldOrg
    ├── classes/
    ├── triggers/
    ├── flows/
    └── objects/
```

### README.md Structure

1. **Executive Summary**: What the system does, key features
2. **System Overview**: High-level architecture and flow
3. **Components Inventory**: Detailed list of all components (Apex, Flows, Custom Objects, etc.)
4. **Current State Verification**: Queries and results showing what's actually deployed
5. **Code Content Verification**: Line-by-line confirmation of documented changes
6. **Business Logic**: How the system works, assignment rules, calculations
7. **Configuration**: Adjustable settings and how to change them
8. **Dependencies**: All referenced objects, fields, settings, queues, record types
9. **Integration Points**: How this scenario connects to other systems
10. **Related Documentation**: Links to source-docs and NewOrg migration package
11. **Files and Metadata**: Location of source code
12. **Version History**: Chronological history of implementations

---

## Verification Methodology

All documented scenarios include verification data showing:

- **Deployment IDs**: Proof of what was deployed and when
- **Active Versions**: Flow versions, trigger statuses
- **Code Content**: Line-by-line verification using sed/grep
- **Test Results**: Test coverage, passing tests
- **Last Modified Dates**: Timestamps of last changes
- **Modified By**: Who made the changes
- **Functional Proof**: Query results showing feature works

### Example Code Verification

**Verify documented code exists:**
```bash
# Read the actual retrieved code
cat force-app/main/default/classes/ClassName.cls

# Check specific line numbers mentioned in docs
sed -n '45p' force-app/main/default/classes/ClassName.cls
sed -n '78p' force-app/main/default/classes/ClassName.cls

# Search for documented code snippets
grep -n "List<CustomObject__c> records" force-app/main/default/classes/ClassName.cls
grep -n "HelperClass.helperMethod" force-app/main/default/classes/ClassName.cls

# If NOT FOUND → STOP and ASK USER
```

---

## Migration Context

### OldOrg → NewOrg Migration

**OldOrg (Source)**:
- Organization: Recycling Lives Service
- URL: recyclinglives.my.salesforce.com
- Status: Current production system
- Future: Will be decommissioned after migration

**NewOrg (Target)**:
- Organization: Recycling Lives Group
- Status: Future production system
- Purpose: Modern, consolidated Salesforce instance

**This Repository's Role**:
- Documents OldOrg as the **source** of migration
- Provides complete picture of what needs to be migrated
- Serves as reference during and after migration
- Maintains verification trail of code content

---

## Related Repositories

### Companion Repository

**Salesforce_NewOrg** (https://github.com/Shintu-John/Salesforce_NewOrg.git)
- Contains **migration plans** for each scenario
- Includes **deployment steps** with commands (CLI and Manual UI)
- Provides **gap analysis** comparing OldOrg vs NewOrg
- Offers **rollback plans** for each migration
- Has **deployment-ready code** in code/ folders

**Use Together**:
1. Review OldOrg state (this repo) → Understand what exists
2. Plan migration (NewOrg repo) → Deploy to NewOrg

---

## Important Notes

### This is a Read-Only Record

⚠️ **Do not use this repository for active development**

- This repo documents OldOrg **as it exists**
- Do not make changes to code in this repo
- Do not deploy from this repo to OldOrg
- This is for **documentation and reference only**

### For Active Development

- **OldOrg changes**: Make directly in OldOrg, then update this documentation
- **NewOrg deployment**: Use the **Salesforce_NewOrg** repository

---

## Support Information

**Documentation Owner**: John Shintu
**Organization Admins**: [OldOrg Administrators]
**Migration Project**: OldOrg → NewOrg Migration (2025)

**For Questions**:
- Scenario-specific: See individual README files
- Migration planning: See Salesforce_NewOrg repository
- General: Contact organization administrators

---

## Quick Links

- [NewOrg Migration Repository](https://github.com/Shintu-John/Salesforce_NewOrg.git)

---
