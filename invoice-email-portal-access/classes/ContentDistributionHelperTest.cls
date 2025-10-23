@isTest
public class ContentDistributionHelperTest {
    public static testmethod void testContentDistributionHelper(){
        //Create Document Parent Record
        Account acc = new Account(Name='Test Account');
        Insert acc; 
        
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'ADOC-';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv; 
        
        
        // Create a supplier
        Account supplier = TestFactory.createSupplier('Vendor 1');
        insert supplier;
        
        // Create some clients
        Map<String, Account> clientsByRef = new Map<String, Account>();
        clientsByRef.put('C1', TestFactory.createClient('Company 1'));
        clientsByRef.put('C2', TestFactory.createClient('Company 2'));
        clientsByRef.put('C3', TestFactory.createClient('Company 3'));
        clientsByRef.put('C4', TestFactory.createClient('Company 4'));
        insert clientsByRef.values(); 
        // Create an order
        Order ord = TestFactory.createOrder('Order 1',supplier.Id);
        insert ord;
        
        // Create a product
        Product2 prod = TestFactory.createProduct('Test Product');
        insert prod;
        
        // Create a price book entry
        PricebookEntry pbe = TestFactory.createPricebookEntry(prod.Id,Test.getStandardPricebookId(),123.45);
        insert pbe;
        
        Depot__c depotDisposeRec = new Depot__c(
            Name = 'Test Depot',
            Permit_Reference__c = 'MN3456OP'
        );
        insert depotDisposeRec;
        
        // Create an order line
        OrderItem orderProduct = TestFactory.createOrderProduct(ord.Id,supplier.Id,prod.Id,pbe.Id, 200,250, 100, 15, 20);
        orderProduct.Depot_Dispose__c = depotDisposeRec.Id;
        insert orderProduct;
        
        Schedule__c scheduleRec = new Schedule__c();
        insert scheduleRec;
        
        // Create some jobs
        Map<String, Job__c> jobsByRef = new Map<String, Job__c>();
        jobsByRef.put('J1',TestFactory.createJob(clientsByRef.get('C1').Id,'Open','Fixed', orderProduct.Id, supplier.Id,System.today(),'1234'));
        jobsByRef.get('J1').Schedule__c = scheduleRec.Id;
        insert jobsByRef.values();
        
        
        //Create Document
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'Test Document';
        cv1.PathOnClient = 'TestDocument.pdf';
        cv1.VersionData = Blob.valueOf('Test Content');
        cv1.Document__c = 'Waste Transfer Note';
        cv1.IsMajorVersion = true;
        Insert cv1; 
        
        FileController.createContentDocLink(cv1.Id,jobsByRef.get('J1').Id,true);
        
        //Create Document
        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'Test Document';
        cv2.PathOnClient = 'TestDocument.pdf';
        cv2.VersionData = Blob.valueOf('Test Content');
        cv2.Document__c = 'Annual Duty of Care';
        cv2.IsMajorVersion = true;
        Insert cv2; 
        
        FileController.createContentDocLink(cv2.Id,jobsByRef.get('J1').Id,true);
        
        Map<Id,Job__c> jobMap = new Map<Id,Job__c>();
        for(Job__c jobRec :jobsByRef.values()){
            jobRec.DOC_uploaded__c = true;
            jobRec.Required_Paperwork__c = 'ADOC;WTN';
            jobRec.Waste_Transfer_Note_Uploaded__c = true;
            jobRec.DOC_ContentDistribution_Id__c = null;
            jobRec.WTN_ContentDistribution_Id__c = null;
            jobMap.put(jobRec.Id, jobRec);
        }
        update jobMap.values();
    }

    public static testmethod void testInvoiceContentDistributionHelper(){
        // Create test account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Create a test invoice (Name is auto-number, can't be set)
        Invoice__c invoice = new Invoice__c(Account__c = acc.Id);
        insert invoice;

        // Create a PDF document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Invoice - TEST-INV-001.pdf';
        cv.PathOnClient = 'Invoice.pdf';
        cv.VersionData = Blob.valueOf('Test Invoice PDF Content');
        cv.IsMajorVersion = true;
        insert cv;

        // Link the PDF to the invoice
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = invoice.Id;
        cdl.ContentDocumentId = insertedCV.ContentDocumentId;
        cdl.ShareType = 'V';
        insert cdl;

        // Call the ContentDistributionHelper method
        Test.startTest();
        ContentDistributionHelper.manageInvoiceContentDistribution(new Set<Id>{invoice.Id});
        Test.stopTest();

        // Verify ContentDistribution was created
        List<ContentDistribution> distributions = [
            SELECT Id, ContentVersionId, Name
            FROM ContentDistribution
            WHERE ContentVersionId = :cv.Id
        ];

        System.assertEquals(1, distributions.size(), 'Should create one ContentDistribution');
        System.assertEquals('Invoice - TEST-INV-001.pdf', distributions[0].Name, 'ContentDistribution name should match the PDF title');

        // Test that it doesn't create duplicates
        ContentDistributionHelper.manageInvoiceContentDistribution(new Set<Id>{invoice.Id});
        distributions = [
            SELECT Id
            FROM ContentDistribution
            WHERE ContentVersionId = :cv.Id
        ];
        System.assertEquals(1, distributions.size(), 'Should not create duplicate ContentDistribution');
    }
}