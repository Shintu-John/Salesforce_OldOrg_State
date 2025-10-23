@isTest
public class JobMissingScheduleEmailNotificationTest {
    @testSetup 
    static void setupData() {
        EmailTemplate e = new EmailTemplate (developerName = 'TestTemplate', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test'); // plus any other fields that you want to set
        insert e;
    }
    
    public static testmethod void testJobMissingScheduleEmailNotificationBatch(){
        // Create a client
        Account clientAcc = TestFactory.createClient('Building Co Ltd');
        insert clientAcc;
        
        // Create a supplier
        Account supplierAcc = TestFactory.createSupplier('Skips R Us');
        insert supplierAcc;
        
        // Create an order
        Order ord = TestFactory.createOrder('Order 1',supplierAcc.Id);
        insert ord;
        
        // Create a product
        Product2 prod = TestFactory.createProduct('Test Product');
        prod.May_Require_Schedule__c  = true;
        insert prod;
        
        // Create a price book entry
        PricebookEntry pbe = TestFactory.createPricebookEntry(prod.Id,Test.getStandardPricebookId(),123.45);
        insert pbe;
        
        Depot__c depotRec = new Depot__c(
            Name = 'Test Depot',
            Permit_Reference__c = 'ZA9012BC'
        );
        insert depotRec;
        
        // Create an order line
        OrderItem orderProduct = TestFactory.createOrderProduct(ord.Id,supplierAcc.Id,prod.Id,pbe.Id, 200,250, 100, 15, 20);
        orderProduct.Sales_Tonnage_incl__c = 1;
        orderProduct.Depot_Dispose__c = depotRec.Id;
        insert orderProduct;
        
        // Insert a job
        Job__c job = TestFactory.createJob(clientAcc.Id,'Open','Variable', orderProduct.Id);
        job.Partner_Tonnage_charge_thereafter__c = 15;
        job.Sales_Tonnage_charge_thereafter__c = 20;
        job.Supplier_Price__c = 443.21;
        job.Sales_Price__c = 300;
        job.Waste_Type_2__c = 'Clinical waste';
        job.Delivery_Date__c = System.today().addDays(-7); // Set delivery date to 7 days ago (past delivery)
        insert job;

        Test.startTest();
        Database.executebatch(new JobMissingScheduleEmailNotificationBatch(), 1);
        Test.stopTest();

        // Verify the reminder counter was incremented
        Job__c updatedJob = [SELECT Schedule_Not_Created_Warning__c FROM Job__c WHERE Id = :job.Id];
        System.assertNotEquals(null, updatedJob.Schedule_Not_Created_Warning__c, 'Reminder counter should be incremented');
    }

    public static testmethod void testSchedulableInterface(){
        Test.startTest();
        // Schedule the batch
        String cronExp = '0 0 9 ? * 2,3,4,5,6';
        String jobId = System.schedule('Test Schedule Reminder',
                                       cronExp,
                                       new JobMissingScheduleEmailNotificationBatch());
        Test.stopTest();

        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
    }
}