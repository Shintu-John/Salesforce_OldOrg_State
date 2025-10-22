# PO Consumption Email Notifications - OldOrg Current State

**Scenario**: Purchase Order Consumption Monitoring System
**Last Updated**: October 22, 2025
**Deployment Date**: October 14, 2025
**Deployed By**: John Shintu
**Status**: ✅ Active in Production

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Overview](#system-overview)
3. [Components Inventory](#components-inventory)
4. [Verification Evidence](#verification-evidence)
5. [Business Logic](#business-logic)
6. [Configuration](#configuration)
7. [Implementation History](#implementation-history)
8. [Integration Points](#integration-points)
9. [Files and Metadata](#files-and-metadata)

---

## Executive Summary

### What This System Does

Automated email notification system that monitors Purchase Order consumption and alerts stakeholders when consumption reaches critical thresholds (50%, 75%, 90%).

### Key Features

- ✅ **Multi-Threshold Monitoring**: Alerts at 50%, 75%, and 90% consumption
- ✅ **Automatic Reset Logic**: Resets notifications when consumption drops below thresholds, enabling re-notification
- ✅ **Configurable Per PO**: Enable/disable monitoring for specific Purchase Orders via Custom Setting
- ✅ **Scalable**: Add more POs without code changes
- ✅ **4 Email Recipients**: customerservice@, Mark Simpson, Dennis Dadey, Kaylie Morris
- ✅ **URGENT Escalation**: 90% notifications marked as URGENT

### Current Production Status

**Monitoring**: 1 Purchase Order (Order #00059438)
**Current Consumption**: 0% (£0 of £63,000)
**Notifications Sent**: 0 (PO below first threshold)
**System Health**: ✅ All components active and functioning

---

## System Overview

### Architecture

```
Order Record Updated
    ↓
Flow Triggered: Order_Consumption_Multi_Threshold_Notification
    ↓
Custom Setting Lookup: Is this PO monitored?
    ↓ (Yes - found in PO_Notification_Settings__c)
    ↓
Reset Logic: Uncheck notification flags if consumption dropped below thresholds
    ↓
Check 90% Threshold
    ├─ If ≥90% AND not previously notified → Send URGENT email, mark Notified_90_Percent__c
    └─ If <90% → Continue
    ↓
Check 75% Threshold
    ├─ If ≥75% AND <90% AND not previously notified → Send email, mark Notified_75_Percent__c
    └─ If <75% → Continue
    ↓
Check 50% Threshold
    ├─ If ≥50% AND <75% AND not previously notified → Send email, mark Notified_50_Percent__c
    └─ If <50% → End
```

### Business Problem Solved

**Original Request**: Alisha Miller requested email notification when Purchase Order #00059438 reaches 50% of maximum value.

**Stakeholder Requirements** (Oct 14, 2025):
- Alert at 50%, 75%, and 90% consumption
- One-time notification per threshold crossing (no daily reminders)
- Re-notify if consumption drops then rises again
- Email 4 recipients: Customer Service team + 3 key stakeholders
- 90% alerts marked as URGENT
- Configurable system to easily add more POs

---

## Components Inventory

### 1. Custom Setting Object

**API Name**: `PO_Notification_Settings__c`
**Type**: List Custom Setting
**Purpose**: Controls which POs are monitored

**Fields**:

| Field API Name | Type | Description |
|----------------|------|-------------|
| `PO_ID__c` | Text(18) | Salesforce ID of Order record |
| `PO_Number__c` | Text(20) | Order number (reference only) |
| `Notifications_Enabled__c` | Checkbox | Master on/off switch for this PO |
| `Use_Repeated_Reminders__c` | Checkbox | Toggle notification mode (currently unused) |
| `Reminder_Frequency_Hours__c` | Number | Hours between reminders (for future use) |

**Deploy ID**: 0AfSj000000yjOrKAI

### 2. Order Object Fields (6 fields)

**Purpose**: Track notification state for each threshold

| Field API Name | Type | Description |
|----------------|------|-------------|
| `Notified_50_Percent__c` | Checkbox | Has 50% email been sent? |
| `Notified_75_Percent__c` | Checkbox | Has 75% email been sent? |
| `Notified_90_Percent__c` | Checkbox | Has 90% email been sent? |
| `Notified_50_Percent_Date__c` | DateTime | When was 50% email sent? |
| `Notified_75_Percent_Date__c` | DateTime | When was 75% email sent? |
| `Notified_90_Percent_Date__c` | DateTime | When was 90% email sent? |

**Deploy ID**: 0AfSj000000yjThKAI

**Formula Logic** (Reset checkboxes when below thresholds):
```
Notified_50_Percent__c = IF(Consumed_Percent__c >= 50, TRUE, FALSE)
Notified_75_Percent__c = IF(Consumed_Percent__c >= 75, TRUE, FALSE)
Notified_90_Percent__c = IF(Consumed_Percent__c >= 90, TRUE, FALSE)
```

### 3. Email Templates (3 templates)

**Purpose**: HTML email notifications for each threshold

| Template Name | Subject | Recipients |
|---------------|---------|------------|
| `PO_Consumption_50_Percent_Alert` | Purchase Order {!Order.OrderNumber} - 50% Consumed | 4 stakeholders |
| `PO_Consumption_75_Percent_Alert` | Purchase Order {!Order.OrderNumber} - 75% Consumed | 4 stakeholders |
| `PO_Consumption_90_Percent_Alert` | Purchase Order {!Order.OrderNumber} - 90% Consumed (URGENT) | 4 stakeholders |

**Deploy ID**: 0AfSj000000yjYXKAY

**Recipients (all templates)**:
- customerservice@recyclinglives-services.com
- Mark.Simpson@recyclinglives-services.com
- Dennis.Dadey@recyclinglives-services.com
- kaylie.morris@recyclinglives-services.com

### 4. Flow

**API Name**: `Order_Consumption_Multi_Threshold_Notification`
**Type**: Record-Triggered Flow (AutoLaunchedFlow)
**Trigger**: Order record updated
**Version**: 1 (Active)
**Deploy ID**: 0AfSj000000yk3BKAQ

**Flow Logic**:
1. Get Custom Setting record for this Order
2. Check if notifications enabled
3. Reset logic: Uncheck flags if consumption dropped
4. Check 90% threshold → Send email if needed
5. Check 75% threshold → Send email if needed
6. Check 50% threshold → Send email if needed
7. Update Order with notification flags and timestamps

---

## Verification Evidence

### Flow Status

**Verification Date**: October 22, 2025

**Query**:
```sql
SELECT Definition.DeveloperName, VersionNumber, Status, ProcessType,
       LastModifiedDate, LastModifiedBy.Name
FROM Flow
WHERE Definition.DeveloperName = 'Order_Consumption_Multi_Threshold_Notification'
```

**Results**:

| Field | Value |
|-------|-------|
| DeveloperName | Order_Consumption_Multi_Threshold_Notification |
| VersionNumber | 1 |
| Status | Active ✅ |
| ProcessType | AutoLaunchedFlow |
| LastModifiedDate | 2025-10-14 08:36:55 |
| LastModifiedBy | John Shintu |

**Analysis**: ✅ Flow is Active and matches deployment date (Oct 14, 2025)

### Email Templates

**Verification Date**: October 22, 2025

**Query**:
```sql
SELECT Name, Subject
FROM EmailTemplate
WHERE Name LIKE '%PO%Consumption%'
```

**Results**:

| Name | Subject |
|------|---------|
| PO Consumption 50 Percent Alert | Purchase Order {!Order.OrderNumber} - 50% Consumed |
| PO Consumption 75 Percent Alert | Purchase Order {!Order.OrderNumber} - 75% Consumed |
| PO Consumption 90 Percent Alert | Purchase Order {!Order.OrderNumber} - 90% Consumed (URGENT) |

**Analysis**: ✅ All 3 email templates exist and have correct subjects

### Current Custom Setting Data

**PO Being Monitored**:

```
Name: PO_00059438
PO_ID__c: 801Sj00000OjGCUIA3
PO_Number__c: 00059438
Notifications_Enabled__c: TRUE
Use_Repeated_Reminders__c: FALSE
Reminder_Frequency_Hours__c: 24
```

**Order Details**:
- Account: Sheffield City Council
- Total Amount: £63,000
- Consumed Amount: £0 (0%)
- Status: Active

---

## Business Logic

### Reset Logic (Option B)

**How It Works**: Notification checkboxes automatically reset when consumption drops below thresholds.

**Example Scenario**:

**Step 1**: PO reaches 55% consumption
- Flow checks: 55% >= 50%? YES
- Flow sets: `Notified_50_Percent__c = TRUE`
- Flow sends: 50% email to 4 recipients ✅

**Step 2**: PO consumption drops to 45%
- Flow checks: 45% >= 50%? NO
- Flow sets: `Notified_50_Percent__c = FALSE` (auto-reset)
- No email sent

**Step 3**: PO rises back to 60%
- Flow checks: 60% >= 50%? YES AND `Notified_50_Percent__c = FALSE`
- Flow sends: 50% email again ✅
- Flow sets: `Notified_50_Percent__c = TRUE`

### Threshold Logic

**Three Independent Checks** (in order):

1. **90% Check**:
   - IF `Consumed_Percent__c >= 90` AND `Consumed_Percent__c < 100` AND `Notified_90_Percent__c = FALSE`
   - THEN send URGENT email, set checkbox TRUE, record timestamp

2. **75% Check**:
   - IF `Consumed_Percent__c >= 75` AND `Consumed_Percent__c < 90` AND `Notified_75_Percent__c = FALSE`
   - THEN send email, set checkbox TRUE, record timestamp

3. **50% Check**:
   - IF `Consumed_Percent__c >= 50` AND `Consumed_Percent__c < 75` AND `Notified_50_Percent__c = FALSE`
   - THEN send email, set checkbox TRUE, record timestamp

**Why This Order Matters**: Ensures only ONE email is sent per update, even if multiple thresholds are crossed.

---

## Configuration

### How to Add a New PO to Monitoring

**No code deployment required** - simply add Custom Setting record:

1. Navigate to: Setup → Custom Settings → PO Notification Settings → Manage
2. Click: **New**
3. Fill in:
   - **Name**: `PO_[OrderNumber]` (e.g., `PO_00059439`)
   - **PO ID**: 18-character Salesforce Order ID
   - **PO Number**: Order number (for reference)
   - **Notifications Enabled**: ☑ (checked)
   - **Use Repeated Reminders**: ☐ (unchecked for Option B)
   - **Reminder Frequency Hours**: 24
4. Click: **Save**

**Result**: PO will be monitored immediately on next Order update.

### How to Disable Monitoring

**Option 1**: Uncheck `Notifications_Enabled__c` in Custom Setting record
**Option 2**: Delete Custom Setting record entirely

### How to Manually Resend Notification

1. Navigate to Order record
2. Edit Order
3. Uncheck appropriate notification checkbox:
   - `Notified_50_Percent__c` for 50% notification
   - `Notified_75_Percent__c` for 75% notification
   - `Notified_90_Percent__c` for 90% notification
4. Save Order
5. Make small edit to trigger Flow (e.g., add note to Description)
6. Save again → Email will resend

---

## Implementation History

### V1: Initial Implementation (Oct 13-14, 2025)

**Business Requirements**:
- Request from: Alisha Miller
- Monitor: PO #00059438 (Sheffield City Council)
- Thresholds: 50%, 75%, 90%
- Recipients: 4 stakeholders
- Behavior: One-time per threshold, but reset if consumption drops

**Implementation**:
- Created Custom Setting for PO configuration
- Added 6 fields to Order object (3 checkboxes + 3 timestamps)
- Created 3 HTML email templates
- Built record-triggered Flow with reset logic

**Testing**:
- Tested threshold crossing logic
- Verified email delivery to all 4 recipients
- Confirmed reset logic works correctly
- Validated Custom Setting integration

**Deployment**:
- **Date**: October 14, 2025
- **Deploy IDs**:
  - Custom Setting: 0AfSj000000yjOrKAI
  - Order Fields: 0AfSj000000yjThKAI
  - Email Templates: 0AfSj000000yjYXKAY
  - Flow: 0AfSj000000yk3BKAQ
- **Status**: All successful
- **Manual Config**: Added PO_00059438 to Custom Setting

**Production Metrics**:
- **PO Monitored**: 1
- **Notifications Sent**: 0 (PO currently at 0% consumption)
- **System Uptime**: 8 days (as of Oct 22, 2025)
- **Errors**: 0

---

## Integration Points

### Dependencies

**Upstream**:
- Order object standard fields: `TotalAmount`, `OrderNumber`, `Status`
- Order custom field: `Consumed_Amount__c` (calculated field showing total consumed)
- Order formula field: `Consumed_Percent__c` (Consumed_Amount__c / TotalAmount * 100)

**Downstream**:
- Email delivery system (SMTP)
- Email recipients' inboxes

### Related Systems

**None** - This is a standalone monitoring system with no dependencies on other custom processes.

### Trigger Mechanism

**Flow Trigger**:
- **Object**: Order
- **Trigger**: Record is updated
- **Entry Criteria**:
  - Order exists in `PO_Notification_Settings__c` Custom Setting
  - `Notifications_Enabled__c = TRUE`
- **When to Run**: After save

---

## Files and Metadata

### Custom Setting

**File**: `force-app/main/default/objects/PO_Notification_Settings__c/PO_Notification_Settings__c.object-meta.xml`

**Fields**:
- `force-app/main/default/objects/PO_Notification_Settings__c/fields/PO_ID__c.field-meta.xml`
- `force-app/main/default/objects/PO_Notification_Settings__c/fields/PO_Number__c.field-meta.xml`
- `force-app/main/default/objects/PO_Notification_Settings__c/fields/Notifications_Enabled__c.field-meta.xml`
- `force-app/main/default/objects/PO_Notification_Settings__c/fields/Use_Repeated_Reminders__c.field-meta.xml`
- `force-app/main/default/objects/PO_Notification_Settings__c/fields/Reminder_Frequency_Hours__c.field-meta.xml`

### Order Fields

**Directory**: `force-app/main/default/objects/Order/fields/`

- `Notified_50_Percent__c.field-meta.xml`
- `Notified_75_Percent__c.field-meta.xml`
- `Notified_90_Percent__c.field-meta.xml`
- `Notified_50_Percent_Date__c.field-meta.xml`
- `Notified_75_Percent_Date__c.field-meta.xml`
- `Notified_90_Percent_Date__c.field-meta.xml`

### Email Templates

**Directory**: `force-app/main/default/email/unfiled$public/`

- `PO_Consumption_50_Percent_Alert.email`
- `PO_Consumption_50_Percent_Alert.email-meta.xml`
- `PO_Consumption_75_Percent_Alert.email`
- `PO_Consumption_75_Percent_Alert.email-meta.xml`
- `PO_Consumption_90_Percent_Alert.email`
- `PO_Consumption_90_Percent_Alert.email-meta.xml`

### Flow

**File**: `force-app/main/default/flows/Order_Consumption_Multi_Threshold_Notification.flow-meta.xml`

**Version**: 1
**Status**: Active
**Last Modified**: 2025-10-14 08:36:55 by John Shintu

---

## Related Documentation

**Primary Source**: `/home/john/Projects/Salesforce/Documentation/PO_CONSUMPTION_EMAIL_NOTIFICATIONS.md`

**Complete System Guide**: 45,000+ words covering:
- Full requirements gathering
- Stakeholder responses
- Technical implementation details
- Testing procedures
- Configuration guide
- Troubleshooting

**No Related Deployments**: This is a standalone scenario, not consolidated with other documentation.

---

**Document Version**: 1.0
**Last Updated**: October 22, 2025
**Maintained By**: Migration Team
