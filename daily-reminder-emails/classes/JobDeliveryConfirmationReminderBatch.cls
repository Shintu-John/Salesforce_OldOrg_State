global with sharing class JobDeliveryConfirmationReminderBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

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

        public JobReportData(Job__c job) {
            this.jobName = job.Name;
            this.accountName = job.Account__r.Name;
            this.productName = job.Order_Product__r.Product2.Name;
            this.deliveryDate = job.Delivery_Date__c;
            this.daysSinceDelivery = job.Delivery_Date__c.daysBetween(Date.today());
            this.jobId = job.Id;
        }
    }

    global void execute(SchedulableContext SC) {
        Database.executebatch(new JobDeliveryConfirmationReminderBatch(), 200);
    }

    global Database.QueryLocator start( Database.BatchableContext bc ){
        String query = 'SELECT Id, Name, CreatedDate, Delivery_Date__c, Delivery_Confirmed__c, ';
        query += 'Account__r.Name, Order_Product__r.Product2.Name ';
        query += '  FROM Job__c ';
        if(Test.isRunningTest()) {
            query += ' LIMIT 10 ';
        } else {
            query += ' WHERE RLES_Standard_Job_Filters__c = true and Schedule__c = null and May_Require_Schedule__c = true and Delivery_Date__c != null and Delivery_Date__c < TODAY and Delivery_Confirmed__c = false and DAY_ONLY(createddate) > 2024-04-05 ';
            query += ' ORDER BY Delivery_Date__c ASC';
        }
        System.debug(' Delivery Confirmation Query :: '+query);
        return Database.getQueryLocator(query);
    }

    global void execute( Database.BatchableContext bc, List<Job__c> recs ){
        for(Job__c job :recs){
            totalJobsProcessed++;

            // Calculate days since delivery date
            Integer daysSinceDelivery = job.Delivery_Date__c.daysBetween(Date.today());

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
        }
    }

    global void finish( Database.BatchableContext bc ){
        // Send consolidated daily report email
        sendDailyReport();
    }

    private void sendDailyReport() {
        // Build HTML email report
        String htmlBody = buildHtmlReport();
        String textBody = buildTextReport();

        // Send email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Daily Delivery Confirmation Report - ' + totalJobsProcessed + ' Jobs Requiring Attention');
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
        html += '<h1 style="color: #0070d2;">Daily Delivery Confirmation Report</h1>';
        html += '<p><strong>Date:</strong> ' + Date.today().format() + '</p>';
        html += '<p><strong>Total Jobs Requiring Delivery Confirmation:</strong> ' + totalJobsProcessed + '</p>';
        html += '<hr/>';

        // Critical section (30+ days)
        if(criticalJobs.size() > 0) {
            html += '<div style="background-color: #fce4e4; padding: 15px; margin: 10px 0; border-left: 5px solid #c23934;">';
            html += '<h2 style="color: #c23934; margin-top: 0;">CRITICAL - 30+ Days Overdue (' + criticalJobs.size() + ' Jobs)</h2>';
            html += '<p style="color: #c23934;"><strong>ACTION REQUIRED:</strong> These deliveries are extremely overdue. Please prioritize confirmation.</p>';
            html += buildJobTable(criticalJobs);
            html += '</div>';
        }

        // High Priority section (8-29 days)
        if(highPriorityJobs.size() > 0) {
            html += '<div style="background-color: #fff3e0; padding: 15px; margin: 10px 0; border-left: 5px solid #fe9339;">';
            html += '<h2 style="color: #fe9339; margin-top: 0;">HIGH PRIORITY - 8-29 Days Overdue (' + highPriorityJobs.size() + ' Jobs)</h2>';
            html += '<p>Please confirm these deliveries as soon as possible.</p>';
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
        html += '<p style="font-size: 12px; color: #666;">This is an automated daily report. To confirm a delivery, update the "Delivery Confirmed" field on the Job record.</p>';
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
            table += '<td>' + job.deliveryDate.format() + '</td>';
            table += '<td style="text-align: center;"><strong>' + job.daysSinceDelivery + '</strong></td>';
            table += '<td><a href="' + jobUrl + '" style="color: #0070d2;">Confirm Delivery</a></td>';
            table += '</tr>';
        }

        table += '</tbody>';
        table += '</table>';

        return table;
    }

    private String buildTextReport() {
        String text = 'DAILY DELIVERY CONFIRMATION REPORT\n';
        text += '==================================\n\n';
        text += 'Date: ' + Date.today().format() + '\n';
        text += 'Total Jobs Requiring Delivery Confirmation: ' + totalJobsProcessed + '\n\n';

        if(criticalJobs.size() > 0) {
            text += 'CRITICAL - 30+ Days Overdue (' + criticalJobs.size() + ' Jobs)\n';
            text += '--------------------------------------------\n';
            for(JobReportData job : criticalJobs) {
                text += job.jobName + ' | ' + job.accountName + ' | ' + job.deliveryDate.format() + ' | ' + job.daysSinceDelivery + ' days\n';
            }
            text += '\n';
        }

        if(highPriorityJobs.size() > 0) {
            text += 'HIGH PRIORITY - 8-29 Days Overdue (' + highPriorityJobs.size() + ' Jobs)\n';
            text += '--------------------------------------------\n';
            for(JobReportData job : highPriorityJobs) {
                text += job.jobName + ' | ' + job.accountName + ' | ' + job.deliveryDate.format() + ' | ' + job.daysSinceDelivery + ' days\n';
            }
            text += '\n';
        }

        if(mediumPriorityJobs.size() > 0) {
            text += 'MEDIUM PRIORITY - 4-7 Days Overdue (' + mediumPriorityJobs.size() + ' Jobs)\n';
            text += '--------------------------------------------\n';
            for(JobReportData job : mediumPriorityJobs) {
                text += job.jobName + ' | ' + job.accountName + ' | ' + job.deliveryDate.format() + ' | ' + job.daysSinceDelivery + ' days\n';
            }
            text += '\n';
        }

        if(recentJobs.size() > 0) {
            text += 'RECENT - 1-3 Days (' + recentJobs.size() + ' Jobs)\n';
            text += '--------------------------------------------\n';
            for(JobReportData job : recentJobs) {
                text += job.jobName + ' | ' + job.accountName + ' | ' + job.deliveryDate.format() + ' | ' + job.daysSinceDelivery + ' days\n';
            }
            text += '\n';
        }

        text += '\nTo confirm a delivery, update the "Delivery Confirmed" field on the Job record.';

        return text;
    }
}