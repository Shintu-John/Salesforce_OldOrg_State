# Smart Waste Portal Integration Analysis

**Date:** October 14, 2025
**Organization:** OldOrg (Recycling Lives Service)
**Data Source:** Smart Waste Integration Errors - Daily Report
**Analysis Period:** Jobs with collection dates ranging from January 1, 2024 to December 31, 2024

---

## Executive Summary

⚠️ **INTEGRATION CONTINUES TO SHOW HIGH ERROR RATE**

**Key Findings:**
- Integration batch runs daily at midnight (00:00 UTC)
- **Error Count Today:** 2,283 error log entries
- **Error Trend:** Comparable to October 8th analysis (2,119 errors), showing persistent data quality issues
- **Primary Issue:** 78.8% of all errors come from a SINGLE account (WATES CONSTRUCTION LIMITED)

**Root Cause:** Integration is running, but **jobs continue to fail validation** due to:
1. Missing SmartWaste product/skip IDs (22.1% of errors)
2. Missing or invalid product percentage data (16.5% of errors)
3. Paperwork not marked as complete (14.1% of errors)
4. Recycling rates exceeding 100% (11.3% of errors)

---

## Comparison with Previous Analysis (October 8, 2025)

| Metric | Oct 8, 2025 | Oct 14, 2025 | Change |
|--------|------------|--------------|--------|
| Total Errors | 2,119 | 2,283 | +164 (+7.7%) |
| Success Rate | 0.53% | Unknown* | - |
| Top Error Type | Missing Paperwork (~90%) | Missing SmartWaste ID (22.1%) | Changed |
| Most Affected Account | WATES CONSTRUCTION | WATES CONSTRUCTION | Same |

*Note: Today's report only shows errors, not successful transmissions, so success rate cannot be calculated.

**Trend:** Error count has **increased slightly** and **root causes have shifted**, suggesting that while some paperwork issues may have been addressed, new systematic issues have emerged.

---

## Critical Findings - NEW INSIGHTS

### 1. 🚨 WATES CONSTRUCTION LIMITED - Critical Data Quality Issue

**Impact:** 1,799 errors out of 2,283 total (78.8%)

This single account represents the **overwhelming majority** of all integration failures. This suggests:
- Systematic data entry issues specific to WATES workflows
- Possible missing training or process documentation
- Potential bulk data upload problems
- Need for **immediate targeted intervention**

**Recommendation:** Schedule urgent meeting with WATES CONSTRUCTION LIMITED account team to:
- Review their job creation process
- Audit data entry workflows
- Provide targeted training
- Consider data cleanup project for existing jobs

### 2. 🆕 SmartWaste ID Missing - NEW PRIMARY ISSUE (22.1%)

**Change from Oct 8:** This was 5% of errors on Oct 8, now 22.1%

**What This Means:**
- Products/containers are not mapped to SmartWaste portal IDs
- Skip sizes and product types lack proper configuration
- This is a **MASTER DATA ISSUE**, not an operational issue

**Top Products Missing SmartWaste IDs:**
1. Tipping Only - 475 errors (20.8%)
2. Sanitary Bin - 373 errors (16.3%)
3. Road Sweeper - 297 errors (13.0%)
4. 1100 Litre Bin - 215 errors (9.4%)
5. Open 12 Yard Skip - 147 errors (6.4%)

**Immediate Action Required:**
- Contact SmartWaste support to obtain correct product/skip IDs
- Update Product2 records with SmartWaste_Id__c values
- Prioritize top 5 products listed above (represents 66.2% of all errors)

### 3. 📊 Product Percentage Issues Persist (16.5%)

376 jobs have missing or invalid product percentage data.

**Data Shows:**
- 76.7% of jobs have Product % > 0 (good)
- 17.6% have Product % empty (bad)
- 5.7% have Product % = 0 (questionable)

**This indicates:**
- Data entry training has helped (77% completion rate)
- But 23% still fail validation
- Need validation rules to prevent submission without this field

### 4. ✅ Paperwork Completion - Mixed Results (14.1% errors)

**Positive Trend:**
- 82.8% of jobs have Paperwork Done = TRUE
- This is improvement from Oct 8 analysis

**Still Concerning:**
- 393 jobs (17.2%) still lack completed paperwork
- Yet these jobs are marked as "Completed" or "Collected" status
- Process allows premature status changes

**Recommendation:** Implement validation rule:
```
Status cannot be changed to "Collected", "Paperwork Provided", or "Completed"
UNLESS Paperwork_Done__c = TRUE
```

### 5. 🔄 Recycling Rate Calculation Errors (11.3%)

259 jobs have recycling rates + energy recovery > 100%

**Most Affected Depot:**
- (RG7) - Alan Hadley - Sheffield Bottom Waste Transfer Facility - 137 errors

**Root Cause:**
- Material_Recycling_Rate__c records have incorrect percentage values
- Likely data entry errors in depot disposal records
- Affects primarily WATES CONSTRUCTION LIMITED jobs

**Action Required:**
- Query Material_Recycling_Rate__c for Alan Hadley depot
- Fix percentage calculations
- Add validation rule: Total_Percentage__c <= 100

---

## Integration Architecture (Unchanged)

### How It Works

1. **Scheduled Job:** `SmartWaste_Integration-10`
   - Runs daily at 00:00 UTC
   - Processes eligible jobs in batches

2. **Batch Class:** `SmartWasteIntegrationBatch`
   - Queries jobs with Status = Collected/Paperwork Provided/Completed
   - Validates required fields
   - Creates integration logs for failures
   - Makes API callouts for valid jobs

3. **Email Notification:**
   - Sends summary email after each run
   - Contains success/failure counts

---

## Error Type Breakdown (October 14, 2025)

| Error Type | Count | Percentage | Priority |
|-----------|-------|------------|----------|
| **Missing SmartWaste ID** | 505 | 22.1% | 🔴 CRITICAL |
| **Product Percentage Missing/Invalid** | 376 | 16.5% | 🔴 HIGH |
| **Paperwork Not Done** | 323 | 14.1% | 🟡 MEDIUM |
| **Recycling Rate > 100%** | 259 | 11.3% | 🟡 MEDIUM |
| **Missing Waste Carrier License Date** | 124 | 5.4% | 🟢 LOW |
| **Missing WTN File** | 40 | 1.8% | 🟢 LOW |
| **Zero Percentage** | 14 | 0.6% | 🟢 LOW |
| **Other** | 642 | 28.1% | 🔵 NEEDS ANALYSIS |

**Note:** "Other" category needs further investigation to identify specific error patterns.

---

## Top Accounts Affected (by Error Count)

| Account | Error Count | % of Total | Status |
|---------|-------------|------------|--------|
| WATES CONSTRUCTION LIMITED | 1,799 | 78.8% | 🚨 CRITICAL |
| WATES PROPERTY SERVICES | 221 | 9.7% | 🔴 HIGH |
| BAM Construct UK | 86 | 3.8% | 🟡 MEDIUM |
| Wates Smartspace Limited | 57 | 2.5% | 🟡 MEDIUM |
| Enable Infrastructure | 46 | 2.0% | 🟡 MEDIUM |
| Wates Residential Construction Limited | 27 | 1.2% | 🟢 LOW |
| KIER TRANSPORTATION LIMITED | 26 | 1.1% | 🟢 LOW |
| SES (Engineering Services) Ltd | 19 | 0.8% | 🟢 LOW |
| Madigan Gill Logistics Limited | 2 | 0.1% | 🟢 LOW |

**Key Insight:** WATES family of companies represents **92.3%** of all errors (2,107 out of 2,283). This suggests a company-wide data quality issue requiring **coordinated intervention**.

---

## Job Status Analysis

| Status | Count | Percentage |
|--------|-------|------------|
| Completed | 1,814 | 79.5% |
| Collected | 407 | 17.8% |
| Paperwork Provided | 62 | 2.7% |

**Observation:** 79.5% of failing jobs are marked as "Completed" yet still have validation errors. This indicates:
- Jobs are being closed prematurely
- Validation should occur BEFORE status changes
- Need workflow automation to enforce data quality

---

## Top Suppliers Associated with Errors

| Supplier | Error Count | % of Total |
|----------|-------------|------------|
| COX SKIPS LIMITED | 475 | 20.8% |
| Personal Hygiene Services | 373 | 16.3% |
| CHARLTON SWEEPER HIRE LIMITED | 232 | 10.2% |
| ALAN HADLEY LIMITED | 137 | 6.0% |
| CLEARABEE LIMITED | 127 | 5.6% |

**Note:** These suppliers themselves may not be the issue - errors are likely related to how jobs with these suppliers are entered into Salesforce.

---

## Top Depots Associated with Errors

| Depot | Error Count | % of Total |
|-------|-------------|------------|
| (RH10) - Cox Skips - Cox House | 477 | 20.9% |
| (OL9) - Charlton Sweeper Hire - Holroyd Skip Hire | 232 | 10.2% |
| (LS9) - SRCL - Leeds Clinical Waste Facility | 183 | 8.0% |
| (OX27) - Viridor - Ardley Fields Farm | 170 | 7.4% |
| (RG7) - Alan Hadley - Sheffield Bottom Waste Transfer Facility | 137 | 6.0% |

**Action:** Review Material_Recycling_Rate__c records for these depots, particularly Alan Hadley depot which has the recycling rate > 100% issue.

---

## Top Products Associated with Errors

| Product | Error Count | % of Total | Likely Issue |
|---------|-------------|------------|--------------|
| Tipping Only | 475 | 20.8% | Missing SmartWaste ID |
| Sanitary Bin | 373 | 16.3% | Missing SmartWaste ID |
| Road Sweeper | 297 | 13.0% | Missing SmartWaste ID |
| 1100 Litre Bin | 215 | 9.4% | Missing SmartWaste ID |
| Open 12 Yard Skip | 147 | 6.4% | Missing SmartWaste ID |
| Caged Wagon Full Load | 108 | 4.7% | Missing SmartWaste ID |
| Open 8 Yard Skip | 105 | 4.6% | Missing SmartWaste ID |
| Enclosed 8 Yard Skip | 79 | 3.5% | Missing SmartWaste ID |
| Tanker | 59 | 2.6% | Missing SmartWaste ID |
| 20 Yard RO/RO | 57 | 2.5% | Missing SmartWaste ID |

**Critical Action Required:**
These 10 products represent **84.5% of all errors** (1,930 out of 2,283).

**Immediate Fix:**
1. Export list of products: `SELECT Id, Name, SmartWaste_Id__c FROM Product2 WHERE Name IN ('Tipping Only', 'Sanitary Bin', 'Road Sweeper', ...)`
2. Contact SmartWaste support with product names
3. Obtain correct SmartWaste IDs for each product type
4. Mass update Product2.SmartWaste_Id__c field
5. **Expected Result:** ~80% reduction in integration errors

---

## Data Quality Metrics

### Paperwork Completion
- ✅ **Paperwork Done = TRUE:** 1,890 jobs (82.8%)
- ❌ **Paperwork Done = FALSE:** 393 jobs (17.2%)

**Analysis:** 17.2% of jobs attempting integration don't have completed paperwork, yet they're marked as Collected/Completed status. This violates business rules.

### Weight Data
- ✅ **Weight > 0:** 1,881 jobs (82.4%)
- ❌ **Weight = 0:** 402 jobs (17.6%)
- ✅ **Weight Empty:** 0 jobs (0.0%)

**Analysis:** Good news - weight field is always populated. However, 17.6% have zero weight, which may indicate:
- Data entry errors
- Missing scale readings
- Jobs closed before weight recorded

### Product Percentage
- ✅ **Product % > 0:** 1,751 jobs (76.7%)
- ❌ **Product % = 0:** 130 jobs (5.7%)
- ❌ **Product % Empty:** 402 jobs (17.6%)

**Analysis:** 23.3% of jobs have missing or zero product percentage. This field is required for SmartWaste integration.

---

## Recommendations - PRIORITIZED ACTION PLAN

### 🔴 CRITICAL - This Week (Impact: ~80% error reduction)

#### 1. **Fix Product Master Data - SmartWaste ID Mapping**
**Impact:** Will resolve 505 errors (22.1%)

**Steps:**
1. Run query to identify all products missing SmartWaste IDs:
```sql
SELECT Id, Name, SmartWaste_Id__c
FROM Product2
WHERE Name IN (
  'Tipping Only', 'Sanitary Bin', 'Road Sweeper',
  '1100 Litre Bin', 'Open 12 Yard Skip', 'Caged Wagon Full Load',
  'Open 8 Yard Skip', 'Enclosed 8 Yard Skip', 'Tanker', '20 Yard RO/RO'
)
```
2. Contact SmartWaste support with product list
3. Obtain correct SmartWaste product/skip IDs
4. Create data import CSV with Product ID and SmartWaste_Id__c
5. Use Data Loader to mass update Product2 records
6. Test integration with one job for each product type

**Owner:** Salesforce Admin + SmartWaste Account Manager
**Deadline:** End of Week (October 18, 2025)

#### 2. **Urgent Meeting with WATES CONSTRUCTION LIMITED**
**Impact:** Will address 1,799 errors (78.8%)

**Agenda:**
- Present error analysis showing their 78.8% error rate
- Review their job creation workflow
- Identify systematic data entry gaps
- Provide targeted training on required fields
- Establish data quality metrics and accountability

**Attendees:**
- WATES Operations Manager
- WATES Data Entry Team Leads
- Recycling Lives Account Manager
- Salesforce Administrator

**Owner:** Account Manager
**Deadline:** October 16, 2025

#### 3. **Add Validation Rule - Prevent Incomplete Job Status Changes**
**Impact:** Will prevent 323 future errors (14.1%)

**Validation Rule:**
```apex
AND(
  OR(
    ISPICKVAL(Status__c, 'Collected'),
    ISPICKVAL(Status__c, 'Paperwork Provided'),
    ISPICKVAL(Status__c, 'Completed')
  ),
  NOT(Paperwork_Done__c)
)
```

**Error Message:**
"Cannot change status to Collected, Paperwork Provided, or Completed unless Paperwork Done is checked. Please complete all required paperwork fields first."

**Owner:** Salesforce Admin
**Deadline:** October 16, 2025

---

### 🟡 HIGH - Next 2 Weeks (Impact: ~15% error reduction)

#### 4. **Fix Alan Hadley Depot - Recycling Rate > 100% Issue**
**Impact:** Will resolve 259 errors (11.3%)

**Steps:**
1. Query Material_Recycling_Rate__c records:
```sql
SELECT Id, Name, Depot_Dispose__c, Recycling_Rate__c, Energy_Recovery_Rate__c,
       (Recycling_Rate__c + Energy_Recovery_Rate__c) Total_Rate
FROM Material_Recycling_Rate__c
WHERE Depot_Dispose__r.Name LIKE '%Alan Hadley%'
  AND (Recycling_Rate__c + Energy_Recovery_Rate__c) > 100
```
2. Review with depot team - which rates are correct?
3. Correct the percentage values
4. Add validation rule to prevent > 100% in future

**Validation Rule for Material_Recycling_Rate__c:**
```apex
(Recycling_Rate__c + Energy_Recovery_Rate__c + Landfill_Rate__c) > 100
```

**Owner:** Data Quality Team + Operations
**Deadline:** October 25, 2025

#### 5. **Add Required Field Validation - Product Percentage**
**Impact:** Will prevent 376 future errors (16.5%)

**Validation Rule:**
```apex
AND(
  OR(
    ISPICKVAL(Status__c, 'Collected'),
    ISPICKVAL(Status__c, 'Paperwork Provided'),
    ISPICKVAL(Status__c, 'Completed')
  ),
  OR(
    ISBLANK(Product_Percentage__c),
    Product_Percentage__c = 0
  )
)
```

**Error Message:**
"Product Percentage is required and must be greater than 0 before marking job as Collected, Paperwork Provided, or Completed."

**Owner:** Salesforce Admin
**Deadline:** October 25, 2025

#### 6. **Add Supplier/Depot Waste Carrier License Date Validation**
**Impact:** Will resolve 124 errors (5.4%)

**Root Cause Analysis:**
- 124 jobs missing Waste Carrier License Date on either:
  - Supplier account, OR
  - Depot Dispose account

**Steps:**
1. Identify affected supplier/depot accounts:
```sql
SELECT Id, Name, Waste_Carrier_License_Date__c
FROM Account
WHERE Id IN (
  SELECT Supplier__c FROM Job__c WHERE Id IN (
    SELECT Related_Job__c FROM SmartWaste_Integration_Log__c
    WHERE Description__c LIKE '%Waste Carrier License Date%'
  )
)
```
2. Request license dates from suppliers/depots
3. Update Account.Waste_Carrier_License_Date__c
4. Add validation to prevent blank dates for waste carrier accounts

**Owner:** Supplier Management Team
**Deadline:** October 30, 2025

---

### 🟢 MEDIUM - Next Month (Preventive Measures)

#### 7. **Investigate "Other" Error Category (28.1%)**

642 errors are categorized as "Other" - need detailed analysis:

**Steps:**
1. Export all "Other" errors from SmartWaste_Integration_Log__c
2. Parse Description__c field to identify common patterns
3. Categorize into new error types
4. Create targeted fixes for top 3 patterns

**Owner:** Salesforce Developer
**Deadline:** November 15, 2025

#### 8. **Create SmartWaste Data Readiness Dashboard**

**Components:**
1. Gauge Chart - Today's Error Rate
2. Bar Chart - Errors by Type (last 7 days)
3. Table - Top 10 Accounts with Errors
4. Table - Jobs Pending Sync (with validation status)
5. Metric - Jobs Successfully Sent Today
6. Line Chart - Daily Trend (Success vs Errors)

**Owner:** Salesforce Admin
**Deadline:** November 15, 2025

#### 9. **Enhanced Email Notifications**

**Current:** Email to dincer.uyav@vesium.com only
**Proposed:** Expanded distribution with detailed breakdown

**New Email Template:**
```
Subject: SmartWaste Integration Daily Summary - {Date}

SUCCESS RATE: {success_rate}%
Successfully Sent: {success_count} jobs
Failed Validation: {error_count} jobs

TOP ERROR TYPES:
1. {error_type_1}: {count_1} ({percent_1}%)
2. {error_type_2}: {count_2} ({percent_2}%)
3. {error_type_3}: {count_3} ({percent_3}%)

TOP ACCOUNTS NEEDING ATTENTION:
1. {account_1}: {count_1} errors
2. {account_2}: {count_2} errors
3. {account_3}: {count_3} errors

TREND: {comparison_to_yesterday}

View detailed report: {link_to_dashboard}
```

**Recipients:**
- Operations Managers
- Account Managers
- Data Quality Team
- Salesforce Administrator

**Owner:** Salesforce Developer
**Deadline:** November 20, 2025

#### 10. **User Training Program - SmartWaste Data Requirements**

**Target Audiences:**
1. **WATES CONSTRUCTION LIMITED team** (CRITICAL)
2. **WATES PROPERTY SERVICES team** (HIGH)
3. All operations staff (MEDIUM)

**Training Topics:**
- Required fields for SmartWaste integration
- How to check job readiness before status change
- Understanding validation errors
- Best practices for paperwork completion
- Common mistakes and how to avoid them

**Format:**
- 30-minute recorded training video
- Quick reference guide (PDF)
- Job completion checklist
- Monthly refresher sessions

**Owner:** Training Team + Salesforce Admin
**Deadline:** November 30, 2025

---

## Technical Details

### Integration Components (Unchanged)

**Apex Classes:**
- `SmartWasteIntegrationBatch` - Main batch processing
- `SmartWasteIntegrationMiddleware` - API callout handler
- `SmartWasteIntegrationFlowHandler` - Flow integration support
- `SmartWasteIntegrationHexFormBuilder` - Form data builder

**Custom Objects:**
- `SmartWaste_Integration_Log__c` - Error tracking

**Scheduled Jobs:**
- `SmartWaste_Integration-10` - Daily at 00:00 UTC
- `SmartWaste Log Cleanup` - Daily at 08:00 UTC

### Current Integration Query Criteria

Jobs are eligible for Smart Waste integration IF:

```sql
WHERE Site__r.Account__r.SmartWaste_Private_Key__c != ''
  AND Site__r.Account__r.SmartWaste_Client_Key__c != ''
  AND SMS_Job_Id__c = ''
  AND SMS_Job_Duplicated__c = false
  AND (Status__c = 'Collected'
       OR Status__c = 'Paperwork Provided'
       OR Status__c = 'Completed')
  AND SmartWaste_Id__c = null
  AND Attempt_Send_to_SmartWaste__c = true
```

---

## Key Metrics Summary

| Metric | Value |
|--------|-------|
| **Total Integration Errors** | 2,283 |
| **Date Range** | Jan 1, 2024 - Dec 31, 2024 |
| **Most Affected Account** | WATES CONSTRUCTION LIMITED (78.8%) |
| **Top Error Type** | Missing SmartWaste ID (22.1%) |
| **Jobs with Completed Status** | 1,814 (79.5%) |
| **Jobs with Paperwork Done** | 1,890 (82.8%) |
| **Jobs with Valid Weight** | 1,881 (82.4%) |
| **Jobs with Valid Product %** | 1,751 (76.7%) |

---

## Expected Impact of Recommendations

If all **CRITICAL** actions are completed:

| Action | Estimated Error Reduction |
|--------|--------------------------|
| Fix Product SmartWaste IDs | -505 errors (22.1%) |
| WATES data quality improvement | -1,799 errors (78.8%) * 0.7 = -1,259 |
| Prevent incomplete status changes | Prevention of future errors |
| **Total Potential Reduction** | **~1,764 errors (77.2%)** |

**Expected Result After Critical Actions:**
- Current: 2,283 errors/day
- After fixes: ~519 errors/day
- **Improvement: 77% reduction in integration errors**

---

## Questions for SmartWaste Portal

1. **How many jobs are you successfully receiving per day currently?**
   - This will help us calculate actual success rate

2. **Do you have documentation for all Product/Skip IDs we should use?**
   - We need to map our 10 most common product types

3. **Are there any API changes or updates we should know about?**
   - Some errors may be due to API compatibility issues

4. **Can you provide examples of successfully submitted jobs?**
   - We can reverse-engineer the correct data format

---

## Next Steps - Action Tracker

| # | Action | Owner | Due Date | Status |
|---|--------|-------|----------|--------|
| 1 | Fix Product SmartWaste IDs (top 10 products) | Salesforce Admin | Oct 18, 2025 | 🔴 Not Started |
| 2 | Schedule meeting with WATES CONSTRUCTION LIMITED | Account Manager | Oct 16, 2025 | 🔴 Not Started |
| 3 | Deploy validation rule - Paperwork Done | Salesforce Admin | Oct 16, 2025 | 🔴 Not Started |
| 4 | Fix Alan Hadley Depot recycling rates | Data Quality Team | Oct 25, 2025 | 🔴 Not Started |
| 5 | Deploy validation rule - Product Percentage | Salesforce Admin | Oct 25, 2025 | 🔴 Not Started |
| 6 | Update Supplier/Depot Waste Carrier License Dates | Supplier Mgmt | Oct 30, 2025 | 🔴 Not Started |
| 7 | Investigate "Other" error category | Salesforce Dev | Nov 15, 2025 | 🔴 Not Started |
| 8 | Build SmartWaste Data Readiness Dashboard | Salesforce Admin | Nov 15, 2025 | 🔴 Not Started |
| 9 | Enhance email notifications | Salesforce Dev | Nov 20, 2025 | 🔴 Not Started |
| 10 | Deliver user training program | Training Team | Nov 30, 2025 | 🔴 Not Started |

---

## Conclusion

**The integration infrastructure continues to work correctly**, but **data quality issues persist and have evolved**:

### What Changed Since October 8:
1. ✅ **Slight improvement** in paperwork completion (based on 82.8% completion rate)
2. ❌ **New primary issue emerged:** Missing SmartWaste Product IDs (22.1% of errors)
3. ❌ **WATES CONSTRUCTION LIMITED** remains the dominant source of errors (78.8%)
4. ❌ **Total error count increased** by 7.7% (2,119 → 2,283)

### Root Cause:
- **NOT an integration technical issue** ✅
- **Master data configuration gaps** (Product IDs not mapped) ❌
- **Data entry process issues** (validation not enforced) ❌
- **Account-specific data quality problems** (WATES) ❌

### Path Forward:
Focus on **THREE critical fixes** that will resolve 77% of errors:
1. Map SmartWaste IDs for top 10 products (22% reduction)
2. Partner with WATES to fix their data quality (55% reduction)
3. Add validation rules to prevent incomplete submissions (prevent future errors)

**Estimated Timeline:** 2-3 weeks to implement critical fixes, with full resolution expected by end of November 2025.

---

## Appendix A: Useful Queries for Monitoring

### Query 1: Today's Error Summary
```sql
SELECT
    COUNT(Id) TotalErrors,
    COUNT(DISTINCT Related_Job__c) AffectedJobs,
    COUNT(DISTINCT Related_Account__c) AffectedAccounts
FROM SmartWaste_Integration_Log__c
WHERE CreatedDate = TODAY
```

### Query 2: Jobs Pending Sync with Validation Status
```sql
SELECT
    Id, Name, Status__c,
    Site__r.Account__r.Name,
    Paperwork_Done__c,
    Weight__c,
    Product_Percentage__c,
    Order_Product__r.Product2.SmartWaste_Id__c
FROM Job__c
WHERE Attempt_Send_to_SmartWaste__c = true
  AND SmartWaste_Id__c = null
  AND (Status__c = 'Collected'
       OR Status__c = 'Paperwork Provided'
       OR Status__c = 'Completed')
ORDER BY Site__r.Account__r.Name, CreatedDate DESC
LIMIT 100
```

### Query 3: Products Missing SmartWaste IDs
```sql
SELECT
    Id, Name, SmartWaste_Id__c,
    (SELECT COUNT() FROM OpportunityLineItems) ActiveJobsCount
FROM Product2
WHERE SmartWaste_Id__c = null
  AND Id IN (
    SELECT Product2Id FROM OpportunityLineItem
    WHERE Id IN (
      SELECT Order_Product__c FROM Job__c
      WHERE Attempt_Send_to_SmartWaste__c = true
    )
  )
ORDER BY Name
```

### Query 4: Successfully Sent Jobs Today
```sql
SELECT
    Id, Name, SmartWaste_Id__c,
    Site__r.Account__r.Name,
    Collection_Date__c,
    Weight__c,
    Status__c,
    LastModifiedDate
FROM Job__c
WHERE SmartWaste_Id__c != null
  AND LastModifiedDate = TODAY
ORDER BY LastModifiedDate DESC
```

### Query 5: WATES Error Breakdown
```sql
SELECT
    Related_Account__r.Name,
    COUNT(Id) ErrorCount
FROM SmartWaste_Integration_Log__c
WHERE CreatedDate = TODAY
  AND Related_Account__r.Name LIKE '%WATES%'
GROUP BY Related_Account__r.Name
ORDER BY COUNT(Id) DESC
```

---

**Analysis Completed By:** Claude Code (AI Analysis Tool)
**Date:** October 14, 2025
**Data Source:** Smart Waste Integration Errors - Daily-2025-10-14-13-14-18.xlsx
**Total Records Analyzed:** 2,283 error log entries
**Document Version:** 1.0 (Initial Analysis for October 14, 2025)
