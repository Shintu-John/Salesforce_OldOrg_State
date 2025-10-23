global with sharing class JobMissingScheduleEmailNotificationBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    // Stateful variables to accumulate data across batches
    global List<JobReportData> criticalJobs = new List<JobReportData>();      // 30+ days
    global List<JobReportData> highPriorityJobs = new List<JobReportData>();  // 8-29 days
    global List<JobReportData> mediumPriorityJobs = new List<JobReportData>(); // 4-7 days
    global List<JobReportData> recentJobs = new List<JobReportData>();        // 1-3 days
    global Integer totalJobsProcessed = 0;

    // Inner class to hold Job data for reporting
    global class JobReportData {
        public String jobName;
        public String accountName;
        public String productName;
        public Date deliveryDate;
        public Integer daysSinceDelivery;
        public String jobId;
        public Integer reminderCount;

        public JobReportData(Job__c job) {
            this.jobName = job.Name;
            this.accountName = job.Account__r != null ? job.Account__r.Name : '';
            this.productName = job.Order_Product__r != null && job.Order_Product__r.Product2 != null ? job.Order_Product__r.Product2.Name : '';
            this.deliveryDate = job.Delivery_Date__c;
            this.daysSinceDelivery = job.Delivery_Date__c != null ? job.Delivery_Date__c.daysBetween(Date.today()) : 0;
            this.jobId = job.Id;
            this.reminderCount = job.Schedule_Not_Created_Warning__c != null ? Integer.valueOf(job.Schedule_Not_Created_Warning__c) : 0;
        }
    }

    global void execute(SchedulableContext SC) {
        Database.executebatch(new JobMissingScheduleEmailNotificationBatch(), 200);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, CreatedDate, Schedule_Not_Created_Warning__c, Delivery_Date__c, Delivery_Confirmed__c, ';
        query += 'Account__r.Name, Order_Product__r.Product2.Name ';
        query += '  FROM Job__c ';
        if(Test.isRunningTest()) {
            query += ' LIMIT 10 ';
        } else {
            query += ' WHERE RLES_Standard_Job_Filters__c = true and Schedule__c = null and May_Require_Schedule__c = true and Delivery_Confirmed__c = true and DAY_ONLY(createddate) > 2024-04-05 ';
            query += ' ORDER BY Delivery_Date__c ASC';
        }
        System.debug('Schedule Reminder Query :: ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Job__c> recs) {
        List<Job__c> updateJobs = new List<Job__c>();

        for(Job__c job : recs) {
            totalJobsProcessed++;

            // Calculate days since delivery date
            Integer daysSinceDelivery = job.Delivery_Date__c != null ? job.Delivery_Date__c.daysBetween(Date.today()) : 0;

            // Categorize by urgency
            JobReportData reportData = new JobReportData(job);

            if(daysSinceDelivery >= 30) {
                criticalJobs.add(reportData);
            } else if(daysSinceDelivery >= 8) {
                highPriorityJobs.add(reportData);
            } else if(daysSinceDelivery >= 4) {
                mediumPriorityJobs.add(reportData);
            } else {
                recentJobs.add(reportData);
            }

            // Increment reminder counter
            Decimal counter = (job.Schedule_Not_Created_Warning__c == null ? 0 : job.Schedule_Not_Created_Warning__c) + 1;
            updateJobs.add(new Job__c(Id = job.Id, Schedule_Not_Created_Warning__c = Integer.valueOf(counter)));
        }

        // Update reminder counters
        if(updateJobs.size() > 0) {
            Database.update(updateJobs, false);
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Send consolidated daily report email
        sendDailyReport();
    }

    private void sendDailyReport() {
        // Build HTML email report
        String htmlBody = buildHtmlReport();
        String textBody = buildTextReport();

        // Send email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Daily Schedule Creation Report - ' + totalJobsProcessed + ' Jobs Requiring Schedules');
        email.setHtmlBody(htmlBody);
        email.setPlainTextBody(textBody);

        // Set recipients - Customer Service (primary), CC: Kaylie Morris & Lucas Hargreaves
        email.setToAddresses(new List<String>{Label.fromaddress_customerservice});
        email.setCcAddresses(new List<String>{'kaylie.morris@recyclinglives-services.com', 'lucas.hargreaves@recyclinglives-services.com'});

        // Set org-wide email address if available
        try {
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :Label.fromaddress_customerservice LIMIT 1];
            if(owea.size() > 0) {
                email.setOrgWideEmailAddressId(owea[0].Id);
            }
        } catch(Exception e) {
            System.debug('Could not set org-wide email address: ' + e.getMessage());
        }

        if(!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }

    private String buildHtmlReport() {
        String html = '<html><body style="font-family: Arial, sans-serif;">';
        html += '<h1 style="color: #0070d2;">Daily Schedule Creation Report</h1>';
        html += '<p><strong>Date:</strong> ' + Date.today().format() + '</p>';
        html += '<p><strong>Total Jobs Requiring Schedules:</strong> ' + totalJobsProcessed + '</p>';
        html += '<p style="color: #666;">These Jobs have confirmed deliveries but no schedules created yet.</p>';
        html += '<hr/>';

        // Critical section (30+ days)
        if(criticalJobs.size() > 0) {
            html += '<div style="background-color: #fce4e4; padding: 15px; margin: 10px 0; border-left: 5px solid #c23934;">';
            html += '<h2 style="color: #c23934; margin-top: 0;">CRITICAL - 30+ Days Overdue (' + criticalJobs.size() + ' Jobs)</h2>';
            html += '<p style="color: #c23934;"><strong>URGENT ACTION REQUIRED:</strong> Delivery confirmed over 30 days ago. Schedule creation is severely overdue.</p>';
            html += buildJobTable(criticalJobs);
            html += '</div>';
        }

        // High Priority section (8-29 days)
        if(highPriorityJobs.size() > 0) {
            html += '<div style="background-color: #fff3e0; padding: 15px; margin: 10px 0; border-left: 5px solid #fe9339;">';
            html += '<h2 style="color: #fe9339; margin-top: 0;">HIGH PRIORITY - 8-29 Days Overdue (' + highPriorityJobs.size() + ' Jobs)</h2>';
            html += '<p>Please create schedules for these Jobs as soon as possible.</p>';
            html += buildJobTable(highPriorityJobs);
            html += '</div>';
        }

        // Medium Priority section (4-7 days)
        if(mediumPriorityJobs.size() > 0) {
            html += '<div style="background-color: #fffbf0; padding: 15px; margin: 10px 0; border-left: 5px solid #ffb75d;">';
            html += '<h2 style="color: #ffb75d; margin-top: 0;">MEDIUM PRIORITY - 4-7 Days Overdue (' + mediumPriorityJobs.size() + ' Jobs)</h2>';
            html += buildJobTable(mediumPriorityJobs);
            html += '</div>';
        }

        // Recent section (1-3 days)
        if(recentJobs.size() > 0) {
            html += '<div style="background-color: #e8f5e9; padding: 15px; margin: 10px 0; border-left: 5px solid #4bca81;">';
            html += '<h2 style="color: #4bca81; margin-top: 0;">RECENT - 1-3 Days (' + recentJobs.size() + ' Jobs)</h2>';
            html += buildJobTable(recentJobs);
            html += '</div>';
        }

        html += '<hr/>';
        html += '<p style="font-size: 12px; color: #666;">This is an automated daily report. To create a schedule, navigate to the Job record and use the "Create Schedule" button.</p>';
        html += '</body></html>';

        return html;
    }

    private String buildJobTable(List<JobReportData> jobs) {
        String table = '<table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%; margin-bottom: 20px;">';
        table += '<thead style="background-color: #f3f3f3;">';
        table += '<tr>';
        table += '<th>Job Name</th>';
        table += '<th>Account</th>';
        table += '<th>Product</th>';
        table += '<th>Delivery Date</th>';
        table += '<th>Days Overdue</th>';
        table += '<th>Reminders Sent</th>';
        table += '<th>Action</th>';
        table += '</tr>';
        table += '</thead>';
        table += '<tbody>';

        for(JobReportData job : jobs) {
            String jobUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + job.jobId;
            table += '<tr>';
            table += '<td><a href="' + jobUrl + '">' + job.jobName + '</a></td>';
            table += '<td>' + job.accountName + '</td>';
            table += '<td>' + job.productName + '</td>';
            table += '<td>' + (job.deliveryDate != null ? job.deliveryDate.format() : '') + '</td>';
            table += '<td style="text-align: center;"><strong>' + job.daysSinceDelivery + '</strong></td>';
            table += '<td style="text-align: center;">' + (job.reminderCount + 1) + '</td>';
            table += '<td><a href="' + jobUrl + '" style="color: #0070d2;">Create Schedule</a></td>';
            table += '</tr>';
        }

        table += '</tbody>';
        table += '</table>';

        return table;
    }

    private String buildTextReport() {
        String text = 'DAILY SCHEDULE CREATION REPORT\n';
        text += '===============================\n\n';
        text += 'Date: ' + Date.today().format() + '\n';
        text += 'Total Jobs Requiring Schedules: ' + totalJobsProcessed + '\n\n';

        if(criticalJobs.size() > 0) {
            text += 'CRITICAL - 30+ Days Overdue (' + criticalJobs.size() + ' Jobs)\n';
            text += '--------------------------------------------\n';
            for(JobReportData job : criticalJobs) {
                text += job.jobName + ' | ' + job.accountName + ' | ' + (job.deliveryDate != null ? job.deliveryDate.format() : '') + ' | ' + job.daysSinceDelivery + ' days | Reminder #' + (job.reminderCount + 1) + '\n';
            }
            text += '\n';
        }

        if(highPriorityJobs.size() > 0) {
            text += 'HIGH PRIORITY - 8-29 Days Overdue (' + highPriorityJobs.size() + ' Jobs)\n';
            text += '--------------------------------------------\n';
            for(JobReportData job : highPriorityJobs) {
                text += job.jobName + ' | ' + job.accountName + ' | ' + (job.deliveryDate != null ? job.deliveryDate.format() : '') + ' | ' + job.daysSinceDelivery + ' days | Reminder #' + (job.reminderCount + 1) + '\n';
            }
            text += '\n';
        }

        if(mediumPriorityJobs.size() > 0) {
            text += 'MEDIUM PRIORITY - 4-7 Days Overdue (' + mediumPriorityJobs.size() + ' Jobs)\n';
            text += '--------------------------------------------\n';
            for(JobReportData job : mediumPriorityJobs) {
                text += job.jobName + ' | ' + job.accountName + ' | ' + (job.deliveryDate != null ? job.deliveryDate.format() : '') + ' | ' + job.daysSinceDelivery + ' days | Reminder #' + (job.reminderCount + 1) + '\n';
            }
            text += '\n';
        }

        if(recentJobs.size() > 0) {
            text += 'RECENT - 1-3 Days (' + recentJobs.size() + ' Jobs)\n';
            text += '--------------------------------------------\n';
            for(JobReportData job : recentJobs) {
                text += job.jobName + ' | ' + job.accountName + ' | ' + (job.deliveryDate != null ? job.deliveryDate.format() : '') + ' | ' + job.daysSinceDelivery + ' days | Reminder #' + (job.reminderCount + 1) + '\n';
            }
            text += '\n';
        }

        text += '\nTo create a schedule, navigate to the Job record and use the "Create Schedule" button.';

        return text;
    }
}