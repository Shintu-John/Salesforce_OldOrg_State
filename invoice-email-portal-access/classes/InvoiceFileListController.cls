/**
 * @description Given an invoice ID this returns a list of files related to jobs that the invoice covers
 */

public without sharing class InvoiceFileListController {
    public List<FileDetails> fileDetailsList {public get; private set;}
    public List<InvoiceFileDetails> invoiceFileDetailsList {public get; private set;}
    public Invoice__c invoice {public get; private set;}
    public Boolean isIdValid {public get; private set;}
    public Boolean displayMessage {public get; private set;}
    public List<String> contentDocumentIds {public get; private set;}
    public String contentVersionIds {public get; private set;}
    

    public InvoiceFileListController() {
        this.isIdValid = true;
        this.displayMessage = false;

        // Get the ID of the invoice
        String invoiceId = System.currentPageReference().getParameters().get('invoiceid');
        if(String.isBlank(invoiceId)){
            invoiceId = System.currentPageReference().getParameters().get('id');
        }

        // Check that the invoice ID is valid and does link to an invoice
        if(isValidId(invoiceId) == false) {
            this.isIdValid = false;
        } else {
            // Try and find the invoice
            List<Invoice__c> invoices = [SELECT Id, Name FROM Invoice__c WHERE Id=:invoiceId];
            if (invoices.size() == 0) {
                this.isIdValid = false;
            } else {
                this.invoice = invoices[0];
            }
        }

        // Display a message if the ID is invalid
        if (isIdValid == false) {
            this.displayMessage = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'The provided invoice ID is not valid'));
        } else {
            // Get all of the job charges that are linked to this invoice
            Map<Id, List<String>> jobChargeNamesByJobId = new Map<Id, List<String>>();
            Map<Id, Job__c> jobsById = new Map<Id, Job__c>();
            Map<Id, List<String>> jobWithChargeTypesMap = new Map<Id, List<String>>();
            for (Job_Charge__c jobCharge : [SELECT Id, Name, Charge_Type__c, Job__c, Job__r.Name, 
                                            Job__r.Consignment_Note_ContentDistribution_Id__c, Job__r.Parent_Job__r.Consignment_Note_ContentDistribution_Id__c,
                                            Job__r.DOC_ContentDistribution_Id__c, Job__r.Parent_Job__r.DOC_ContentDistribution_Id__c, 
                                            Job__r.Weighbridge_ContentDistribution_Id__c, Job__r.Parent_Job__r.Weighbridge_ContentDistribution_Id__c, 
                                            Job__r.WTN_ContentDistribution_Id__c, Job__r.Parent_Job__r.WTN_ContentDistribution_Id__c,
                                            Job__r.COD_ContentDistribution_Id__c, Job__r.Parent_Job__r.COD_ContentDistribution_Id__c,
                                            Job__r.Collection_Note_ContentDistribution_Id__c, Job__r.Parent_Job__r.Collection_Note_ContentDistribution_Id__c,
                                            Job__r.Delivery_Note_ContentDistribution_Id__c, Job__r.Parent_Job__r.Delivery_Note_ContentDistribution_Id__c
                                            FROM Job_Charge__c WHERE Invoice__c=:invoiceId]) {
                                                if (jobChargeNamesByJobId.containsKey(jobCharge.Job__c) == false) {jobChargeNamesByJobId.put(jobCharge.Job__c, new List<String>());}
                                                jobChargeNamesByJobId.get(jobCharge.Job__c).add(jobCharge.Name);
                                                
                                                // Add the job object
                                                jobsById.put(jobCharge.Job__c, (Job__c)jobCharge.getSObject('Job__r'));
                                                
                                                //collect charge types
                                                if(!jobWithChargeTypesMap.containsKey(jobCharge.Job__c)){
                                                    jobWithChargeTypesMap.put(jobCharge.Job__c, new List<String>());
                                                }
                                                jobWithChargeTypesMap.get(jobCharge.Job__c).add(jobCharge.Charge_Type__c);
            }

            // Get the IDs of all the related content distribution records
            Set<Id> contentDistributionIds = new Set<Id>();
            for (Job__c job : jobsById.values()) {
                if (job.Consignment_Note_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.Consignment_Note_ContentDistribution_Id__c);}
                if (job.DOC_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.DOC_ContentDistribution_Id__c);}
                if (job.Weighbridge_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.Weighbridge_ContentDistribution_Id__c);}
                if (job.WTN_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.WTN_ContentDistribution_Id__c);}
                if (job.COD_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.COD_ContentDistribution_Id__c);}
                if (job.Collection_Note_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.Collection_Note_ContentDistribution_Id__c);}
                if (job.Delivery_Note_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.Delivery_Note_ContentDistribution_Id__c);}
                
                if (job?.Parent_Job__r.WTN_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.Parent_Job__r.WTN_ContentDistribution_Id__c);}
                if (job?.Parent_Job__r.COD_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.Parent_Job__r.COD_ContentDistribution_Id__c);}
                if (job.Parent_Job__r?.Consignment_Note_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.Parent_Job__r.Consignment_Note_ContentDistribution_Id__c);}
                if (job.Parent_Job__r.Delivery_Note_ContentDistribution_Id__c != null) {contentDistributionIds.add(job.Parent_Job__r.Delivery_Note_ContentDistribution_Id__c);}
            }
            System.debug(contentDistributionIds);
            // Get all of the Content Distribution records
            Map<Id, ContentDistribution> contentDistributionsById = new Map<Id, ContentDistribution>([SELECT Id,ContentVersionId, ExpiryDate, Name, RelatedRecordId, DistributionPublicUrl,ContentDownloadUrl, ContentDocumentId FROM ContentDistribution WHERE Id IN:contentDistributionIds]);
            System.debug(contentDistributionsById);
            // Step through the jobs and for each one add details to the list
            // Build up the file details
            this.fileDetailsList = new List<FileDetails>();
            this.contentDocumentIds = new List<String>();
            for (Id jobId : jobsById.keySet()) {
                // Get the Job
                Job__c job = jobsById.get(jobId);
                
                //Invoice Charge Types
                List<String> chargeTypes = jobWithChargeTypesMap.get(jobId);

                // Get the job charge names
                List<String> jobChargeNames = jobChargeNamesByJobId.get(jobId);

                // Add the Consignment Note
                if(isContains(new List<String>{'Job', 'Rebate Transport'}, chargeTypes)){
                    String Consignment_Note_ContentDistribution_Id = job.Parent_Job__c != null ? job.Parent_Job__r.Consignment_Note_ContentDistribution_Id__c : job.Consignment_Note_ContentDistribution_Id__c;
                    
                    if(Consignment_Note_ContentDistribution_Id != null){
                        ContentDistribution conDist = contentDistributionsById.get(Consignment_Note_ContentDistribution_Id);
                        if (conDist != null) {
                            // Create the file details and add them to the list
                            this.fileDetailsList.add(new FileDetails(conDist.DistributionPublicUrl,conDist.ContentDownloadUrl, conDist.Name, job.Name, String.join(jobChargeNames,','),'Consignment Note'));
                            this.contentDocumentIds.add(conDist.ContentVersionId);
                        }
                    }
                }

                // Add the Annual DOC
                /*
                if (job.DOC_ContentDistribution_Id__c != null) {
                    ContentDistribution conDist = contentDistributionsById.get(job.DOC_ContentDistribution_Id__c);
                    if (conDist != null) {
                        // Create the file details and add them to the list
                        this.fileDetailsList.add(new FileDetails(conDist.DistributionPublicUrl,conDist.ContentDownloadUrl, conDist.Name, job.Name, String.join(jobChargeNames,','),'Annual Duty of Care'));
                         this.contentDocumentIds.add(conDist.ContentVersionId);
                    }
                }
				*/
                
                // Add the Weighbridge Ticket
                if(isContains(new List<String>{'Tonnage', 'Rebate'}, chargeTypes)){
                    if (job.Weighbridge_ContentDistribution_Id__c != null) {
                        ContentDistribution conDist = contentDistributionsById.get(job.Weighbridge_ContentDistribution_Id__c);
                        if (conDist != null) {
                            // Create the file details and add them to the list
                            this.fileDetailsList.add(new FileDetails(conDist.DistributionPublicUrl,conDist.ContentDownloadUrl, conDist.Name, job.Name, String.join(jobChargeNames,','),'Weighbridge Ticket'));
                            this.contentDocumentIds.add(conDist.ContentVersionId);
                        }
                    }
                }

                // Add the WTN/COD
                if(isContains(new List<String>{'Job', 'Rebate Transport'}, chargeTypes)){
                    String WTN_ContentDistribution_Id = job.Parent_Job__c != null ? job.Parent_Job__r.WTN_ContentDistribution_Id__c : job.WTN_ContentDistribution_Id__c;
                    if (WTN_ContentDistribution_Id != null) {
                        ContentDistribution conDist = contentDistributionsById.get(WTN_ContentDistribution_Id);
                        if (conDist != null) {
                            // Create the file details and add them to the list
                            this.fileDetailsList.add(new FileDetails(conDist.DistributionPublicUrl,conDist.ContentDownloadUrl, conDist.Name, job.Name, String.join(jobChargeNames,','),'Waste Transfer Note'));
                            this.contentDocumentIds.add(conDist.ContentVersionId);
                        }
                    }
                    
                    String COD_ContentDistribution_Id = job.Parent_Job__c != null ? job.Parent_Job__r.COD_ContentDistribution_Id__c : job.COD_ContentDistribution_Id__c;
                    if (COD_ContentDistribution_Id != null) {
                        ContentDistribution conDist = contentDistributionsById.get(COD_ContentDistribution_Id);
                        if (conDist != null) {
                            // Create the file details and add them to the list
                            this.fileDetailsList.add(new FileDetails(conDist.DistributionPublicUrl,conDist.ContentDownloadUrl, conDist.Name, job.Name, String.join(jobChargeNames,','),'COD'));
                            this.contentDocumentIds.add(conDist.ContentVersionId);
                        }
                    }
                }
                
                // Add the Collection Note
                if (job.Collection_Note_ContentDistribution_Id__c != null) {
                    ContentDistribution conDist = contentDistributionsById.get(job.Collection_Note_ContentDistribution_Id__c);
                    if (conDist != null) {
                        // Create the file details and add them to the list
                        this.fileDetailsList.add(new FileDetails(conDist.DistributionPublicUrl,conDist.ContentDownloadUrl, conDist.Name, job.Name, String.join(jobChargeNames,','),'Collection Note'));
                         this.contentDocumentIds.add(conDist.ContentVersionId);
                    }
                }
                
                // Add the Delivery Note
                if(isContains(new List<String>{'Job', 'Rebate Transport'}, chargeTypes)){
                    String Delivery_Note_ContentDistribution_Id = job.Parent_Job__c != null ? job.Parent_Job__r.Delivery_Note_ContentDistribution_Id__c : job.Delivery_Note_ContentDistribution_Id__c;
                    
                    if(Delivery_Note_ContentDistribution_Id != null){
                        ContentDistribution conDist = contentDistributionsById.get(Delivery_Note_ContentDistribution_Id);
                        if (conDist != null) {
                            // Create the file details and add them to the list
                            this.fileDetailsList.add(new FileDetails(conDist.DistributionPublicUrl,conDist.ContentDownloadUrl, conDist.Name, job.Name, String.join(jobChargeNames,','),'Delivery Note'));
                            this.contentDocumentIds.add(conDist.ContentVersionId);
                        }
                    }
                    
                }
            }
            System.debug(fileDetailsList);
            this.contentVersionIds = String.join(this.contentDocumentIds, ',');

            // Get invoice files from ContentDocumentLink
            this.invoiceFileDetailsList = new List<InvoiceFileDetails>();
            List<ContentDocumentLink> invoiceDocLinks = [
                SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.LatestPublishedVersionId,
                       ContentDocument.LatestPublishedVersion.VersionDataUrl, ContentDocument.FileExtension,
                       ContentDocument.LatestPublishedVersion.CreatedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :invoiceId
                AND ContentDocument.FileExtension = 'pdf'
                ORDER BY ContentDocument.LatestPublishedVersion.CreatedDate DESC
            ];

            // Deduplicate by filename - only show the most recent version of each file
            Set<String> seenFileNames = new Set<String>();
            Set<Id> invoiceContentVersionIds = new Set<Id>();
            for (ContentDocumentLink cdl : invoiceDocLinks) {
                String fileName = cdl.ContentDocument.Title + '.' + cdl.ContentDocument.FileExtension;

                // Only add if we haven't seen this filename yet (first occurrence is most recent due to ORDER BY)
                if (!seenFileNames.contains(fileName)) {
                    seenFileNames.add(fileName);
                    invoiceContentVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
                }
            }

            // Get existing ContentDistribution records for invoice files (don't create new ones - guest users can't)
            Map<Id, ContentDistribution> contentDistByVersionId = new Map<Id, ContentDistribution>();
            if (!invoiceContentVersionIds.isEmpty()) {
                // Check for existing ContentDistribution records
                for (ContentDistribution cd : [
                    SELECT Id, ContentVersionId, DistributionPublicUrl, ContentDownloadUrl
                    FROM ContentDistribution
                    WHERE ContentVersionId IN :invoiceContentVersionIds
                    LIMIT 50
                ]) {
                    contentDistByVersionId.put(cd.ContentVersionId, cd);
                }

                // Build the invoice file details list with ContentDistribution URLs for files that have them
                Set<String> addedFiles = new Set<String>();
                for (ContentDocumentLink cdl : invoiceDocLinks) {
                    String fileName = cdl.ContentDocument.Title + '.' + cdl.ContentDocument.FileExtension;
                    if (!addedFiles.contains(fileName) && contentDistByVersionId.containsKey(cdl.ContentDocument.LatestPublishedVersionId)) {
                        addedFiles.add(fileName);
                        ContentDistribution cd = contentDistByVersionId.get(cdl.ContentDocument.LatestPublishedVersionId);
                        this.invoiceFileDetailsList.add(new InvoiceFileDetails(
                            cd.DistributionPublicUrl,
                            cd.ContentDownloadUrl,
                            fileName,
                            'Invoice'
                        ));
                    }
                }
            }
            System.debug('Invoice files: ' + invoiceFileDetailsList);
        }

    }

    /************************* INNER CLASSES ********************/
    public class FileDetails {
        public String url {public get; private set;}
        public String downloadUrl {public get; private set;}
        public String fileName {public get; private set;}
        public String jobReference {public get; private set;}
        public String jobChargeNames {public get; private set;}
        public String docType {public get; private set;}

        public FileDetails(String url,String downloadUrl, String fileName, String jobReference, String jobChargeIds, String docType) {
            this.url = url;
            this.downloadUrl = downloadUrl;
            this.fileName = fileName;
            this.jobReference = jobReference;
            this.jobChargeNames = jobChargeIds;
            this.docType = docType;
        }

    }

    public class InvoiceFileDetails {
        public String url {public get; private set;}
        public String downloadUrl {public get; private set;}
        public String fileName {public get; private set;}
        public String docType {public get; private set;}

        public InvoiceFileDetails(String url, String downloadUrl, String fileName, String docType) {
            this.url = url;
            this.downloadUrl = downloadUrl;
            this.fileName = fileName;
            this.docType = docType;
        }
    }
    
    public static Boolean isContains(List<String> list1, List<String> list2){
        Boolean isContains = false;
        if(list1 != null && list2 != null){
            for(String list1Item : list1){
                isContains = isContains ? true : list2.contains(list1Item);
            }
        }
        return isContains;
    }

    /**************** PRIVATE METHODS *******************/
    private static Boolean isValidId(String strId) {
        Boolean isValid = (strId instanceof Id) ? true : false ;
        return isValid ;
    }


}