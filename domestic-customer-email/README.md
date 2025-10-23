# Domestic Customer Email Issue - Person Account Fix

**Created**: October 23, 2025
**Scenario Type**: 📊 **Analysis** (Person Account Configuration Fix)
**Organization**: OldOrg (Recycling Lives Service)
**Incident Date**: October 9, 2025
**Status**: ✅ Resolved

## Executive Summary

**Issue**: Customer service staff unable to add email address to Domestic Customer account, blocking skip booking process.

**Root Cause**: Person Account page layout missing PersonEmail field.

**Resolution**: Added PersonEmail field to "Domestic Customer" page layout.

**Impact**: Fixed immediately; documented for NewOrg prevention.

## The Problem

**Account**: George Williams (Domestic Customer)
**Record Type**: Person Account
**Issue**: No edit option visible for email field on Account record

**Why Skip Booking Was Blocked**:
- Domestic Create Job flow requires email address
- Staff couldn't add email (field not on page layout)
- Order processing blocked

## Person Account Architecture

**Person Accounts** merge Account and Contact into single entity:
- Email stored in `PersonEmail` field (NOT standard Account.Email)
- Requires specific page layout configuration
- Different field access than Business Accounts

## Resolution

**Action**: Added PersonEmail field to page layout

**File Modified**: `force-app/main/default/layouts/Account-Domestic Customer Layout.layout-meta.xml`

**Field Added** (lines 250-253):
```xml
<layoutItems>
    <behavior>Edit</behavior>
    <field>PersonEmail</field>
</layoutItems>
```

**Result**: ✅ Email field now editable on Domestic Customer records

## Prevention for NewOrg

**Pre-Go-Live Checklist**:
- [ ] Verify PersonEmail field on Domestic Customer page layout
- [ ] Test email entry with Person Account records
- [ ] Ensure field is NOT read-only
- [ ] Train staff on Person Account vs Business Account differences

See: [NewOrg Prevention Guide](https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/domestic-customer-email)

**Last Updated**: October 23, 2025
**Scenario Classification**: Analysis / Page Layout Fix
