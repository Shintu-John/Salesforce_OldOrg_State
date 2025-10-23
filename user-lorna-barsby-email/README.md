# User Email Correction - Lorna Barsby

**Created**: October 23, 2025
**Scenario Type**: 📊 **Analysis** (User Account Fix)
**Organization**: OldOrg (Recycling Lives Service)
**Incident Date**: October 8, 2025
**Status**: ✅ Resolved

## Executive Summary

**Issue**: User account created with incorrect email address, stuck in verification loop.

**Incorrect Email**: lorna.barsby@recyclinglives-service.com (missing 's')
**Correct Email**: lorna.barsby@recyclinglives-services.com

**Resolution**: Deactivated incorrect user, created new user with correct email.

## The Problem

**Why Standard Update Failed**:
- User had never logged in (LastLoginDate = null)
- Email verification workflow active for new users
- Salesforce prevents email updates for users in verification state

**Why Deletion Failed**:
- Salesforce doesn't allow User record deletion via API/Apex
- Platform restriction

## Resolution

**Step 1**: Deactivated old user (ID: 005Sj000003ZLnpIAG)

**Step 2**: Created new user with correct details:
- User ID: 005Sj000003ZMdRIAW
- Name: Lorna Barsby ✅ (corrected spelling)
- Email: lorna.barsby@recyclinglives-services.com ✅
- Profile: 2.0 - RLCS
- Status: Active

## Lessons for NewOrg

**Prevention**:
- Double-check email addresses before creating users
- Test verification emails in sandbox first
- Keep list of valid email domains

**If Similar Issue Occurs**:
1. Cannot update email for unverified users
2. Cannot delete User records
3. Solution: Deactivate + Create new user

See: [NewOrg User Creation Guide](https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/user-lorna-barsby-email)

**Last Updated**: October 23, 2025
**Scenario Classification**: Analysis / User Account Fix
