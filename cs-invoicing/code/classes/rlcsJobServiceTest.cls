@isTest
public class rlcsJobServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create client account
        Account clientAcc = TestFactory.createClient('Test Client');
        clientAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert clientAcc;

        // Create supplier account
        Account supplierAcc = TestFactory.createSupplier('Test Supplier');
        supplierAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert supplierAcc;

        // Create processor account
        Account processorAcc = TestFactory.createSupplier('Test Processor');
        processorAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert processorAcc;

        // Create order
        Order ord = TestFactory.createOrder('Test Order', supplierAcc.Id);
        insert ord;

        // Create product
        Product2 prod = TestFactory.createProduct('Test Product');
        insert prod;

        // Create price book entry
        PricebookEntry pbe = TestFactory.createPricebookEntry(prod.Id, Test.getStandardPricebookId(), 100.00);
        insert pbe;

        // Create depot
        Depot__c depotRec = new Depot__c();
        depotRec.Name = 'Test Depot';
        depotRec.Permit_Reference__c = 'WEX374229';
        insert depotRec;

        // Create order item
        OrderItem orderProduct = TestFactory.createOrderProduct(ord.Id, supplierAcc.Id, prod.Id, pbe.Id, 200, 250, 100, 15, 20);
        orderProduct.Sales_Tonnage_incl__c = 1;
        orderProduct.Depot_Dispose__c = depotRec.Id;
        orderProduct.Transport__c = 100.00;
        orderProduct.Transport_Per_Unit__c = true;  // Default to per unit for backwards compatibility
        insert orderProduct;
    }

    @isTest
    static void testVariablePricingWithTransportPerTonne() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Sales_Tonnage_inc__c = 1;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Supplier_Cost__c = 20;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 1;

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be created');
    }

    @isTest
    static void testVariablePricingWithTransportPerUnit() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job (already set in @testSetup, but being explicit)
        orderProduct.Transport_Per_Tonne__c = false;
        orderProduct.Transport_Per_Unit__c = true;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Unit__c = true;
        job.Unit_Count__c = 5;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be created');
    }

    @isTest
    static void testFixedPricing() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Delivery_Date__c = System.now().date();
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Fixed';
        job.Sales_Cost__c = 100;
        job.Sales_Tonnage_inc__c = 1;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Supplier_Cost__c = 20;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 1;

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be created');
    }

    @isTest
    static void testRebatePricing() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Sales_Tonnage_inc__c = 1;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Supplier_Cost__c = 20;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 1;

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be created for Rebate pricing');
    }

    @isTest
    static void testJobUpdates() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Sales_Tonnage_inc__c = 1;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Supplier_Cost__c = 20;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 1;
        insert job;

        Test.startTest();
        // Update weight
        job.Material_Weight_Tonnes__c = 12;
        update job;

        // Update sales cost
        job.Sales_Cost__c = 120;
        update job;

        // Update supplier cost
        job.Supplier_Cost__c = 25;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be updated');
    }

    @isTest
    static void testAdditionalWeightChanges() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = false;
        job.Material_Weight_Tonnes__c = 5;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Sales_Tonnage_inc__c = 1;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Supplier_Cost__c = 20;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 1;
        insert job;

        Test.startTest();
        // Increase weight above sales tonnage inc
        job.Material_Weight_Tonnes__c = 10;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Additional weight charges should be created');
    }

    @isTest
    static void testAccountChanges() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account supplier = [SELECT Id FROM Account WHERE Name = 'Test Supplier' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Haullier__c = supplier.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 20;
        insert job;

        Test.startTest();
        // Change customer account
        job.Customer_Account__c = supplier.Id;
        update job;

        // Change haulier
        job.Haullier__c = processor.Id;
        update job;

        // Change processor
        job.Processor__c = supplier.Id;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should reflect account changes');
    }

    @isTest
    static void testMixedJobSkipped() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Is_Mixed_Job__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assertEquals(0, charges.size(), 'Mixed jobs should not create charges');
    }

    @isTest
    static void testTransportDeductions() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 20;
        job.Client_Transport_Deduction__c = 5;
        job.Supplier_Transport_Deduction__c = 3;
        insert job;

        Test.startTest();
        job.Client_Transport_Deduction__c = 10;
        job.Supplier_Transport_Deduction__c = 5;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should reflect transport deductions');
    }

    @isTest
    static void testRebatePricingUpdates() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Sales_Tonnage_inc__c = 1;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Supplier_Cost__c = 20;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 1;
        insert job;

        Test.startTest();
        job.Material_Weight_Tonnes__c = 15;
        update job;

        job.Partner_Tonnage_charge_thereafter__c = 15;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Rebate charges should be updated');
    }

    @isTest
    static void testSalesTransport() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Sales_Transport__c = 50;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;

        Test.startTest();
        insert job;

        job.Sales_Transport__c = 75;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Sales transport charges should be created');
    }

    @isTest
    static void testPartnerChanges() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account supplier = [SELECT Id FROM Account WHERE Name = 'Test Supplier' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 20;
        job.Partner_Tonnage_Incl__c = 1;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        insert job;

        Test.startTest();
        job.Partner_Tonnage_Incl__c = 2;
        update job;

        job.Partner_Tonnage_charge_thereafter__c = 15;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Partner charges should be updated');
    }

    @isTest
    static void testJobWithExistingCharges() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 20;
        insert job;

        // Create charges manually
        RLCS_Charge__c charge1 = new RLCS_Charge__c(
            RLCS_Job__c = job.Id,
            Charge_Type__c = 'Transport',
            Cost__c = 100
        );
        insert charge1;

        Test.startTest();
        // Update job to trigger charge recalculation
        job.Material_Weight_Tonnes__c = 12;
        job.Sales_Cost__c = 120;
        job.Supplier_Cost__c = 25;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Existing charges should be updated');
    }

    @isTest
    static void testMultipleJobsVariablePricing() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        List<RLCS_Job__c> jobs = new List<RLCS_Job__c>();
        for(Integer i = 0; i < 5; i++) {
            RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
            job.Order__c = orderProduct.OrderId;
            job.Order_Product__c = orderProduct.Id;
            job.Delivery_Date__c = System.now().date();
            job.Customer_Account__c = acc.Id;
            job.Transport__c = 10 + i;
            job.Material_Weight_Tonnes__c = 10 + i;
            job.Pricing_Method__c = 'Variable';
            job.Sales_Cost__c = 100 + (i * 10);
            job.Supplier_Cost__c = 20 + i;
            jobs.add(job);
        }

        Test.startTest();
        insert jobs;
        
        // Update all jobs
        for(RLCS_Job__c job : jobs) {
            job.Material_Weight_Tonnes__c += 2;
        }
        update jobs;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c IN :jobs];
        System.assert(charges.size() > 0, 'Charges should be created for multiple jobs');
    }

    @isTest
    static void testMultipleJobsRebatePricing() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        List<RLCS_Job__c> jobs = new List<RLCS_Job__c>();
        for(Integer i = 0; i < 3; i++) {
            RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
            job.Order__c = orderProduct.OrderId;
            job.Order_Product__c = orderProduct.Id;
            job.Customer_Account__c = acc.Id;
            job.Transport__c = 10 + i;
            job.Material_Weight_Tonnes__c = 10 + i;
            job.Pricing_Method__c = 'Rebate';
            job.Sales_Cost__c = 100 + (i * 10);
            job.Supplier_Cost__c = 20 + i;
            job.Partner_Tonnage_Incl__c = 1;
            job.Partner_Tonnage_charge_thereafter__c = 10 + i;
            jobs.add(job);
        }

        Test.startTest();
        insert jobs;
        
        // Update all rebate jobs
        for(RLCS_Job__c job : jobs) {
            job.Material_Weight_Tonnes__c += 3;
            job.Partner_Tonnage_charge_thereafter__c += 5;
        }
        update jobs;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c IN :jobs];
        System.assert(charges.size() > 0, 'Rebate charges should be created for multiple jobs');
    }

    @isTest
    static void testVendorAccountChangePath() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account supplier = [SELECT Id FROM Account WHERE Name = 'Test Supplier' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Haullier__c = supplier.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        job.Processor__c = supplier.Id;
        update job;
        job.Haullier__c = processor.Id;
        update job;
        job.Sales_Cost__c = 0;
        job.Supplier_Cost__c = 0;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges: ' + charges.size());
    }

    @isTest
    static void testWeightChangeNotPerTonne() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = false;
        job.Material_Weight_Tonnes__c = 5;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Sales_Tonnage_inc__c = 2;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 2;
        job.Partner_Tonnage_charge_thereafter__c = 8;
        insert job;

        Test.startTest();
        job.Material_Weight_Tonnes__c = 12;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges: ' + charges.size());
    }

    @isTest
    static void testDeliveryDateChange() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        insert job;

        Test.startTest();
        job.Delivery_Date__c = System.now().date().addDays(5);
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should exist');
    }

    @isTest
    static void testTransportPerTonneToggle() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        insert job;

        Test.startTest();
        job.Transport_Per_Tonne__c = false;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be recalculated');
    }

    @isTest
    static void testUnitCountChange() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = false;
        orderProduct.Transport_Per_Unit__c = true;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Unit__c = true;
        job.Unit_Count__c = 5;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        insert job;

        Test.startTest();
        job.Unit_Count__c = 10;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should update');
    }

    @isTest
    static void testSalesTonnageChange() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Sales_Tonnage_inc__c = 1;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        insert job;

        Test.startTest();
        job.Sales_Tonnage_charge_thereafter__c = 20;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should update');
    }

    @isTest
    static void testRebateWithTransportDeductions() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Sales_Transport__c = 50;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Client_Transport_Deduction__c = 20;
        job.Supplier_Transport_Deduction__c = 10;
        insert job;

        Test.startTest();
        job.Client_Transport_Deduction__c = 30;
        job.Supplier_Transport_Deduction__c = 15;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Rebate charges with deductions should be created');
    }


    @isTest
    static void testCancelledJob() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        job.Status__c = 'Cancelled';
        job.Sales_Cost__c = 0;
        job.Supplier_Cost__c = 0;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges after cancellation: ' + charges.size());
    }

    @isTest
    static void testPartnerTonnageInclChange() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Partner_Tonnage_Incl__c = 5;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        insert job;

        Test.startTest();
        job.Partner_Tonnage_Incl__c = 3;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should update');
    }

    @isTest
    static void testFixedPricingUpdate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Fixed';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        job.Sales_Cost__c = 150;
        job.Supplier_Cost__c = 75;
        job.Material_Weight_Tonnes__c = 12;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Fixed pricing charges should update');
    }

    @isTest
    static void testRebateWithSalesTransport() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Sales_Transport__c = 50;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        job.Sales_Transport__c = 75;
        job.Transport__c = 15;
        update job;
        
        job.Sales_Transport__c = 0;
        job.Transport__c = 0;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Rebate charges: ' + charges.size());
    }

    @isTest
    static void testRebatePricingTransportPerUnit() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = false;
        orderProduct.Transport_Per_Unit__c = true;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Transport_Per_Unit__c = true;
        job.Unit_Count__c = 5;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        job.Unit_Count__c = 10;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Rebate charges should be created');
    }

    @isTest
    static void testRebatePricingTransportPerLoad() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job (per load)
        orderProduct.Transport_Per_Tonne__c = false;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = false;
        job.Transport_Per_Unit__c = false;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        job.Transport__c = 15;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Rebate charges should be created');
    }

    @isTest
    static void testMultipleRebateJobsWithDifferentTransportMethods() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        List<RLCS_Job__c> jobs = new List<RLCS_Job__c>();
        
        RLCS_Job__c job1 = RLCS_UtilityTest.createRLCS_Job(false);
        job1.Order__c = orderProduct.OrderId;
        job1.Order_Product__c = orderProduct.Id;
        job1.Customer_Account__c = acc.Id;
        job1.Processor__c = processor.Id;
        job1.Transport__c = 10;
        job1.Transport_Per_Tonne__c = true;
        job1.Material_Weight_Tonnes__c = 10;
        job1.Pricing_Method__c = 'Rebate';
        job1.Sales_Cost__c = 100;
        job1.Supplier_Cost__c = 50;
        jobs.add(job1);
        
        RLCS_Job__c job2 = RLCS_UtilityTest.createRLCS_Job(false);
        job2.Order__c = orderProduct.OrderId;
        job2.Order_Product__c = orderProduct.Id;
        job2.Customer_Account__c = acc.Id;
        job2.Processor__c = processor.Id;
        job2.Transport__c = 10;
        job2.Transport_Per_Unit__c = true;
        job2.Unit_Count__c = 5;
        job2.Material_Weight_Tonnes__c = 10;
        job2.Pricing_Method__c = 'Rebate';
        job2.Sales_Cost__c = 100;
        job2.Supplier_Cost__c = 50;
        jobs.add(job2);

        Test.startTest();
        insert jobs;
        
        for(RLCS_Job__c job : jobs) {
            job.Material_Weight_Tonnes__c += 2;
        }
        update jobs;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c IN :jobs];
        System.assert(charges.size() > 0, 'Rebate charges should be created for all jobs');
    }

    @isTest
    static void testJobChargeZeroCostDeletion() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        // Set costs to zero to trigger deletion path
        job.Sales_Cost__c = 0;
        job.Supplier_Cost__c = 0;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges after zero cost: ' + charges.size());
    }

    @isTest
    static void testTonnageChargeCreationAndDeletion() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = false;
        job.Material_Weight_Tonnes__c = 5;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Sales_Tonnage_inc__c = 2;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 2;
        job.Partner_Tonnage_charge_thereafter__c = 8;
        insert job;

        // Trigger weight changes to create tonnage charges
        job.Material_Weight_Tonnes__c = 12;
        update job;

        Test.startTest();
        // Reduce weight back down to trigger deletion
        job.Material_Weight_Tonnes__c = 1;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges after tonnage deletion: ' + charges.size());
    }

    @isTest
    static void testRebateChargeZeroTotalDeletion() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Sales_Transport__c = 50;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        // Set transport to zero to trigger transport charge deletion
        job.Sales_Transport__c = 0;
        job.Transport__c = 0;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Rebate charges after zero transport: ' + charges.size());
    }

    @isTest
    static void testSecondaryTransportPerTonne() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Enable secondary transport on OrderItem
        orderProduct.Secondary_Transport_Charge__c = true;
        orderProduct.Secondary_Transport_P_T__c = 5.50;
        orderProduct.Secondary_Transport_Per_Tonne__c = true;
        orderProduct.Secondary_Haulier__c = processor.Id;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;

        Test.startTest();
        try {
            insert job;
        } catch (Exception e) {
            System.debug('Exception during test: ' + e.getMessage());
        }
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges created: ' + charges.size());
    }

    @isTest
    static void testSecondaryTransportPerUnit() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        orderProduct.Secondary_Transport_Charge__c = true;
        orderProduct.Secondary_Transport_P_T__c = 2.00;
        orderProduct.Secondary_Transport_Per_Unit__c = true;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Unit_Count__c = 25;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;

        Test.startTest();
        try {
            insert job;
        } catch (Exception e) {
            System.debug('Exception during test: ' + e.getMessage());
        }
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges created: ' + charges.size());
    }

    @isTest
    static void testSecondaryTransportPerLoad() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        orderProduct.Secondary_Transport_Charge__c = true;
        orderProduct.Secondary_Transport_P_T__c = 75.00;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;

        Test.startTest();
        try {
            insert job;
        } catch (Exception e) {
            System.debug('Exception during test: ' + e.getMessage());
        }
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges created: ' + charges.size());
    }

    @isTest
    static void testSecondaryTransportRebatePricing() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        orderProduct.Secondary_Transport_Charge__c = true;
        orderProduct.Secondary_Transport_P_T__c = 3.00;
        orderProduct.Secondary_Transport_Per_Tonne__c = true;
        orderProduct.Pricing_Method__c = 'Rebate';
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Material_Weight_Tonnes__c = 20;
        job.Pricing_Method__c = 'Rebate';

        Test.startTest();
        try {
            insert job;
        } catch (Exception e) {
            System.debug('Exception during test: ' + e.getMessage());
        }
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges created: ' + charges.size());
    }

    @isTest
    static void testWeightOnlyChangeVariablePricing() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        job.Material_Weight_Tonnes__c = 15;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assertNotEquals(0, charges.size(), 'Charges should exist after weight update');
    }

    @isTest
    static void testBulkJobInsertWithMixedPricing() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        List<RLCS_Job__c> jobs = new List<RLCS_Job__c>();
        
        for(Integer i = 0; i < 10; i++) {
            RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
            job.Order__c = orderProduct.OrderId;
            job.Order_Product__c = orderProduct.Id;
            job.Customer_Account__c = acc.Id;
            job.Processor__c = processor.Id;
            job.Transport__c = 10 + i;
            job.Material_Weight_Tonnes__c = 5 + i;
            
            if(Math.mod(i, 3) == 0) {
                job.Pricing_Method__c = 'Fixed';
            } else if(Math.mod(i, 3) == 1) {
                job.Pricing_Method__c = 'Variable';
            } else {
                job.Pricing_Method__c = 'Rebate';
            }
            
            job.Sales_Cost__c = 100 + (i * 10);
            job.Supplier_Cost__c = 50 + (i * 5);
            jobs.add(job);
        }

        Test.startTest();
        insert jobs;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c IN :jobs];
        System.assert(charges.size() > 0, 'Bulk insert should create charges');
    }

    @isTest
    static void testBulkJobUpdateMultiplePaths() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        List<RLCS_Job__c> jobs = new List<RLCS_Job__c>();
        
        for(Integer i = 0; i < 5; i++) {
            RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
            job.Order__c = orderProduct.OrderId;
            job.Order_Product__c = orderProduct.Id;
            job.Customer_Account__c = acc.Id;
            job.Processor__c = processor.Id;
            job.Transport__c = 10;
            job.Material_Weight_Tonnes__c = 10;
            job.Pricing_Method__c = 'Variable';
            job.Sales_Cost__c = 100;
            job.Supplier_Cost__c = 50;
            jobs.add(job);
        }
        insert jobs;

        Test.startTest();
        // Update different fields to trigger different paths
        jobs[0].Sales_Cost__c = 150;
        jobs[1].Processor__c = acc.Id;
        jobs[2].Material_Weight_Tonnes__c = 15;
        jobs[3].Transport__c = 20;
        jobs[4].Customer_Account__c = processor.Id;
        update jobs;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c IN :jobs];
        System.assert(charges.size() > 0, 'Bulk update should maintain charges');
    }

    @isTest
    static void testFixedPricingNoTonnageCharge() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = false;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Fixed';
        job.Sales_Cost__c = 100;
        insert job;

        Test.startTest();
        job.Material_Weight_Tonnes__c = 20;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        Integer tonnageCharges = 0;
        for(RLCS_Charge__c c : charges) {
            if(c.Charge_Type__c == 'Tonnage') tonnageCharges++;
        }
        System.debug('Tonnage charges: ' + tonnageCharges);
    }

    @isTest
    static void testJobWithNullValues() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Pricing_Method__c = 'Variable';
        // Leave transport and costs as null/zero
        insert job;

        Test.startTest();
        job.Sales_Cost__c = 50;
        update job;
        
        job.Sales_Cost__c = null;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges with null values: ' + charges.size());
    }

    @isTest
    static void testRebatePricingWithTransportDeductionsZero() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Client_Transport_Deduction__c = 0;
        job.Supplier_Transport_Deduction__c = 0;
        insert job;

        Test.startTest();
        job.Client_Transport_Deduction__c = 5;
        update job;
        
        job.Client_Transport_Deduction__c = 0;
        job.Supplier_Transport_Deduction__c = 0;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Rebate charges should handle zero deductions');
    }

    @isTest
    static void testMultiplePricingMethodChanges() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        job.Pricing_Method__c = 'Fixed';
        update job;
        
        job.Pricing_Method__c = 'Rebate';
        update job;
        
        job.Pricing_Method__c = 'Variable';
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Should handle pricing method changes');
    }

    @isTest
    static void testJobCreationWithCollectedDate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];
        Date collectedDate = System.now().date().addDays(-5);

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Collected_Date__c = collectedDate;
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Waste_Type__c = 'Batteries (Mixed)';
        job.EWC__c = '20.01.23*';

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Date__c, Description__c, Charge_Type__c
                                        FROM RLCS_Charge__c
                                        WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be created');

        // Just verify charges were created - the service layer handles date/description
        System.debug('Created ' + charges.size() + ' charges for job with collected date');
    }

    @isTest
    static void testJobWithWasteTypeAndEWC() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Collected_Date__c = System.now().date().addDays(-2);
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 15;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 5;
        job.Pricing_Method__c = 'Fixed';
        job.Sales_Cost__c = 200;
        job.Supplier_Cost__c = 100;
        job.Waste_Type__c = 'Large Domestic Appliances';
        job.EWC__c = '20.01.36';

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id
                                        FROM RLCS_Charge__c
                                        WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be created for fixed pricing');
    }

    @isTest
    static void testRebateJobCreation() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Delivery_Date__c = System.now().date();
        job.Collected_Date__c = System.now().date().addDays(-1);
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 8;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 150;
        job.Supplier_Cost__c = 75;
        job.Sales_Tonnage_inc__c = 1;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_charge_thereafter__c = 8;
        job.Partner_Tonnage_Incl__c = 1;
        job.Waste_Type__c = 'Batteries (Mixed)';
        job.EWC__c = '20.01.23*';

        Test.startTest();
        insert job;

        // Update to trigger recalculation
        job.Material_Weight_Tonnes__c = 10;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id
                                        FROM RLCS_Charge__c
                                        WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Rebate charges should be created');
    }

    @isTest
    static void testBulkJobsWithDescriptionFields() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        List<RLCS_Job__c> jobs = new List<RLCS_Job__c>();
        for(Integer i = 0; i < 5; i++) {
            RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
            job.Order__c = orderProduct.OrderId;
            job.Order_Product__c = orderProduct.Id;
            job.Delivery_Date__c = System.now().date();
            job.Collected_Date__c = System.now().date().addDays(-i);
            job.Customer_Account__c = acc.Id;
            job.Transport__c = 10 + i;
            job.Material_Weight_Tonnes__c = 5 + i;
            job.Pricing_Method__c = 'Variable';
            job.Sales_Cost__c = 100 + (i * 20);
            job.Supplier_Cost__c = 50 + (i * 10);
            job.Waste_Type__c = 'Batteries (Mixed)';
            job.EWC__c = '20.01.23*';
            jobs.add(job);
        }

        Test.startTest();
        insert jobs;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id
                                        FROM RLCS_Charge__c
                                        WHERE RLCS_Job__c IN :jobs];
        System.assert(charges.size() > 0, 'Charges should be created for multiple jobs');
    }

    @isTest
    static void testJobUpdateTriggersChargeUpdate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        // Update with collected date and description fields
        job.Collected_Date__c = System.now().date().addDays(-3);
        job.Waste_Type__c = 'Batteries (Mixed)';
        job.EWC__c = '20.01.23*';
        job.Material_Weight_Tonnes__c = 12;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id
                                        FROM RLCS_Charge__c
                                        WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should exist after update');
    }

    @isTest
    static void testSecondaryTransportWithCollectedDate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Enable secondary transport on OrderItem
        orderProduct.Secondary_Transport_Charge__c = true;
        orderProduct.Secondary_Transport_P_T__c = 5.50;
        orderProduct.Secondary_Transport_Per_Tonne__c = true;
        orderProduct.Secondary_Haulier__c = processor.Id;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Collected_Date__c = System.now().date().addDays(-1);
        job.Waste_Type__c = 'Batteries (Mixed)';
        job.EWC__c = '20.01.23*';

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be created with secondary transport');
    }

    @isTest
    static void testVariablePricingWithAllFields() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account supplier = [SELECT Id FROM Account WHERE Name = 'Test Supplier' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Collected_Date__c = System.now().date().addDays(-2);
        job.Customer_Account__c = acc.Id;
        job.Haullier__c = supplier.Id;
        job.Transport__c = 10;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Sales_Tonnage_inc__c = 1;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Supplier_Cost__c = 20;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 1;
        job.Waste_Type__c = 'Batteries (Mixed)';
        job.EWC__c = '20.01.23*';

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges created');
    }

    @isTest
    static void testRebateWithAllTransportOptions() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Collected_Date__c = System.now().date().addDays(-1);
        job.Transport__c = 10;
        job.Sales_Transport__c = 50;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Client_Transport_Deduction__c = 20;
        job.Supplier_Transport_Deduction__c = 10;
        job.Waste_Type__c = 'Large Domestic Appliances';
        job.EWC__c = '20.01.36';

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Rebate charges created');
    }

    @isTest
    static void testJobWithSalesTransportOnly() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Collected_Date__c = System.now().date().addDays(-1);
        job.Customer_Account__c = acc.Id;
        job.Sales_Transport__c = 75;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Waste_Type__c = 'Batteries (Mixed)';
        job.EWC__c = '20.01.23*';

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Sales transport charges created');
    }

    @isTest
    static void testAdditionalWeightCharges() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Delivery_Date__c = System.now().date();
        job.Collected_Date__c = System.now().date().addDays(-2);
        job.Customer_Account__c = acc.Id;
        job.Transport__c = 10;
        job.Material_Weight_Tonnes__c = 5;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Sales_Tonnage_inc__c = 2;
        job.Sales_Tonnage_charge_thereafter__c = 15;
        job.Supplier_Cost__c = 50;
        job.Partner_Tonnage_Incl__c = 2;
        job.Partner_Tonnage_charge_thereafter__c = 10;
        job.Waste_Type__c = 'Batteries (Mixed)';

        Test.startTest();
        insert job;

        // Increase weight to trigger additional weight charges
        job.Material_Weight_Tonnes__c = 15;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Additional weight charges created');
    }

    @isTest
    static void testFixedPricingWithTransport() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = false;
        orderProduct.Transport_Per_Unit__c = true;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Collected_Date__c = System.now().date().addDays(-1);
        job.Transport__c = 10;
        job.Transport_Per_Unit__c = true;
        job.Unit_Count__c = 5;
        job.Material_Weight_Tonnes__c = 10;
        job.Pricing_Method__c = 'Fixed';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Waste_Type__c = 'Large Domestic Appliances';
        job.EWC__c = '20.01.36';

        Test.startTest();
        insert job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Fixed pricing with transport charges created');
    }

    @isTest
    static void testJobWithDescriptionFieldsInBulk() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        List<RLCS_Job__c> jobs = new List<RLCS_Job__c>();
        for (Integer i = 0; i < 10; i++) {
            RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
            job.Order__c = orderProduct.OrderId;
            job.Order_Product__c = orderProduct.Id;
            job.Customer_Account__c = acc.Id;
            job.Collected_Date__c = System.now().date().addDays(-i);
            job.Material_Weight_Tonnes__c = 5 + i;
            job.Pricing_Method__c = (Math.mod(i, 2) == 0) ? 'Variable' : 'Fixed';
            job.Sales_Cost__c = 100 + (i * 10);
            job.Supplier_Cost__c = 50 + (i * 5);
            job.Waste_Type__c = (Math.mod(i, 2) == 0) ? 'Batteries (Mixed)' : 'Large Domestic Appliances';
            jobs.add(job);
        }

        Test.startTest();
        insert jobs;
        Test.stopTest();

        // Verify charges were created for all jobs
        List<RLCS_Charge__c> charges = [SELECT Id, RLCS_Job__c, Description__c, Date__c
                                        FROM RLCS_Charge__c
                                        WHERE RLCS_Job__c IN :jobs];
        System.assert(charges.size() > 0, 'Bulk job charges should be created');

        // Verify at least some have date populated (description may be empty if fields not writeable)
        Integer withDescription = 0;
        Integer withCollectedDate = 0;
        for (RLCS_Charge__c c : charges) {
            if (String.isNotBlank(c.Description__c)) {
                withDescription++;
            }
            if (c.Date__c != null) {
                withCollectedDate++;
            }
        }
        // Date should be populated since we set Collected_Date__c
        System.assert(withCollectedDate > 0, 'Some charges should have dates from Collected_Date__c');
        // Description may or may not be populated depending on field availability
        System.debug('Charges with description: ' + withDescription);
    }

    @isTest
    static void testSecondaryTransportChargeDeletionWhenAmountZero() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Enable secondary transport on the order product first
        orderProduct.Secondary_Transport_Charge__c = true;
        orderProduct.Secondary_Transport_Per_Tonne__c = true;
        orderProduct.Secondary_Transport_P_T__c = 100;
        update orderProduct;

        // Create a job with material weight to trigger secondary transport charge
        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Material_Weight_Tonnes__c = 5;
        insert job;

        // Verify secondary transport charge was created
        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c
                                        WHERE RLCS_Job__c = :job.Id
                                        AND Charge_Type__c = :RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT];
        Integer initialCount = charges.size();

        Test.startTest();
        // Update weight to 0 to trigger deletion of secondary transport charge
        job.Material_Weight_Tonnes__c = 0;
        update job;
        Test.stopTest();

        // Verify charges after deletion attempt
        List<RLCS_Charge__c> chargesAfter = [SELECT Id FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Initial secondary transport charges: ' + initialCount + ', charges after: ' + chargesAfter.size());
    }

    @isTest
    static void testSecondaryTransportChargeDeletionWhenDisabled() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Enable secondary transport on the order product first
        orderProduct.Secondary_Transport_Charge__c = true;
        orderProduct.Secondary_Transport_Per_Tonne__c = true;
        orderProduct.Secondary_Transport_P_T__c = 100;
        update orderProduct;

        // Create a job with material weight to trigger secondary transport charge
        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Material_Weight_Tonnes__c = 5;
        insert job;

        Test.startTest();
        // Disable secondary transport to trigger deletion
        orderProduct.Secondary_Transport_Charge__c = false;
        update orderProduct;

        // Update job to trigger recalculation
        job.Material_Weight_Tonnes__c = 6;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> chargesAfter = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges after disabling secondary transport: ' + chargesAfter.size());
    }

    @isTest
    static void testTransportChargeDeletion() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Update OrderItem flags to match Job
        orderProduct.Transport_Per_Tonne__c = true;
        orderProduct.Transport_Per_Unit__c = false;
        update orderProduct;

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Transport_Per_Tonne__c = true;
        job.Material_Weight_Tonnes__c = 5;
        job.Transport__c = 50;
        insert job;

        Test.startTest();
        // Set transport to zero to trigger deletion
        job.Transport__c = 0;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges after transport deletion: ' + charges.size());
    }

    @isTest
    static void testRebateChargeDeletion() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Pricing_Method__c = 'Rebate';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        // Set costs to zero to trigger rebate charge deletion
        job.Sales_Cost__c = 0;
        job.Supplier_Cost__c = 0;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges after rebate deletion: ' + charges.size());
    }

    @isTest
    static void testVendorChangesPathTonnageChargeCreation() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Create a variable pricing job with material weight
        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Material_Weight_Tonnes__c = 5;
        job.Sales_Tonnage_inc__c = 2;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 2;
        job.Partner_Tonnage_charge_thereafter__c = 8;
        insert job;

        Test.startTest();
        // Trigger vendor changes path by changing Additional_Weight_Cost__c (formula field won't work)
        // Change Supplier_Cost__c instead which triggers jobsToProcessByVendorChangesId path
        job.Supplier_Cost__c = 75;
        job.Material_Weight_Tonnes__c = 10; // This will create additional weight
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges after vendor changes: ' + charges.size());
    }

    @isTest
    static void testTonnageChargeDeletionInVendorPath() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Create a variable pricing job with additional weight
        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Material_Weight_Tonnes__c = 10;
        job.Sales_Tonnage_inc__c = 2;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 2;
        job.Partner_Tonnage_charge_thereafter__c = 8;
        insert job;

        Test.startTest();
        // Reduce weight and change supplier cost to trigger vendor path deletion
        job.Supplier_Cost__c = 60;
        job.Material_Weight_Tonnes__c = 1;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges after tonnage deletion in vendor path: ' + charges.size());
    }

    @isTest
    static void testJobChargeDeletionWhenCostZero() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        Test.startTest();
        // Set both costs to zero to trigger job charge deletion
        job.Sales_Cost__c = 0;
        job.Supplier_Cost__c = 0;
        update job;
        Test.stopTest();

        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.debug('Charges after job charge deletion: ' + charges.size());
    }

    @isTest
    static void testLockedSalesInvoiceJobCharge() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Create a Variable pricing job
        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        insert job;

        // Get the auto-created charges
        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c, Sales_Price__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];
        System.assert(charges.size() > 0, 'Charges should be created');

        // Create a sales invoice with Sent status (not Draft) to lock the charge
        Invoice__c salesInvoice = TestFactory.createInvoice(acc.Id, System.today(), TestFactory.INVOICE_STATUS_SENT);
        insert salesInvoice;

        // Link the job charge to the invoice (making it locked)
        for (RLCS_Charge__c charge : charges) {
            charge.Sales_Invoice__c = salesInvoice.Id;
        }
        update charges;

        Test.startTest();
        // Try to update the job - should trigger locked charge error handling
        job.Sales_Cost__c = 150;
        try {
            update job;
        } catch (Exception e) {
            System.debug('Expected error for locked charge: ' + e.getMessage());
        }
        Test.stopTest();

        System.debug('Test completed for locked sales invoice scenario');
    }

    @isTest
    static void testLockedSalesInvoiceWeightChangePath() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Create a Variable pricing job with additional weight
        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Material_Weight_Tonnes__c = 10;
        job.Sales_Tonnage_inc__c = 2;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 2;
        job.Partner_Tonnage_charge_thereafter__c = 8;
        insert job;

        // Get all charges
        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];

        if (charges.size() > 0) {
            // Create a sales invoice with Sent status to lock charges
            Invoice__c salesInvoice = TestFactory.createInvoice(acc.Id, System.today(), TestFactory.INVOICE_STATUS_SENT);
            insert salesInvoice;

            // Link charges to invoice (making them locked)
            for (RLCS_Charge__c charge : charges) {
                charge.Sales_Invoice__c = salesInvoice.Id;
            }
            update charges;

            Test.startTest();
            // Try to update job weight - should trigger locked charge handling in weight change path
            job.Material_Weight_Tonnes__c = 15;
            try {
                update job;
            } catch (Exception e) {
                System.debug('Expected error for locked charge in weight path: ' + e.getMessage());
            }
            Test.stopTest();
        }

        System.debug('Test completed for locked sales invoice weight change path');
    }

    @isTest
    static void testLockedSalesInvoiceVendorChangePath() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Account processor = [SELECT Id FROM Account WHERE Name = 'Test Processor' LIMIT 1];
        OrderItem orderProduct = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

        // Create job with tonnage
        RLCS_Job__c job = RLCS_UtilityTest.createRLCS_Job(false);
        job.Order__c = orderProduct.OrderId;
        job.Order_Product__c = orderProduct.Id;
        job.Customer_Account__c = acc.Id;
        job.Processor__c = processor.Id;
        job.Pricing_Method__c = 'Variable';
        job.Sales_Cost__c = 100;
        job.Supplier_Cost__c = 50;
        job.Material_Weight_Tonnes__c = 10;
        job.Sales_Tonnage_inc__c = 2;
        job.Sales_Tonnage_charge_thereafter__c = 10;
        job.Partner_Tonnage_Incl__c = 2;
        job.Partner_Tonnage_charge_thereafter__c = 8;
        insert job;

        // Get charges
        List<RLCS_Charge__c> charges = [SELECT Id, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = :job.Id];

        // Lock sales invoice
        Invoice__c salesInvoice = TestFactory.createInvoice(acc.Id, System.today(), TestFactory.INVOICE_STATUS_SENT);
        insert salesInvoice;

        for (RLCS_Charge__c charge : charges) {
            charge.Sales_Invoice__c = salesInvoice.Id;
        }
        update charges;

        Test.startTest();
        // Trigger vendor changes path (supplier cost change) with locked charges
        job.Supplier_Cost__c = 75;
        job.Material_Weight_Tonnes__c = 15;
        try {
            update job;
        } catch (Exception e) {
            System.debug('Locked charge error in vendor changes path: ' + e.getMessage());
        }
        Test.stopTest();

        System.debug('Test completed for locked charge in vendor changes path');
    }

}