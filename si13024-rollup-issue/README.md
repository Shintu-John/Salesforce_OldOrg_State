# SI-13024 Vendor Invoice Rollup Issue - OldOrg Analysis

⚠️ **SCENARIO TYPE: ANALYSIS/TROUBLESHOOTING - NOT A CODE DEPLOYMENT**

**Date**: October 9, 2025
**Reported By**: Chantal Cooke
**Status**: ✅ RESOLVED (One-time manual fix)
**Org**: OldOrg (recyclinglives.my.salesforce.com)
**Type**: Bug Analysis & Manual Resolution

---

## ⚠️ Important: This is an Analysis Scenario

**What This Document Is**:
- Analysis of a rollup trigger bug that affected one vendor invoice
- One-time manual fix applied via Apex script
- Lessons learned for preventing similar issues

**What This Is NOT**:
- NOT a code deployment
- NOT an Apex/Trigger modification
- NOT a recurring issue requiring ongoing fixes

**Resolution Method**: Manual Apex script execution (one-time)

---

## Overview

Vendor Invoice **SI-13024** showed `Total_Invoice_Difference__c = £4,980` even after all RLCS Charges were allocated. The rollup field `Job_Charge_Total__c` was incorrectly set to £0 instead of £4,980, preventing the invoice from being released for payment.

### Business Problem

**Reported Issue**:
- Invoice SI-13024 had 13 charges correctly allocated (total £4,980)
- Field `Job_Charge_Total__c` showed £0 (should be £4,980)
- Field `Total_Invoice_Difference__c` showed £4,980 (should be £0)
- Invoice could not be released for payment

**Root Cause**:
- User edited the invoice on Oct 9, 2025 at 07:37-07:38 UTC
- This triggered the rollup calculation (Rollup_RLCS_ChargeHandler)
- The trigger incorrectly reset `Job_Charge_Total__c` to £0
- The query to recalculate from charges failed or returned empty results

**Impact**:
- 1 invoice affected (SI-13024)
- No other invoices showed this issue
- Isolated incident, not a widespread problem

---

## Timeline of Events

### September 18-23, 2025 - Invoice Created & Charges Allocated

**Sept 18, 14:50:55** - Invoice SI-13024 created:
- `Total_Net__c` = £5,295 (invoice amount from vendor)
- `Job_Charge_Total__c` = £0 (no charges allocated yet)

**Sept 23, 13:19 - 13:25** - Chantal successfully allocated 13 RLCS Charges:

| Time | Job_Charge_Total | Action | Status |
|------|------------------|--------|--------|
| 13:19:06 | £0 → £4,605 | First batch of charges allocated | ✅ Trigger worked |
| 13:24:26 | £4,605 → £4,620 | Added charge | ✅ Trigger worked |
| 13:24:30 | £4,620 → £4,635 | Added charge | ✅ Trigger worked |
| 13:24:32 | £4,635 → £4,650 | Added charge | ✅ Trigger worked |
| 13:24:35 | £4,650 → £4,665 | Added charge | ✅ Trigger worked |
| 13:25:16 | £4,665 → **£4,980** | Last charge allocated | ✅ SUCCESS |

**Result**: All 13 charges allocated correctly, totaling £4,980.

**The Problem**: Invoice showed `Total_Invoice_Difference__c = £315` because:
- `Total_Net__c` (invoice amount) = £5,295
- `Job_Charge_Total__c` (charges allocated) = £4,980
- Difference = £315 (vendor invoice was £315 too high)

---

### October 9, 2025 - Rollup Bug Triggered

**07:37:16** - First rollup malfunction:
- `Job_Charge_Total__c`: £4,980 → £315 ❌
- `Job_Charge_Missing_Paperwork__c`: false → true
- Trigger calculated incorrectly

**07:37:29** - Second rollup malfunction:
- `Job_Charge_Total__c`: £315 → £0 ❌
- `Job_Charge_Missing_Paperwork__c`: true → false
- Rollup continued to fail

**07:38:40** - Chantal manually corrected invoice amount:
- `Total_Net__c`: £5,295 → £4,980 ✅
- Chantal removed the £315 discrepancy by editing the invoice amount
- This did NOT trigger rollup recalculation

**Current State (before fix)**:
- Total_Net__c: £4,980 ✅ (correct invoice amount)
- Job_Charge_Total__c: £0 ❌ (should be £4,980)
- Total_Invoice_Difference__c: £4,980 ❌ (should be £0)
- 13 charges still linked, totaling £4,980 ✅

**08:15:07** - Fix script applied by John:
- Recalculated `Job_Charge_Total__c` from linked charges
- Updated to £4,980 ✅

**Final State (after fix)**:
- Total_Net__c: £4,980 ✅
- Job_Charge_Total__c: £4,980 ✅
- Total_Invoice_Difference__c: £0 ✅
- Invoice ready for payment ✅

---

## The 13 Charges on SI-13024

| Charge Name | Cost | Created | Currently Linked |
|-------------|------|---------|------------------|
| Charge-00030405 | £315.00 | 2025-07-25 | ✅ SI-13024 |
| Charge-00030506 | £315.00 | 2025-07-30 | ✅ SI-13024 |
| Charge-00030539 | £315.00 | 2025-08-01 | ✅ SI-13024 |
| Charge-00030540 | £315.00 | 2025-08-01 | ✅ SI-13024 |
| Charge-00030748 | £315.00 | 2025-08-05 | ✅ SI-13024 |
| Charge-00030749 | £315.00 | 2025-08-05 | ✅ SI-13024 |
| Charge-00032076 | £315.00 | 2025-08-12 | ✅ SI-13024 |
| Charge-00032074 | £315.00 | 2025-08-12 | ✅ SI-13024 |
| Charge-00032081 | £1,200.00 | 2025-08-12 | ✅ SI-13024 |
| Charge-00032443 | £315.00 | 2025-08-14 | ✅ SI-13024 |
| Charge-00033850 | £315.00 | 2025-08-20 | ✅ SI-13024 |
| Charge-00033912 | £315.00 | 2025-08-22 | ✅ SI-13024 |
| Charge-00039674 | £315.00 | 2025-09-23 | ✅ SI-13024 |

**Total**: 12 × £315 + 1 × £1,200 = **£4,980** ✅

---

## Root Cause Analysis

### The Rollup Trigger Bug

**Component**: Rollup_RLCS_ChargeHandler.cls

**The Bug** (lines 139-154):
```apex
if(isRLCSVendorLookup){
    Set<String> parentIds = rollupWrap.get(RLCS_Charge__c.Vendor_Invoice__c);

    for (String parentId : parentIds) {
        Vendor_Invoice__c parentToUpdate = (Vendor_Invoice__c) parentsToUpdateMap.get(parentId)
            ?? new Vendor_Invoice__c(Id = parentId);

        // Reset all fields
        parentToUpdate.Job_Charge_Total__c = 0;  // ⚠️ RESETS TO ZERO
        parentsToUpdateMap.put(parentToUpdate.Id, parentToUpdate);
    }

    // Later code should recalculate from charges...
    // But if query fails or returns empty, field stays at £0
}
```

**What Happened**:
1. User edited the invoice at 07:37 (changed `Total_Net__c`)
2. Vendor_Invoice__c trigger fired
3. This triggered `Rollup_RLCS_ChargeHandler`
4. Handler reset `Job_Charge_Total__c` to £0
5. Query to find charges failed or returned empty results
6. Field was updated to £0 instead of £4,980

---

### Why the Query Might Have Failed

**Hypothesis 1**: Timing issue with WHERE clause filters

**Hypothesis 2**: Parent ID mismatch in query construction

**Hypothesis 3**: Transaction isolation caused charges to not be visible

**Evidence**:
- NO RLCS_Charge__c records were modified between 07:36 and 07:39
- All 13 charges remained linked to SI-13024
- Field history shows Job_Charge_Total__c changed twice (07:37:16 and 07:37:29)
- Changes attributed to "Chantal Cooke" but not from direct field edits

---

## The Fix Applied

### Manual Script Executed

**Date**: October 9, 2025 at 08:15:07 UTC
**Executed By**: John Shintu
**Method**: Anonymous Apex execution

```apex
// Calculate actual total from all linked charges
List<RLCS_Charge__c> charges = [
    SELECT Cost__c
    FROM RLCS_Charge__c
    WHERE Vendor_Invoice__c IN (
        SELECT Id FROM Vendor_Invoice__c WHERE Name = 'SI-13024'
    )
];

Decimal actualTotal = 0;
for (RLCS_Charge__c charge : charges) {
    actualTotal += (charge.Cost__c != null ? charge.Cost__c : 0);
}

// Directly update Job_Charge_Total__c
Vendor_Invoice__c invoice = [
    SELECT Id FROM Vendor_Invoice__c WHERE Name = 'SI-13024'
];
invoice.Job_Charge_Total__c = actualTotal; // £4,980.00
update invoice;

System.debug('Updated SI-13024: Job_Charge_Total__c = ' + actualTotal);
```

**Result**:
- `Job_Charge_Total__c` updated from £0 to £4,980
- `Total_Invoice_Difference__c` recalculated to £0
- Invoice released for payment

---

## Scope Analysis

### Was This a Widespread Problem?

**Query to Find Similar Issues**:
```sql
SELECT Id, Name, Job_Charge_Total__c, Total_Invoice_Difference__c
FROM Vendor_Invoice__c
WHERE Id IN (SELECT Vendor_Invoice__c FROM RLCS_Charge__c WHERE Vendor_Invoice__c != null)
  AND Job_Charge_Total__c = 0
```

**Results**: **Only 1 invoice affected** - SI-13024

### Comparison with Similar Invoices

**SI-13023** (created same day, Sept 18):
- Total_Net__c: £4,155
- Job_Charge_Total__c: £3,240
- Total_Invoice_Difference__c: £915
- Status: ✅ Rollup working correctly (partially allocated)

**SI-13025** (created same day, Sept 18):
- Total_Net__c: £4,680
- Job_Charge_Total__c: £4,680
- Total_Invoice_Difference__c: £0
- Status: ✅ Rollup working correctly

**Conclusion**: This was an **isolated incident** specific to SI-13024. The rollup trigger works correctly for normal operations.

---

## Lessons Learned

### For NewOrg Migration

1. **Monitor Rollup Calculations**:
   - Set up alerts for invoices with charges but Job_Charge_Total__c = £0
   - Regular validation queries to catch discrepancies

2. **Rollup Trigger Improvements** (Recommendations):
   - Add logging when resetting fields to £0
   - Add safeguards: if query returns no results but charges exist, log error
   - Consider using DLRS (Declarative Lookup Rollup Summaries) instead of custom trigger

3. **User Training**:
   - Train users on when to manually update invoice amounts
   - Document that manual invoice amount changes may not trigger recalculation
   - Provide self-service validation query for users

4. **Monitoring Query** (for NewOrg):
```sql
-- Run weekly to catch rollup issues
SELECT Id, Name, Job_Charge_Total__c, Total_Invoice_Difference__c,
       (SELECT COUNT() FROM RLCS_Charges__r) AS ChargeCount
FROM Vendor_Invoice__c
WHERE Job_Charge_Total__c = 0
  AND Id IN (SELECT Vendor_Invoice__c FROM RLCS_Charge__c)
ORDER BY CreatedDate DESC
```

---

## Migration Notes for NewOrg

**No Code Changes Required**:
- This was a one-time bug in OldOrg
- No code deployment needed
- Only documentation and monitoring recommendations

**Recommended Actions for NewOrg**:
1. Review Rollup_RLCS_ChargeHandler.cls for similar reset patterns
2. Add error logging when rollup calculations result in £0 with charges present
3. Implement monitoring query (above)
4. Document manual fix procedure for future reference

**Estimated Setup Time**: 1 hour
- 30 mins: Set up monitoring query/report
- 30 mins: Document troubleshooting procedure

---

## Related Documentation

- **Complete Analysis**: [SI13024_ROLLUP_ISSUE_COMPLETE_RESOLUTION.md](../../Documentation/SI13024_ROLLUP_ISSUE_COMPLETE_RESOLUTION.md)

---

**Document Version**: 1.0
**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Status**: Complete - Analysis Only
