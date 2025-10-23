public class ContentDistributionHelper {
    public static void manageContentDistribution(Map<Id,Job__c> jobMap){
        Set<Id> adocJobIds = new Set<Id>();
        Set<Id> wtnJobIds = new Set<Id>();
        for(Job__c jobRec :jobMap.values()){
            List<String> requiredPaperwork = jobRec.required_paperwork__c == null? new List<String>():jobRec.required_paperwork__c.split(';');
            System.debug(requiredPaperwork + '  ' +jobRec.DOC_uploaded__c+ '  '+jobRec.DOC_ContentDistribution_Id__c);
            if(requiredPaperwork.contains('ADOC') && jobRec.DOC_uploaded__c && jobRec.DOC_ContentDistribution_Id__c == null){
                adocJobIds.add(jobRec.Id);
            }
            System.debug(requiredPaperwork + '  ' +jobRec.Waste_Transfer_Note_Uploaded__c+ '  '+jobRec.WTN_ContentDistribution_Id__c);
            if(requiredPaperwork.contains('WTN') && jobRec.Waste_Transfer_Note_Uploaded__c && jobRec.WTN_ContentDistribution_Id__c == null){
                wtnJobIds.add(jobRec.Id);
            }
        }
        
        if(adocJobIds.size() > 0 || wtnJobIds.size() > 0){
            List<ContentDocumentLink> cdLinks = [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Document__c 
                                                 FROM ContentDocumentLink 
                                                 Where LinkedEntityId IN :adocJobIds OR LinkedEntityId IN :wtnJobIds];
            
            
            Map<Id,String> adocMap = new Map<Id,String>();
            Map<Id,String> wtnMap = new Map<Id,String>();
            for(ContentDocumentLink cdLink :cdLinks){
                if(adocJobIds.contains(cdLink.LinkedEntityId) && cdLink.ContentDocument.LatestPublishedVersion.Document__c == 'Annual Duty of Care'){
                    adocMap.put(cdLink.LinkedEntityId,cdLink.ContentDocument.LatestPublishedVersionId);
                }
                
                if(wtnJobIds.contains(cdLink.LinkedEntityId) && cdLink.ContentDocument.LatestPublishedVersion.Document__c == 'Waste Transfer Note'){
                    wtnMap.put(cdLink.LinkedEntityId,cdLink.ContentDocument.LatestPublishedVersionId);
                }
            }
            
            Map<String,ContentDistribution> adocDistribution = new Map<String,ContentDistribution>();
            for(String jobId :adocMap.keyset()){
                ContentDistribution cdRec = createCD(adocMap.get(jobId),'ADOC Preview', jobId ); 
                adocDistribution.put(jobId,cdRec);
            }
            
            Map<String,ContentDistribution> wtnDistribution = new Map<String,ContentDistribution>();
            for(String jobId :wtnMap.keyset()){
                ContentDistribution cdRec = createCD(wtnMap.get(jobId),'WTN Preview', jobId ); 
                wtnDistribution.put(jobId,cdRec);
            }
            
            List<Database.SaveResult> adocDistributionSR = Database.Insert(adocDistribution.values(),false);
            System.debug(JSON.serialize(adocDistributionSR));
            List<Database.SaveResult> wtnDistributionSR = Database.Insert(wtnDistribution.values(),false);
            System.debug(JSON.serialize(wtnDistributionSR));
            
            
            Map<String,Job__c> updateJobMap = new Map<String,Job__c>();
            
            for(String jobId :adocDistribution.keyset()){
                ContentDistribution cdRec = adocDistribution.get(jobId);
                if(cdRec.Id != null){
                    Job__c jobRec = updateJobMap.containsKey(jobId)?updateJobMap.get(jobId):new Job__c(Id=jobId);
                    jobRec.DOC_ContentDistribution_Id__c = cdRec.Id;
                    updateJobMap.put(jobRec.Id,jobRec);
                }
            }
            
            for(String jobId :wtnDistribution.keyset()){
                ContentDistribution cdRec = wtnDistribution.get(jobId);
                if(cdRec.Id != null){
                    Job__c jobRec = updateJobMap.containsKey(jobId)?updateJobMap.get(jobId):new Job__c(Id=jobId);
                    jobRec.WTN_ContentDistribution_Id__c = cdRec.Id;
                    updateJobMap.put(jobRec.Id,jobRec);
                }
            }
            
            Database.update(updateJobMap.values(),false);
        }
        
    }
    
    /**
     * Create ContentDistribution records for invoice PDF files
     * This allows invoice PDFs to be publicly accessible in the customer portal
     */
    public static void manageInvoiceContentDistribution(Set<Id> invoiceIds){
        if(invoiceIds == null || invoiceIds.isEmpty()){
            return;
        }

        // Get all PDF files linked to invoices
        List<ContentDocumentLink> cdLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId,
                   ContentDocument.LatestPublishedVersionId,
                   ContentDocument.Title,
                   ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :invoiceIds
            AND ContentDocument.FileExtension = 'pdf'
        ];

        if(cdLinks.isEmpty()){
            return;
        }

        // Get ContentVersionIds
        Set<Id> contentVersionIds = new Set<Id>();
        Map<Id,String> versionIdToTitle = new Map<Id,String>();
        for(ContentDocumentLink cdLink : cdLinks){
            contentVersionIds.add(cdLink.ContentDocument.LatestPublishedVersionId);
            versionIdToTitle.put(cdLink.ContentDocument.LatestPublishedVersionId, cdLink.ContentDocument.Title);
        }

        // Check for existing ContentDistribution records
        Set<Id> existingVersionIds = new Set<Id>();
        for(ContentDistribution cd : [
            SELECT ContentVersionId
            FROM ContentDistribution
            WHERE ContentVersionId IN :contentVersionIds
        ]){
            existingVersionIds.add(cd.ContentVersionId);
        }

        // Create ContentDistribution for PDFs that don't have one
        List<ContentDistribution> newDistributions = new List<ContentDistribution>();
        for(Id versionId : contentVersionIds){
            if(!existingVersionIds.contains(versionId)){
                // Don't set RelatedRecordId for invoice PDFs to allow guest user access
                ContentDistribution cdRec = new ContentDistribution();
                cdRec.ContentVersionId = versionId;
                cdRec.Name = versionIdToTitle.get(versionId);
                cdRec.PreferencesAllowViewInBrowser = true;
                cdRec.PreferencesAllowOriginalDownload = true;
                cdRec.PreferencesAllowPDFDownload = true;
                cdRec.PreferencesLinkLatestVersion = false;
                newDistributions.add(cdRec);
            }
        }

        // Insert new ContentDistribution records
        if(!newDistributions.isEmpty()){
            Database.insert(newDistributions, false);
        }
    }

    public static ContentDistribution createCD(String cvId, String name, String recordId){
        ContentDistribution cdRec = new ContentDistribution();
        cdRec.ContentVersionId = cvId;
        cdRec.Name = name;
        cdRec.RelatedRecordId = recordId;
        cdRec.PreferencesAllowViewInBrowser = true;
        cdRec.PreferencesAllowOriginalDownload = true;
        cdRec.PreferencesAllowPDFDownload = true;
        cdRec.PreferencesLinkLatestVersion = true;
        return cdRec;
    }
}