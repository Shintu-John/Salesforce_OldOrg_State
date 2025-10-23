/**
 * @description This is a test class for the file list controller
 */

@IsTest
private class InvoiceFileListControllerTest {
    private static final Date DEFAULT_DATE = Date.newInstance(2019,1,1);

    static {}

    private static void init() {}

    @TestSetup private static void setup() {}

    /**
     * @description Test that the controller finds files for a given invoice including invoice PDFs
     */
    @IsTest
    static void testGetFileDetails() {

        // Create a supplier
        Account supplier = TestFactory.createSupplier('Vendor 1');
        insert supplier;

        // Create some clients
        Account testClient = TestFactory.createClient('Company 1');
        insert testClient;

        // Create an invoice that can be used in a charge to make sure it is not included
        Invoice__c invoice = TestFactory.createInvoice(testClient.Id, System.today(),TestFactory.INVOICE_STATUS_DRAFT);
        insert invoice;

        // Create an order
        Order ord = TestFactory.createOrder('Order 1',supplier.Id);
        insert ord;

        // Create a product
        Product2 prod = TestFactory.createProduct('Test Product');
        insert prod;

        // Create a price book entry
        PricebookEntry pbe = TestFactory.createPricebookEntry(prod.Id,Test.getStandardPricebookId(),123.45);
        insert pbe;

        //Depot
        Depot__c depotRec = new Depot__c();
        depotRec.Name = 'Test Depot';
        depotRec.Permit_Reference__c = 'WEX374229';
        insert depotRec;

        // Create an order line
        OrderItem orderProduct = TestFactory.createOrderProduct(ord.Id,supplier.Id,prod.Id,pbe.Id, 200,250, 100, 15, 20);
        orderProduct.Depot_Dispose__c = depotRec.Id;
        orderProduct.Depot_Supply__c = depotRec.Id;
        insert orderProduct;

        // Create some jobs - reduced to 2 to avoid SOQL limit issues with triggers
        Map<String, Job__c> jobsByRef = new Map<String, Job__c>();
        jobsByRef.put('J1',TestFactory.createJob( testClient.Id,'Open','Fixed', orderProduct.Id, supplier.Id, DEFAULT_DATE, 'ref1'));
        jobsByRef.put('J2',TestFactory.createJob( testClient.Id,'Open','Fixed', orderProduct.Id,  supplier.Id, DEFAULT_DATE, 'ref1'));
        insert jobsByRef.values();

        // Add some files to the jobs
        Map<Id, List<ContentDistribution>> contentDistsByJobId = createContentForJobs(jobsByRef.values());
        List<Job__c> jobRecs = new List<Job__c>();
        for(Id jobId : contentDistsByJobId.keyset()){
            Job__c jobRec = new Job__c();
            jobRec.Id = jobId;
            for(ContentDistribution ContentDistributionRec : contentDistsByJobId.get(jobId)){
                jobRec.DOC_ContentDistribution_Id__c = ContentDistributionRec.Id;
                jobRec.Weighbridge_ContentDistribution_Id__c =  ContentDistributionRec.Id;
                jobRec.WTN_ContentDistribution_Id__c =  ContentDistributionRec.Id;
            }
            jobRecs.add(jobRec);
        }
        update jobRecs;

        // Add some job charges using 'Job' charge type which is always valid
        Map<String, Job_Charge__c> jobChargesByRef = new Map<String, Job_Charge__c>();
        jobChargesByRef.put('J1_C1',TestFactory.createJobCharge(jobsByRef.get('J1').Id,'Job',DEFAULT_DATE,100.00,150.00)); // C1 Job
        jobChargesByRef.put('J2_C1',TestFactory.createJobCharge(jobsByRef.get('J2').Id,'Job',DEFAULT_DATE,300.00,350.00)); // C1 Job

        // Allocate charge to invoice
        jobChargesByRef.get('J1_C1').Invoice__c = invoice.Id;
        jobChargesByRef.get('J2_C1').Invoice__c = invoice.Id;
        insert jobChargesByRef.values();

        // Create invoice PDF files linked to the invoice
        List<ContentVersion> invoiceFiles = new List<ContentVersion>();
        invoiceFiles.add(createContentVersion('Invoice - ' + invoice.Name + '.pdf', 'Invoice PDF content'));
        invoiceFiles.add(createContentVersion('Supporting Doc.pdf', 'Supporting document content'));
        insert invoiceFiles;

        // Link the invoice PDFs to the invoice record
        List<Id> invoiceContentDocIds = new List<Id>();
        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :invoiceFiles]) {
            invoiceContentDocIds.add(cv.ContentDocumentId);
        }

        List<ContentDocumentLink> invoiceDocLinks = new List<ContentDocumentLink>();
        for(Id docId : invoiceContentDocIds) {
            invoiceDocLinks.add(createContentDocumentLink(docId, invoice.Id));
        }
        insert invoiceDocLinks;

        // Create ContentDistribution for invoice files so they can be displayed
        List<ContentDistribution> invoiceDistributions = new List<ContentDistribution>();
        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :invoiceFiles]) {
            ContentDistribution cd = new ContentDistribution();
            cd.ContentVersionId = cv.Id;
            cd.Name = 'Test Distribution';
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesAllowOriginalDownload = true;
            invoiceDistributions.add(cd);
        }
        insert invoiceDistributions;

        // Start the test
        Test.startTest();

        // Get the page reference
        PageReference pageRef = Page.InvoiceFileList;
        Test.setCurrentPage(pageRef);

        // Instantiate the controller without invoice ID
        InvoiceFileListController controller = new InvoiceFileListController();

        // Test that the controller does not have an invoice or list since no invoice ID has been provided
        System.assertEquals(null, controller.invoice, 'Invoice should be null when no ID provided');

        // Add an invoice ID parameter
        ApexPages.currentPage().getParameters().put('invoiceid', invoice.Id);

        // Instantiate the controller with invoice ID
        controller = new InvoiceFileListController();

        // Stop the test
        Test.stopTest();

        // Test that the invoice is there
        System.assertEquals(invoice.Id, controller.invoice.Id, 'Invoice should be populated');

        // Test that the job paperwork files have been found
        System.assertNotEquals(null, controller.fileDetailsList, 'File details list should not be null');
        System.assert(controller.fileDetailsList.size() > 0, 'Should have job paperwork files');

        // Test that the invoice files have been found (NEW FUNCTIONALITY)
        System.assertNotEquals(null, controller.invoiceFileDetailsList, 'Invoice file details list should not be null');
        System.assertEquals(2, controller.invoiceFileDetailsList.size(), 'Should have 2 invoice PDF files');

        // Verify invoice file properties
        Boolean foundInvoiceFile = false;
        for(InvoiceFileListController.InvoiceFileDetails fileDetail : controller.invoiceFileDetailsList) {
            System.assertNotEquals(null, fileDetail.fileName, 'File name should not be null');
            System.assertNotEquals(null, fileDetail.url, 'URL should not be null');
            System.assertNotEquals(null, fileDetail.downloadUrl, 'Download URL should not be null');
            System.assertEquals('Invoice', fileDetail.docType, 'Doc type should be Invoice');

            if(fileDetail.fileName.contains('Invoice')) {
                foundInvoiceFile = true;
            }
        }
        System.assert(foundInvoiceFile, 'Should find invoice PDF file');
    }

    /**
     * @description Test invalid invoice ID handling
     */
    @IsTest
    static void testInvalidInvoiceId() {
        // Get the page reference
        PageReference pageRef = Page.InvoiceFileList;
        Test.setCurrentPage(pageRef);

        // Add an invalid invoice ID parameter
        ApexPages.currentPage().getParameters().put('invoiceid', 'invalid');

        Test.startTest();
        // Instantiate the controller
        InvoiceFileListController controller = new InvoiceFileListController();
        Test.stopTest();

        // Test that the controller detected the invalid ID
        System.assertEquals(false, controller.isIdValid, 'Should detect invalid ID');
        System.assertEquals(true, controller.displayMessage, 'Should display error message');
    }

    /**
     * @description Test invoice with no files
     */
    @IsTest
    static void testInvoiceWithNoFiles() {
        // Create a client
        Account testClient = TestFactory.createClient('Company 1');
        insert testClient;

        // Create an invoice with no files
        Invoice__c invoice = TestFactory.createInvoice(testClient.Id, System.today(),TestFactory.INVOICE_STATUS_DRAFT);
        insert invoice;

        // Get the page reference
        PageReference pageRef = Page.InvoiceFileList;
        Test.setCurrentPage(pageRef);

        // Add invoice ID parameter
        ApexPages.currentPage().getParameters().put('invoiceid', invoice.Id);

        Test.startTest();
        // Instantiate the controller
        InvoiceFileListController controller = new InvoiceFileListController();
        Test.stopTest();

        // Test that the invoice is there but no files
        System.assertEquals(invoice.Id, controller.invoice.Id, 'Invoice should be populated');
        System.assertEquals(0, controller.fileDetailsList.size(), 'Should have no job paperwork files');
        System.assertEquals(0, controller.invoiceFileDetailsList.size(), 'Should have no invoice files');
    }

    /****************** PRIVATE METHODS ***************/
    private static Map<Id, List<ContentDistribution>> createContentForJobs(List<Job__c> jobs) {

        // Create a map of the jobs by ID
        Map<Id, Job__c> jobsById = new Map<Id, Job__c>(jobs);

        // Create some content versions - only 1 per job to avoid SOQL limits
        Map<Id, List<ContentVersion>> contentVersionsByJobId = new Map<Id, List<ContentVersion>>();
        List<ContentVersion> allContentVersions = new List<ContentVersion>();
        for (Id jobId : jobsById.keySet()) {
            contentVersionsByJobId.put(jobId, new List<ContentVersion>());
            ContentVersion cv = createContentVersion('Example File for ' + jobId, 'This is just some random contents');
            contentVersionsByJobId.get(jobId).add(cv);
            allContentVersions.add(cv);
        }
        insert allContentVersions;

        // Get the IDs
        Set<Id> contentVersionIds = new Set<Id>();
        for (ContentVersion cv : allContentVersions) {
            contentVersionIds.add(cv.Id);
        }

        // Get the content document IDs for these versions
        Map<Id, Id> contentDocIdsByVersionId = new Map<Id, Id>();
        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:contentVersionIds]) {
            contentDocIdsByVersionId.put(cv.Id, cv.ContentDocumentId);
        }

        // Loop through the content versions and create links to the job and also content distribution records
        List<ContentDistribution> allContentDistributions = new List<ContentDistribution>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (Id jobId : contentVersionsByJobId.keySet()) {
            // Step through the content versions for this job Id
            for (ContentVersion cv : contentVersionsByJobId.get(jobId)) {
                // Get the content document Id
                Id contentDocId = contentDocIdsByVersionId.get(cv.Id);

                // Create the link to the document
                ContentDocumentLink cdl = createContentDocumentLink(contentDocId, jobId);
                contentDocumentLinks.add(cdl);

                // Create the content distribution record
                ContentDistribution conDist = createContentDistribution(cv.Title, cv.Id, jobId);
                allContentDistributions.add(conDist);

            }

        }

        // Insert the records
        insert contentDocumentLinks;
        insert allContentDistributions;

        System.debug(contentDocumentLinks.size());
        System.debug(allContentDistributions.size());

        // Get the IDs of the content distributions
        Set<Id> contentDistributionIds = new Set<Id>();
        for (ContentDistribution conDist : allContentDistributions) {
            contentDistributionIds.add(conDist.Id);
        }

        // Get the created content distributions and add them to a map
        Map<Id, List<ContentDistribution>> contentDistsByJobId = new Map<Id, List<ContentDistribution>>();
        for (ContentDistribution conDist : [SELECT Id, DistributionPublicUrl, RelatedRecordId FROM ContentDistribution WHERE Id IN:contentDistributionIds]) {
            if (contentDistsByJobId.containsKey(conDist.RelatedRecordId) == false) {contentDistsByJobId.put(conDist.RelatedRecordId, new List<ContentDistribution>());}
            contentDistsByJobId.get(conDist.RelatedRecordId).add(conDist);
        }

        // Return the map
        return contentDistsByJobId;

    }

    private static ContentVersion createContentVersion(String name, String contents) {
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.PathOnClient = name;
        cv.Origin = 'C';
        cv.Title = name;
        cv.VersionData = Blob.valueOf(contents);
        return cv;
    }

    private static ContentDocumentLink createContentDocumentLink(Id contentDocId, Id relatedRecordId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocId;
        cdl.LinkedEntityId = relatedRecordId;
        cdl.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cdl.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
        return cdl;
    }

    private static ContentDistribution createContentDistribution(String name, Id contentVersionId, Id relatedRecordId) {
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersionId;
        newDist.Name = name;
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload = true;
        newDist.RelatedRecordId = relatedRecordId;
        return newDist;
    }


}