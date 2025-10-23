public with sharing class Utility_Community {
    /*
     * depotViewCommunity.html
     * invoiceListCommunity.html
     * jobFileZipDownloadCommunity.html
     * placeAnOrderCommunity.html
     */
    @AuraEnabled(cacheable=true)
    public static List<Site__c> getAvailableSites() {
        return [SELECT Id, Name, Postalcode__c FROM Site__c Order by Name ASC];
    }
    
    /*
     * depotViewCommunity.html
     */
    @AuraEnabled(Cacheable = true)
    public static List<Map<String, object>> getDepotInformations(List<String> siteIds){
        
        List<Map<String, object>> outputs = new List<Map<String, object>>();
        
        for(Job__c jobRec : [SELECT Id, Name, Delivery_Date__c, Supplier__c, Supplier__r.Name, Depot_Dispose__c, Depot_Dispose__r.Name,
                             Waste_Type_2__c, EWC_Code_2__c, Site__c, Site__r.Name,
                             Waste_Carrier_License_Number__c, Waste_Carrier_License_Expiry__c
                             FROM Job__c
                             WHERE Site__c IN :siteIds AND Status__c NOT IN ('Pending Cancellation', 'Cancelled', 'Failed')
                             AND Supplier__c != NULL AND Supplier__r.Name != NULL AND Depot_Dispose__c != NULL
                             ORDER BY Supplier__r.Name, Depot_Dispose__r.Name]){
                                 outputs.add(new Map<String, object>{
                                     'jobId' => jobRec.Id,
                                         'jobName' => jobRec.Name,
                                         'siteId' => jobRec.Site__c,
                                         'siteName' => jobRec.Site__r.Name,
                                         'deliveryDate' => jobRec.Delivery_Date__c,
                                         'supplierId' => jobRec.Supplier__c,
                                         'supplierName' => jobRec.Supplier__r.Name,
                                         'depotDisposeId' => jobRec.Depot_Dispose__c,
                                         'depotDispose' => jobRec.Depot_Dispose__r.Name,
                                         'wasteType' => jobRec.Waste_Type_2__c,
                                         'ewcCode' => jobRec.EWC_Code_2__c,
                                         'licenseNumber' => jobRec.Waste_Carrier_License_Number__c,
                                         'licenseExpiry' => jobRec.Waste_Carrier_License_Expiry__c
                                         });
                             }
        
        return outputs;
    }
    
    /*
     * invoiceListCommunity.html
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getInvoices(String invoiceNumberSearchText, List<String> siteIds, Date startDate, Date endDate) {
        String query = 'SELECT Name, Raised_Date__c, Due_Date__c, Total__c, Site__r.Name, Account__r.Name FROM Invoice__c ';
        List<String> queries = new List<String>();
        
        if(String.isNotblank(invoiceNumberSearchText)){
            queries.add('Name LIKE \'%' + invoiceNumberSearchText.trim() + '%\'');
        }
        if (siteIds != null && siteIds.size() > 0) {
            queries.add('Site__c IN :siteIds');
        }
        if (startDate != null) {
            queries.add('Raised_Date__c >= :startDate');
        }
        if (endDate != null) {
            queries.add('Raised_Date__c <= :endDate');
        }
        
        query += queries.size() > 0 ? ' WHERE ' + String.join(queries, ' AND ') : '';
        
        query += ' Order by Raised_Date__c DESC';
        
        List<Invoice__c> recs = (List<Invoice__c>)  Database.query(query);
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Invoice__c rec : recs) {
            Map<String, Object> invoiceMap = new Map<String, Object>();
            invoiceMap.put('invoiceNumber', rec.Name);
            invoiceMap.put('invoiceUrl', '/s/invoice/' + rec.Id);
            invoiceMap.put('raisedDate', rec.Raised_Date__c);
            invoiceMap.put('dueDate', rec.Due_Date__c);
            invoiceMap.put('total', rec.Total__c);
            invoiceMap.put('siteName', rec.Site__r.Name);
            invoiceMap.put('accountName', rec.Account__r.Name);
            
            result.add(invoiceMap);
        }
        
        return result;
    }
    
    
    /*
     * arrangeCollectionCommunity.html
	*/
    @AuraEnabled(cacheable=true)
    public static List<Site__c> getAvailableSitesWithArrangeCollectionJobs() {
        return [SELECT Id, Name, Postalcode__c FROM Site__c Where Id IN (Select Site__c from Job__c Where Is_On_Site_Job__c = true and Collection_Date__c = NULL and Schedule__c = NULL) Order by Name ASC];
    }
    
    
    /*
     * placeAnOrderCommunity.html
	*/
    @AuraEnabled
    public static List<Map<String, Object>> getPlanAnOrderJobs(List<String> siteIds) {
        String query = 'SELECT Id, Name, Collection_Date__c, Delivery_Date__c, Supplier__c, Supplier__r.Name, Waste_Type__c, Is_On_Site_Job__c ';
        query += ' ,Product_Name__c, Site__c, Site__r.Name, Account__c, Account__r.Name, Order_Product__c, Order_Product__r.Order.OrderNumber, Order_Product__r.Order.PoNumber ';
        query += '  FROM Job__c  ';
        List<String> queries = new List<String>();
        
        queries.add('Site__c IN :siteIds');   
        queries.add('Is_On_Site_Job__c = true');
        queries.add('Collection_Date__c = NULL');
        queries.add('Schedule__c = NULL');
        queries.add('Order_Product__r.Order.Status = \'Activated\'');
        
        query += queries.size() > 0 ? ' WHERE ' + String.join(queries, ' AND ') : '';
        
        query += ' Order by Delivery_Date__c DESC';
        
        List<Job__c> recs = (List<Job__c>)  Database.query(query);
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<String> orderItemIds = new List<String>();
        for (Job__c rec : recs) {
            orderItemIds.add(rec.Order_Product__c);
            
            Map<String, Object> recMap = new Map<String, Object>();
            recMap.put('jobId', rec.Id);
            recMap.put('name', rec.Name);
            recMap.put('jobUrl', '/s/job/' + rec.Id);
            recMap.put('collectionDate', rec.Collection_Date__c);
            recMap.put('deliveryDate', rec.Delivery_Date__c);
            recMap.put('wasteType', rec.Waste_Type__c);
            recMap.put('productName', rec.Product_Name__c);
            recMap.put('siteName', rec.Site__r.Name);
            recMap.put('accountName', rec.Account__r.Name);
            recMap.put('accountId', rec.Account__c);
            recMap.put('supplierName', rec.Supplier__r.Name);
            recMap.put('supplierId', rec.Supplier__c);
            recMap.put('orderItemId' , rec.Order_Product__c);
            recMap.put('orderNumber' , rec.Order_Product__r.Order.PoNumber);
            recMap.put('isJobOnSite' , rec.Is_On_Site_Job__c);
            
            result.add(recMap);
        }
        
        for(OrderItem rec :[Select id, Order.OrderNumber, Order.PoNumber, Order.Site__r.Name, Waste_Type_2__c, Product2.Name, Partner__c, Partner__r.Name 
                            from OrderItem 
                            Where ID NOT IN :orderItemIds 
                            and Order.Site__c IN :siteIds
                            and Order.Status = 'Activated']){
            Map<String, Object> recMap = new Map<String, Object>();
            
            recMap.put('wasteType', rec.Waste_Type_2__c);
            recMap.put('productName', rec.Product2.Name);
            recMap.put('siteName', rec.Order.Site__r.Name);
            recMap.put('orderItemId' , rec.id);
            recMap.put('orderNumber' , rec.Order.PoNumber);
            result.add(recMap);            
        }
        
        return result;
    }
    
      /*
     * placeAnOrderCommunity.html
	*/
    @AuraEnabled(Cacheable=true)
    public static List<Map<String, Object>> getPlanAnOrderServiceses(List<String> siteIds) {
        String query = 'SELECT Id, Product2.Name, Waste_Type_2__c, Order.Site__r.Name ';
        query += '  FROM OrderItem  ';
        List<String> queries = new List<String>();
        
        queries.add('Order.Site__c IN :siteIds');  
        queries.add('Order.Status = \'Activated\' ');
        
        query += queries.size() > 0 ? ' WHERE ' + String.join(queries, ' AND ') : '';
        
        
        List<OrderItem> recs = (List<OrderItem>)  Database.query(query);
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (OrderItem rec : recs) {
            Map<String, Object> recMap = new Map<String, Object>();
            recMap.put('id', rec.Id);
            recMap.put('productName', rec.Product2.Name);
            recMap.put('wasteType', rec.Waste_Type_2__c);
            recMap.put('siteName', rec.Order.Site__r.Name);
            result.add(recMap);
        }
        return result;
        
    }
    
    /*
     * arrangeCollectionCommunity.html
	*/
    @AuraEnabled
    public static List<Map<String, Object>> getArrangeCollectionJobs(List<String> siteIds) {
        String query = 'SELECT Id, Name, Collection_Date__c, Delivery_Date__c, Supplier__c, Supplier__r.Name, Waste_Type__c, Is_On_Site_Job__c ';
        query += ' ,Product_Name__c, Site__c, Site__r.Name, Account__c, Account__r.Name';
        query += '  FROM Job__c  ';
        List<String> queries = new List<String>();
        
        queries.add('Site__c IN :siteIds');  
        queries.add('Is_On_Site_Job__c = true');
        queries.add('Collection_Date__c = NULL');
        queries.add('Schedule__c = NULL');
        
        query += queries.size() > 0 ? ' WHERE ' + String.join(queries, ' AND ') : '';
        
        query += ' Order by Delivery_Date__c DESC';
        
        List<Job__c> recs = (List<Job__c>)  Database.query(query);
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Job__c rec : recs) {
            Map<String, Object> jobMap = new Map<String, Object>();
            jobMap.put('jobId', rec.Id);
            jobMap.put('name', rec.Name);
            jobMap.put('jobUrl', '/s/job/' + rec.Id);
            jobMap.put('collectionDate', rec.Collection_Date__c);
            jobMap.put('deliveryDate', rec.Delivery_Date__c);
            jobMap.put('wasteType', rec.Waste_Type__c);
            jobMap.put('productName', rec.Product_Name__c);
            jobMap.put('siteName', rec.Site__r.Name);
            jobMap.put('accountName', rec.Account__r.Name);
            jobMap.put('accountId', rec.Account__c);
            jobMap.put('supplierName', rec.Supplier__r.Name);
            jobMap.put('supplierId', rec.Supplier__c);
            jobMap.put('isJobOnSite' , rec.Is_On_Site_Job__c);
            
            result.add(jobMap);
        }
        
        return result;
    }
    /*
     * jobFileZipDownloadCommunity.html
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getJobs(List<String> siteIds, Date startDate, Date endDate, List<String> selectedDocumentTypes) {
        String query = 'SELECT Id, Name, Collection_Date__c, Delivery_Date__c, Supplier__c, Supplier__r.Name, Waste_Type__c ';
        query += ' ,Product_Name__c, Site__c, Site__r.Name, Account__c, Account__r.Name';
        query += '  ,(Select Id, ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension from ContentDocumentLinks Where ContentDocument.LatestPublishedVersion.Document__c IN :selectedDocumentTypes) ';
        query += '  FROM Job__c  ';
        List<String> queries = new List<String>();
        
        if (siteIds != null && siteIds.size() > 0) {
            queries.add('Site__c IN :siteIds');
        }
        if (startDate != null) {
            queries.add('Collection_Date__c >= :startDate');
        }
        if (endDate != null) {
            queries.add('Collection_Date__c <= :endDate');
        }
        
        query += queries.size() > 0 ? ' WHERE ' + String.join(queries, ' AND ') : '';
        
        query += ' Order by Collection_Date__c DESC';
        
        List<Job__c> recs = (List<Job__c>)  Database.query(query);
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Job__c rec : recs) {
            Map<String, Object> jobMap = new Map<String, Object>();
            jobMap.put('name', rec.Name);
            jobMap.put('jobUrl', '/s/job/' + rec.Id);
            jobMap.put('collectionDate', rec.Collection_Date__c);
            jobMap.put('deliveryDate', rec.Delivery_Date__c);
            jobMap.put('wasteType', rec.Waste_Type__c);
            jobMap.put('productName', rec.Product_Name__c);
            jobMap.put('siteName', rec.Site__r.Name);
            jobMap.put('accountName', rec.Account__r.Name);
            jobMap.put('accountId', rec.Account__c);
            jobMap.put('supplierName', rec.Supplier__r.Name);
            jobMap.put('supplierId', rec.Supplier__c);
            
            // Process ContentDocumentLinks
            List<Map<String, String>> documents = new List<Map<String, String>>();
            for (ContentDocumentLink cdLink : rec.ContentDocumentLinks) {
                Map<String, String> documentMap = new Map<String, String>();
                documentMap.put('docId', cdLink.ContentDocumentId);
                documentMap.put('title', cdLink.ContentDocument.Title);
                documents.add(documentMap);
            }
            jobMap.put('documents', documents);
            
            result.add(jobMap);
        }
        
        return result;
    }
}