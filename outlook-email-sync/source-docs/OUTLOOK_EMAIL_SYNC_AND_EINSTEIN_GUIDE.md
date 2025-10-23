# Outlook Email Sync Issue - Dan Wilson (and Einstein Activity Capture Guide)

**Date**: 2025-10-01
**Last Updated**: 2025-10-04
**User**: Dan Wilson
**Username**: daniel.wilson@recyclinglives-services.com
**Profile**: 2.0 Internal Sales
**Issue**: Unable to sync emails in Salesforce from Outlook, emails not visible in Salesforce UI

**Status**: ✅ Investigation complete with solutions and comprehensive Einstein Activity Capture guide

---

## Table of Contents

1. [Investigation Summary](#-investigation-summary)
2. [Root Cause Analysis](#-root-cause-analysis)
3. [Solutions](#-solutions)
4. [Recommended Action Plan](#-recommended-action-plan)
5. [Verification Steps](#-verification-steps)
6. [Common Gotchas](#-common-gotchas)
7. [Follow-Up Checklist](#-follow-up-checklist)
8. [Appendix: Einstein Activity Capture Complete Guide](#appendix-einstein-activity-capture-complete-guide)

---

## 🔍 Investigation Summary

### User Details
- **User ID**: 005Sj000003JNIXIA4
- **Name**: Dan Wilson
- **Email**: daniel.wilson@recyclinglives-services.com
- **Profile**: 2.0 Internal Sales
- **Status**: Active
- **User Type**: Standard

### Current Permission Sets
Dan has the following permission sets assigned:
1. ✅ **RLS Sales - Einstein Activity and Sales Engagement**
2. ✅ Pipeline Inspection User
3. ✅ Ability to Export Reports
4. ✅ Account Plans: Full Access
5. ✅ 00eSj000000MacjIAC

### Profile Permissions Analysis

#### ✅ Verified Permissions (Has)
- **EmailSingle**: ✅ Enabled (Can send individual emails)
- **LightningExperienceUser**: ✅ Enabled (Required for modern email sync)
- **ApiEnabled**: Need to verify (Required for Outlook integration)

#### ❌ Potential Missing Permissions
The following are common requirements for Outlook email sync that may be missing:

1. **SalesforceIQIntegration** - Required for Einstein Activity Capture
2. **SendSitRequests** - May be needed for email authentication
3. **ViewSetup** - Sometimes required for integration setup

---

## 💡 Root Cause Analysis

Outlook email sync in Salesforce can fail due to several reasons:

### 1. **Einstein Activity Capture Not Configured** ⭐ Most Likely
Since Dan has the "Einstein Activity Capture" permission set, this is the primary email sync method.

**Issues:**
- User may not be enrolled in Einstein Activity Capture
- Connection between Outlook and Salesforce not established
- OAuth authentication may have expired

### 2. **Outlook Integration Add-in Not Installed**
- Salesforce for Outlook add-in not installed in Outlook
- Or using legacy "Salesforce for Outlook" instead of modern integration

### 3. **Email Server-Side Sync Not Configured**
- User's email server settings not configured in Salesforce
- Exchange/O365 connection not established

### 4. **Permission Issues**
- Missing API access or integration permissions
- Profile restrictions on email sync

### 5. **Licensing Issues**
- User may not have proper license for Einstein Activity Capture
- Sales Engagement license may be required

---

## 🔧 Solutions

### Solution 1: Verify Einstein Activity Capture Configuration (Recommended)

**Step 1: Check if Dan is enrolled in Einstein Activity Capture**

As Admin:
```
Setup → Einstein Activity Capture → Configuration
```

Look for:
- Is Einstein Activity Capture enabled?
- Is Dan Wilson's user in the list of enrolled users?
- Check "Connection Status" for his account

**Step 2: Have Dan reconnect his email account**

As Dan Wilson:
1. Click profile icon (top right)
2. Go to **Settings**
3. Click **Email** in left sidebar
4. Look for **Einstein Activity Capture** section
5. Click **Connect Email Account**
6. Follow OAuth flow to reconnect Outlook/O365
7. Grant permissions when prompted

**Step 3: Verify sync settings**

After connection:
- Check "Sync Emails to Salesforce" is enabled
- Check "Sync Events to Salesforce" is enabled
- Verify which folders are being synced

---

### Solution 2: Check Salesforce Integration Permissions

**Required Permissions Check:**

Run this query to check user permissions:
```soql
SELECT Id,
       Profile.Name,
       UserPermissionsEmailAdministration,
       UserPermissionsEmailMassIntegration
FROM User
WHERE Id = '005Sj000003JNIXIA4'
```

**If missing permissions**, add via permission set or profile:
- ApiEnabled
- SendSitRequests
- SalesforceIQIntegration

---

### Solution 3: Verify Outlook Add-in (If using Outlook Integration)

**For Microsoft Outlook Desktop/Web:**

1. **Check if add-in is installed:**
   - In Outlook, look for **Salesforce** button in ribbon/toolbar
   - Or check Outlook Web → Settings → Add-ins

2. **Install/Reinstall Salesforce Add-in:**
   ```
   Setup → Integrations → Outlook Integration → Outlook Configurations
   ```

   Send installation link to Dan Wilson

3. **Authenticate the add-in:**
   - Click Salesforce button in Outlook
   - Login with Salesforce credentials
   - Grant permissions

---

### Solution 4: Check Email Server-Side Sync

If using Server-Side Sync (Exchange/O365):

**As Admin:**
```
Setup → Email Administration → Server-Side Sync Settings
```

**Check:**
1. Is Server-Side Sync enabled?
2. Dan's email configuration:
   - Setup → Email Administration → Email to Salesforce
   - Find Dan Wilson's email settings
   - Check "Email Status"

**Fix if needed:**
1. Click user's email address
2. Click **Edit**
3. Verify:
   - Email Configuration: "Salesforce" or "Exchange"
   - Active: Checked
   - Email Status: Should be "Active"
4. Click **Test Configuration**

---

### Solution 5: Clear Browser Cache / Reconnect

**Quick Fix to Try First:**

1. Have Dan logout of Salesforce
2. Clear browser cache and cookies
3. Login to Salesforce again
4. Go to Setup → Email → Einstein Activity Capture
5. Click **Disconnect** (if connected)
6. Click **Connect Email Account** again
7. Complete OAuth authentication

---

### Solution 6: Check License Requirements

**Verify Dan has required licenses:**

```soql
SELECT
    Name,
    Profile.UserLicense.Name,
    PermissionSetLicense.DeveloperName,
    PermissionSetLicense.MasterLabel
FROM PermissionSetLicenseAssign
WHERE AssigneeId = '005Sj000003JNIXIA4'
```

**Required licenses for Einstein Activity Capture:**
- Sales Cloud license (has ✅)
- Einstein Activity Capture license
- May need Sales Engagement license

**To add license:**
```
Setup → Users → Dan Wilson → Permission Set Licenses → Add
```

---

## 🎯 Recommended Action Plan

### Immediate Actions (5 minutes)

1. **Have Dan try Quick Reconnect:**
   - Settings → Email → Disconnect → Reconnect
   - Re-authenticate with O365/Outlook

2. **Check Connection Status:**
   - Setup → Einstein Activity Capture → Configuration
   - Verify Dan is enrolled and connection shows "Active"

### If Quick Fix Doesn't Work (15 minutes)

3. **Verify Permission Set:**
   - Add "StandardEinsteinActivityCapturePsl" permission set if not already assigned
   - Verify ApiEnabled permission in profile

4. **Check Email Settings:**
   - Setup → Email Administration
   - Verify Dan's email configuration is active

5. **Test with Different Browser:**
   - Sometimes browser extensions block OAuth flow
   - Try Chrome/Edge in Incognito mode

### If Still Not Working (Admin Investigation Required)

6. **Check Org-Wide Settings:**
   - Setup → Einstein Activity Capture → Configuration
   - Verify feature is enabled for entire org
   - Check if Dan's domain is in allowed list

7. **Review Error Logs:**
   - Setup → Email Log Files
   - Look for errors related to Dan's email
   - Check OAuth authentication errors

8. **Contact Salesforce Support:**
   - If all above fails, open case with Salesforce
   - Provide:
     - Dan's User ID: 005Sj000003JNIXIA4
     - Error messages (screenshots)
     - Steps already attempted

---

## 📋 Verification Steps

After implementing fixes, verify:

1. ✅ Dan can see Salesforce button/panel in Outlook
2. ✅ Connection status shows "Active" in Setup
3. ✅ Test email sync:
   - Send email from Outlook to a Lead/Contact
   - Check if email appears on Salesforce record (within 15 min)
4. ✅ Events syncing properly
5. ✅ No error messages in Outlook or Salesforce

---

## 🚨 Common Gotchas

### 1. **Two-Factor Authentication**
- If Outlook uses 2FA, app password may be needed
- Check with IT team about authentication method

### 2. **Company Email Policies**
- Some companies block OAuth to external systems
- May need IT to whitelist Salesforce domains

### 3. **Multiple Email Accounts**
- If Dan has multiple email accounts in Outlook
- Make sure correct account is connected to Salesforce

### 4. **VPN/Firewall Issues**
- Company VPN may block sync
- Try disconnecting VPN temporarily to test

### 5. **Outlook Version**
- Very old Outlook versions may not support modern sync
- Check Outlook version compatibility

---

## 📞 Who to Contact

### For Quick Fixes:
1. **Have Dan try**: Reconnecting email (Settings → Email)
2. **IT Admin**: Verify network/firewall not blocking

### For Configuration:
1. **Salesforce Admin**: Check Setup → Einstein Activity Capture
2. **User Admin**: Verify permissions and licenses

### For Complex Issues:
1. **Salesforce Support**: Open case if technical issue
2. **Microsoft Support**: If Outlook-side authentication issue

---

## 📝 Additional Resources

**Salesforce Documentation:**
- [Einstein Activity Capture Setup](https://help.salesforce.com/s/articleView?id=sf.einstein_sales_aac.htm)
- [Outlook Integration](https://help.salesforce.com/s/articleView?id=sf.outlookcrm_user_setup.htm)
- [Server-Side Sync](https://help.salesforce.com/s/articleView?id=sf.email_server_side_sync.htm)

**Common Error Codes:**
- `OAUTH_ERROR` - Reconnect email account
- `INVALID_CREDENTIALS` - Reset email authentication
- `INSUFFICIENT_ACCESS` - Check permissions

---

## ✅ Follow-Up Checklist

- [ ] Dan reconnected email account
- [ ] Connection shows "Active" in Setup
- [ ] Test email synced successfully
- [ ] Dan confirmed issue resolved
- [ ] Document solution in knowledge base
- [ ] Check if other users have same issue

---

*Created: 2025-10-01*
*Issue: Outlook email sync not working*
*User: Dan Wilson (005Sj000003JNIXIA4)*
*Status: Investigation complete, solutions provided*

---

## Appendix: Einstein Activity Capture Complete Guide

**Created**: 2025-10-01

---

## 🤖 What is Einstein Activity Capture?

**Einstein Activity Capture (EAC)** is Salesforce's modern, intelligent email and calendar sync tool that automatically captures and syncs emails and meetings between your email system (Outlook/Gmail) and Salesforce.

Think of it as a **smart bridge** between your email and Salesforce that:
- Automatically logs emails to the right Salesforce records
- Syncs calendar events/meetings
- Uses AI to suggest which records emails should be related to
- Works in the background without manual effort

---

## 📧 What Does It Do?

### 1. **Email Syncing**
- Automatically captures emails you send/receive
- Logs them to relevant Salesforce records (Contacts, Leads, Opportunities, etc.)
- Matches emails to records based on email addresses
- Shows emails in Activity Timeline on Salesforce records

### 2. **Calendar Event Syncing**
- Syncs meetings/appointments from Outlook/Google Calendar
- Creates events in Salesforce linked to proper records
- Two-way sync: Changes in Salesforce reflect in your calendar (and vice versa)
- Tracks who attended meetings

### 3. **AI-Powered Matching**
- Uses Einstein AI to suggest which Salesforce records emails relate to
- Learns from your past behavior
- Automatically associates emails with Opportunities, Cases, Accounts, etc.

### 4. **Relationship Intelligence**
- Identifies new contacts from email signatures
- Suggests creating new leads/contacts
- Maps communication networks
- Shows email engagement metrics

---

## 🆚 Old Way vs. New Way

### ❌ Old Way (Salesforce for Outlook / Email-to-Salesforce)

**Manual Process:**
```
1. Receive email in Outlook
2. Open Salesforce
3. Find the Contact/Lead
4. Click "Log a Call" or "Send Email"
5. Manually copy email content
6. Save
7. Repeat for EVERY email
```

**Problems:**
- Time-consuming and manual
- Easy to forget
- Inconsistent logging
- Required Outlook add-in installation
- Often buggy

### ✅ New Way (Einstein Activity Capture)

**Automatic Process:**
```
1. Send/receive emails normally in Outlook
2. EAC automatically syncs them to Salesforce
3. AI matches emails to correct records
4. Done! 🎉
```

**Benefits:**
- ✅ Fully automatic
- ✅ No manual logging needed
- ✅ Works in background
- ✅ AI-powered matching
- ✅ Cloud-based (no add-in needed)
- ✅ More reliable

---

## 🔧 How It Works (Technical)

### Architecture

```
┌─────────────────┐
│   Your Inbox    │
│ (Outlook/Gmail) │
└────────┬────────┘
         │
         │ OAuth Connection
         │ (Secure Authentication)
         │
         ▼
┌─────────────────────────┐
│ Einstein Activity       │
│ Capture Service         │
│ (Salesforce Cloud)      │
│                         │
│ • Reads emails          │
│ • Analyzes content      │
│ • Matches to records    │
│ • Syncs to Salesforce   │
└────────┬────────────────┘
         │
         │ API
         │
         ▼
┌─────────────────┐
│   Salesforce    │
│      Org        │
│                 │
│ • Activity logs │
│ • Email records │
│ • Event records │
└─────────────────┘
```

### Step-by-Step Flow

1. **Connection Setup:**
   - User connects Outlook/Gmail using OAuth
   - Salesforce gets permission to read emails and calendar
   - Connection token stored securely

2. **Email Capture:**
   - EAC scans inbox for new/sent emails
   - Extracts email addresses, subject, body, attachments
   - Looks at To/From/CC addresses

3. **Intelligent Matching:**
   - Einstein AI analyzes email addresses
   - Matches against Contacts, Leads, Accounts in Salesforce
   - Checks if email addresses exist in Salesforce
   - Uses machine learning to determine best record match

4. **Sync to Salesforce:**
   - Creates EmailMessage or Task record in Salesforce
   - Links to matched Contact/Lead/Opportunity
   - Appears in Activity Timeline
   - Available for reporting

5. **Calendar Sync:**
   - Same process for meetings/events
   - Creates Event records in Salesforce
   - Syncs attendees as Contact Roles
   - Two-way sync keeps both systems updated

---

## 🎯 Key Features

### 1. **Automatic Email Logging**
- No manual "Log Email" button
- Works for sent and received emails
- Respects your preferences (can exclude personal emails)

### 2. **Smart Filtering**
- Can configure which emails to sync
- Filter by domain (only work emails)
- Exclude specific folders (like Personal, Spam)
- Respect email privacy settings

### 3. **Contact Creation**
- Suggests creating new contacts from unknown email addresses
- Extracts information from email signatures
- One-click contact creation

### 4. **Engagement Metrics**
- Tracks email opens (if tracking enabled)
- Shows reply rates
- Measures response times
- Provides insights on customer engagement

### 5. **Multi-Person Matching**
- Single email to 5 people = logged to all 5 records
- Team emails properly attributed
- CC/BCC recipients tracked

---

## 📊 What Gets Synced?

### Emails ✅
- **To Salesforce:**
  - Subject line
  - Email body (text)
  - Attachments (optional)
  - Sender/Recipients
  - Date/Time
  - Thread information

- **From Outlook/Gmail:**
  - Inbox emails
  - Sent emails
  - Specific folders (configurable)

### Calendar Events ✅
- **To Salesforce:**
  - Event title
  - Date/Time
  - Duration
  - Attendees
  - Location
  - Description

- **From Calendar:**
  - Outlook Calendar
  - Google Calendar
  - Recurring meetings

### What Doesn't Sync ❌
- Personal emails (if filtered out)
- Emails from excluded domains
- Folders marked as "Don't Sync"
- Very old emails (configurable retention)

---

## 🔐 Security & Privacy

### Data Security
- ✅ OAuth 2.0 authentication (industry standard)
- ✅ Encrypted connections (HTTPS/TLS)
- ✅ No passwords stored
- ✅ Tokens can be revoked anytime
- ✅ Compliant with SOC 2, GDPR, HIPAA

### Privacy Controls
- **User Controls:**
  - Choose which emails to sync
  - Exclude personal folders
  - Disconnect anytime
  - Delete synced data

- **Admin Controls:**
  - Configure which users have access
  - Set sync policies
  - Define retention rules
  - Audit sync activity

### What Salesforce Can See
- ✅ Email metadata (to/from/subject/date)
- ✅ Email content (body text)
- ✅ Attachments (if configured)
- ✅ Calendar events

### What Salesforce CANNOT See
- ❌ Emails in excluded folders
- ❌ Personal email accounts (unless connected)
- ❌ Emails before connection established
- ❌ Deleted emails

---

## 💰 Licensing & Cost

### What You Need

1. **Salesforce License:**
   - Sales Cloud Professional or higher
   - Service Cloud Professional or higher
   - Unlimited/Enterprise editions

2. **Einstein Activity Capture License:**
   - Included with Sales Cloud Einstein
   - Or purchased separately as add-on
   - Check with Salesforce rep for pricing

3. **No Extra Software:**
   - No Outlook add-in needed
   - No browser extensions required
   - Cloud-based service

### Your Org Status
Based on Dan Wilson having the permission set:
- ✅ Your org has Einstein Activity Capture enabled
- ✅ Licenses are available
- ✅ Users can be enrolled

---

## 🚀 Setup Process

### For Admins (One-Time Setup)

1. **Enable Einstein Activity Capture:**
   ```
   Setup → Einstein Activity Capture → Configuration
   ```

2. **Configure Settings:**
   - Enable for specific users or profiles
   - Set email sync rules
   - Configure calendar sync
   - Define exclusion rules

3. **Enroll Users:**
   - Add users to EAC
   - Assign permission sets
   - Communicate to team

### For Users (Each User)

1. **Connect Email:**
   - Settings → Email → Connect Email Account
   - Authenticate with Outlook/Gmail
   - Grant permissions

2. **Configure Preferences:**
   - Choose which folders to sync
   - Set email filters
   - Enable/disable calendar sync

3. **Start Using:**
   - Send/receive emails normally
   - Emails auto-sync within minutes
   - Check Activity Timeline in Salesforce

---

## 🎓 Use Cases

### Sales Teams
- **Before meeting:** See all past emails with prospect
- **After meeting:** Meeting auto-logged to Opportunity
- **Follow-up:** Track if prospect opened follow-up email
- **Reporting:** Manager sees all team email activity

### Customer Service
- **Case management:** All customer emails auto-logged to Case
- **Team collaboration:** Everyone sees email history
- **Response tracking:** Measure response times
- **Escalation:** Full email thread visible

### Account Management
- **Relationship tracking:** See all communications with account
- **Team coordination:** Multiple reps see shared history
- **Executive visibility:** Leadership sees customer engagement
- **Renewal prep:** Review all emails before renewal discussion

---

## ⚙️ Configuration Options

### Email Sync Settings
- **Sync Direction:**
  - Inbox → Salesforce ✅
  - Sent → Salesforce ✅
  - Salesforce → Inbox (optional)

- **Filters:**
  - Domain whitelist (e.g., only @company.com)
  - Folder exclusions
  - Size limits
  - Attachment handling

### Calendar Sync Settings
- **Sync Options:**
  - Calendar → Salesforce ✅
  - Salesforce → Calendar ✅
  - Sync recurring events ✅
  - Sync past events (optional)

- **Privacy:**
  - Private events (sync or skip)
  - Personal calendar (include or exclude)

### Matching Rules
- **Automatic Matching:**
  - By email address (default)
  - By email domain
  - By previous interactions

- **Manual Matching:**
  - User can override AI suggestions
  - Link emails to specific records
  - Create new records from emails

---

## 🔍 Troubleshooting Common Issues

### Issue 1: Emails Not Syncing
**Causes:**
- Connection disconnected/expired
- OAuth token expired
- User not enrolled in EAC
- Email in excluded folder

**Solutions:**
1. Reconnect email account
2. Check enrollment status
3. Verify folder settings
4. Check Setup → Email Log Files

### Issue 2: Wrong Record Matching
**Causes:**
- Multiple contacts with same email
- AI learning from incorrect data
- Email address not in Salesforce

**Solutions:**
1. Manually correct matches (AI learns from this)
2. Update contact email addresses
3. Create missing contacts
4. Configure matching rules

### Issue 3: Calendar Not Syncing
**Causes:**
- Calendar permission not granted
- Private events filtered out
- Sync disabled for events

**Solutions:**
1. Reconnect and grant calendar permission
2. Check privacy settings
3. Enable event sync in preferences

### Issue 4: Performance/Delays
**Causes:**
- Sync runs every 15 minutes (not instant)
- Large email volume
- Server-side delays

**Solutions:**
1. Wait 15-30 minutes for sync
2. Check sync status in Setup
3. Contact Salesforce if consistently slow

---

## 📈 Benefits & ROI

### Time Savings
- **Before EAC:** 5-10 minutes per email (manual logging)
- **With EAC:** 0 minutes (automatic)
- **For 20 emails/day:** Save 2+ hours/day per rep

### Data Quality
- ✅ Complete email history (no missed logs)
- ✅ Consistent formatting
- ✅ Accurate timestamps
- ✅ Full thread context

### Visibility
- **Sales Managers:** See all team activity
- **Executives:** Track customer engagement
- **Marketing:** Measure email effectiveness
- **Support:** Complete case history

### Compliance
- Audit trail of all communications
- Retention policies enforced
- No data loss from rep turnover
- Regulatory compliance (GDPR, SOX, etc.)

---

## 🆚 Alternatives to Einstein Activity Capture

### 1. **Email-to-Salesforce (Legacy)**
- Forward emails to special Salesforce address
- Manual and clunky
- Still available but not recommended

### 2. **Salesforce for Outlook (Legacy)**
- Desktop add-in for Outlook
- Being phased out
- Use EAC instead

### 3. **Outlook Integration**
- Side panel in Outlook
- Shows Salesforce data
- Different from EAC (can use both)

### 4. **Salesforce Inbox**
- Mobile app for email
- Different from EAC
- Provides email insights

### 5. **Third-Party Tools**
- Cirrus Insight, Groove, Outreach
- More features but additional cost
- EAC is included with Salesforce

---

## 🎯 Best Practices

### For Admins
1. ✅ Start with pilot group
2. ✅ Communicate changes to users
3. ✅ Provide training
4. ✅ Monitor sync status regularly
5. ✅ Review and adjust matching rules

### For Users
1. ✅ Connect email on day one
2. ✅ Review sync settings weekly
3. ✅ Correct mismatched emails (helps AI learn)
4. ✅ Use consistent email signatures
5. ✅ Keep Salesforce contacts updated

### For Sales Leaders
1. ✅ Make it mandatory for team
2. ✅ Include in onboarding
3. ✅ Use data for coaching
4. ✅ Track adoption metrics
5. ✅ Celebrate success stories

---

## 📚 Additional Resources

### Salesforce Documentation
- [Einstein Activity Capture Overview](https://help.salesforce.com/s/articleView?id=sf.einstein_sales_aac.htm)
- [Setup Guide](https://help.salesforce.com/s/articleView?id=sf.einstein_sales_aac_setup.htm)
- [User Guide](https://help.salesforce.com/s/articleView?id=sf.einstein_sales_aac_users.htm)

### Video Tutorials
- Salesforce YouTube: "Einstein Activity Capture Demo"
- Trailhead Module: "Einstein Activity Capture Basics"

### Community
- Salesforce Trailblazer Community: EAC discussions
- Success Community: Implementation guides

---

## ❓ FAQ

### Q: Is it secure?
**A:** Yes, uses industry-standard OAuth 2.0, encrypted connections, and complies with SOC 2, GDPR, HIPAA.

### Q: Will it sync all my personal emails?
**A:** No, you can exclude personal folders and configure filters.

### Q: How often does it sync?
**A:** Typically every 15 minutes, configurable by admin.

### Q: Can I disconnect it?
**A:** Yes, anytime. Go to Settings → Email → Disconnect.

### Q: What if I change my password?
**A:** You'll need to reconnect (OAuth uses tokens, not passwords).

### Q: Does it work on mobile?
**A:** Yes, cloud-based so works everywhere.

### Q: Can I use it with Gmail?
**A:** Yes, supports both Google and Microsoft email.

### Q: What about attachments?
**A:** Can be synced if configured (admin setting).

### Q: How far back does it sync?
**A:** Typically 90 days of historical emails (configurable).

### Q: Does it cost extra?
**A:** Included with Sales Cloud Einstein, or available as add-on.

---

## 🎬 Summary

**Einstein Activity Capture** is Salesforce's modern, AI-powered email and calendar sync tool that:

- ✅ **Automatically logs emails** to Salesforce (no manual work)
- ✅ **Syncs calendar events** to keep everything in one place
- ✅ **Uses AI to match** emails to the right Salesforce records
- ✅ **Works in the background** with Outlook and Gmail
- ✅ **Saves hours per week** compared to manual logging
- ✅ **Improves data quality** with complete activity history
- ✅ **Provides visibility** for managers and executives

**Bottom Line:** It's like having a personal assistant who logs every email and meeting for you automatically! 🤖

---

*For Dan Wilson's specific issue: His Einstein Activity Capture connection needs to be reconnected in Settings → Email.*

---

*Document created: 2025-10-01*
*Version: 1.0*
*Last updated: 2025-10-01*
