public class InvoiceTriggerHandler {
    public static void afterInsert(List<Invoice__c> invoiceRecs,Map<Id,Invoice__c> invoiceRecsMap){
        CommunityAccessHelper.addInvoiceAccess(invoiceRecsMap.keyset());

        // Create ContentDistribution records for invoice PDFs to make them accessible in portal
        ContentDistributionHelper.manageInvoiceContentDistribution(invoiceRecsMap.keySet());
    }
    public static void afterUpdate(List<Invoice__c> invoiceRecs,Map<Id,Invoice__c> invoiceRecsMap,List<Invoice__c> oldInvoiceRecs,Map<Id,Invoice__c> oldInvoiceRecsMap){
        Set<Id> newInvoiceForAccess = new Set<Id>();
        Map<Id,Id> invoiceSiteMap = new Map<Id,Id>();

        for(Invoice__c invoiceRec : invoiceRecs){
            if(invoiceRec.Site__c != oldInvoiceRecsMap.get(invoiceRec.Id).Site__c){
                if(invoiceRec.Site__c != null){
                    newInvoiceForAccess.add(invoiceRec.Id);
                }
                if(oldInvoiceRecsMap.get(invoiceRec.Id).Site__c != null){
                    invoiceSiteMap.put(invoiceRec.Id,oldInvoiceRecsMap.get(invoiceRec.Id).Site__c);
                }
            }
        }
        if(invoiceSiteMap.size()>0){
            CommunityAccessHelper.removeInvoiceAccess(invoiceSiteMap);
        }
        if(newInvoiceForAccess.size()>0){
            CommunityAccessHelper.addInvoiceAccess(newInvoiceForAccess);
        }

        // Create ContentDistribution records for invoice PDFs to make them accessible in portal
        ContentDistributionHelper.manageInvoiceContentDistribution(invoiceRecsMap.keySet());
    }
     public static void OnBeforeDelete(List<Invoice__c> invoiceRecs,Map<Id,Invoice__c> invoiceRecsMap)
     {
         System.debug('Starting after delete trigger');
         Set<Id> invIdList=new Set<Id>();
      	 for(Invoice__c invoiceRec : invoiceRecs){
           invIdList.add(invoiceRec.Id);
    	 }
         
         List<Job_Charge__c> updateList = [select Id,Has_Invoice__c,Has_Sales_Invoice__c,Has_Vendor_Invoice__c,Invoice__c,Vendor_Invoice__c from Job_Charge__c where Invoice__c in:invIdList];
 		 System.debug('Job Charge count : '+updateList.size());         
         if(updateList.size() > 0) {
     		  for (Job_Charge__c jobCharge : updateList)
              {
                 jobCharge.Invoice__c=null;
                 jobCharge.Has_Invoice__c = jobCharge.Vendor_Invoice__c != null; 
                 jobCharge.Has_Sales_Invoice__c=false;
           	
              }
         	  System.debug(updateList);
         	  update updateList;
         }
         
      
    }
}