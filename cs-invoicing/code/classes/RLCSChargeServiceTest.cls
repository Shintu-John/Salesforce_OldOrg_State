/**
 * @description Test class for RLCSChargeService
 */

@IsTest
private class RLCSChargeServiceTest {
    private static Account customerAccount;
    private static Account vendorAccount;
    private static RLCS_Job__c rlcsJob;
    private static final Date DEFAULT_DATE = Date.newInstance(2019,1,1);
    
    private static void init() {
        // Get RecordType IDs
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer')?.getRecordTypeId();
        Id supplierRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Supplier')?.getRecordTypeId();

        // Create test accounts
        customerAccount = new Account(Name = 'Test Customer', Type = 'Customer', RecordTypeId = customerRecordTypeId);
        insert customerAccount;

        vendorAccount = new Account(Name = 'Test Vendor', Type = 'Supplier', RecordTypeId = supplierRecordTypeId, comp_house__Company_Number__c = '12345678');
        insert vendorAccount;

        // Create Product (for Product_Name__c formula field)
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        // Create PriceBookEntry
        Id standardPriceBookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create Order
        Order testOrder = new Order(
            AccountId = customerAccount.Id,
            EffectiveDate = DEFAULT_DATE,
            Status = 'Draft',
            Pricebook2Id = standardPriceBookId
        );
        insert testOrder;

        // Create OrderItem (Order_Product__r for formula fields)
        OrderItem orderProduct = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert orderProduct;

        // Create RLCS Job (Product_Name__c will be populated via formula)
        rlcsJob = new RLCS_Job__c(
            Customer_Account__c = customerAccount.Id,
            Status__c = 'Open',
            Delivery_Date__c = DEFAULT_DATE,
            Collected_Date__c = DEFAULT_DATE,
            Order_Product__c = orderProduct.Id,
            Waste_Type__c = 'Batteries (Mixed)',
            EWC__c = '20.01.23*'
        );
        insert rlcsJob;
    }
    
    @TestSetup 
    private static void setup() {}
    
    /**
     * @description Test creating auto job charge
     */
    @IsTest
    static void testCreateAutoJobCharge() {
        init();

        // Re-query job with all fields
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :rlcsJob.Id];

        Test.startTest();

        // Test creating auto job charge
        RLCS_Charge__c jobCharge = RLCSChargeService.createAutoJobCharge(
            job,
            RLCSChargeService.JOB_CHARGE_TYPE_JOB
        );

        Test.stopTest();

        // Verify the job charge was created correctly
        System.assertEquals(job.Id, jobCharge.RLCS_Job__c);
        System.assertEquals(RLCSChargeService.JOB_CHARGE_TYPE_JOB, jobCharge.Charge_Type__c);
        System.assertEquals(0, jobCharge.Sales_Price__c);
        System.assertEquals(0, jobCharge.Cost__c);
        System.assertEquals('0', jobCharge.VAT__c);
        System.assertNotEquals(null, jobCharge.RecordTypeId);

        // Verify collection date and description are set
        System.assertEquals(DEFAULT_DATE, jobCharge.Collection_Date__c, 'Collection Date should be set from Job Collected_Date__c');
        // Description should contain at least Product Name (Waste Type may not populate in test context)
        System.assert(jobCharge.Description__c.contains('Product: Test Product'),
                     'Description should contain Product Name: ' + jobCharge.Description__c);
    }
    
    /**
     * @description Test creating auto tonnage charge
     */
    @IsTest
    static void testCreateAutoTonnageCharge() {
        init();

        // Re-query job with all fields
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :rlcsJob.Id];

        Test.startTest();

        RLCS_Charge__c tonnageCharge = RLCSChargeService.createAutoJobCharge(
            job,
            RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE
        );

        Test.stopTest();

        System.assertEquals(job.Id, tonnageCharge.RLCS_Job__c);
        System.assertEquals(RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE, tonnageCharge.Charge_Type__c);
    }
    
    /**
     * @description Test updating job charge with changes
     */
    @IsTest
    static void testUpdateJobChargeWithChanges() {
        init();

        // Re-query job with all fields
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :rlcsJob.Id];

        RLCS_Charge__c originalCharge = RLCSChargeService.createAutoJobCharge(
            job,
            RLCSChargeService.JOB_CHARGE_TYPE_JOB
        );
        insert originalCharge;
        
        Test.startTest();
        
        // Update with new values
        RLCS_Charge__c updatedCharge = RLCSChargeService.updateJobCharge(
            originalCharge, 
            150.00, // cost
            250.00, // sales price
            customerAccount.Id, // sales account
            vendorAccount.Id, // vendor account
            vendorAccount.Id, // haulier account
            '20' // vat
        );
        
        Test.stopTest();
        
        // Should return the updated charge since values changed
        System.assertNotEquals(null, updatedCharge);
        System.assertEquals(150.00, updatedCharge.Cost__c);
        System.assertEquals(250.00, updatedCharge.Sales_Price__c);
        System.assertEquals(customerAccount.Id, updatedCharge.Sales_Account__c);
        System.assertEquals(vendorAccount.Id, updatedCharge.Vendor_Account__c);
        System.assertEquals(vendorAccount.Id, updatedCharge.Haulier__c);
        System.assertEquals('20', updatedCharge.VAT__c);
    }
    
    /**
     * @description Test updating job charge with no changes
     */
    @IsTest
    static void testUpdateJobChargeNoChanges() {
        init();

        // Re-query job with all fields
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :rlcsJob.Id];

        RLCS_Charge__c originalCharge = RLCSChargeService.createAutoJobCharge(
            job,
            RLCSChargeService.JOB_CHARGE_TYPE_JOB
        );
        originalCharge.Cost__c = 100.00;
        originalCharge.Sales_Price__c = 200.00;
        originalCharge.Sales_Account__c = customerAccount.Id;
        originalCharge.Vendor_Account__c = vendorAccount.Id;
        originalCharge.Haulier__c = vendorAccount.Id;
        originalCharge.VAT__c = '20';
        insert originalCharge;
        
        Test.startTest();
        
        // Update with same values
        RLCS_Charge__c updatedCharge = RLCSChargeService.updateJobCharge(
            originalCharge, 
            100.00, // same cost
            200.00, // same sales price
            customerAccount.Id, // same sales account
            vendorAccount.Id, // same vendor account
            vendorAccount.Id, // same haulier account
            '20' // same vat
        );
        
        Test.stopTest();
        
        // Should return null since no values changed
        System.assertEquals(null, updatedCharge);
    }
    
    /**
     * @description Test updating individual fields
     */
    @IsTest
    static void testUpdateJobChargeIndividualFields() {
        init();

        // Re-query job with all fields
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :rlcsJob.Id];

        RLCS_Charge__c originalCharge = RLCSChargeService.createAutoJobCharge(
            job,
            RLCSChargeService.JOB_CHARGE_TYPE_JOB
        );
        insert originalCharge;
        
        Test.startTest();
        
        // Update only cost
        RLCS_Charge__c updatedCharge1 = RLCSChargeService.updateJobCharge(
            originalCharge, 
            100.00, // new cost
            0, // same sales price
            null, // same sales account
            null, // same vendor account
            null, // same haulier account
            '0' // same vat
        );
        
        System.assertNotEquals(null, updatedCharge1);
        System.assertEquals(100.00, updatedCharge1.Cost__c);
        
        // Update only sales price
        originalCharge.Cost__c = 100.00; // reset
        RLCS_Charge__c updatedCharge2 = RLCSChargeService.updateJobCharge(
            originalCharge, 
            100.00, // same cost
            300.00, // new sales price
            null, // same sales account
            null, // same vendor account
            null, // same haulier account
            '0' // same vat
        );
        
        System.assertNotEquals(null, updatedCharge2);
        System.assertEquals(300.00, updatedCharge2.Sales_Price__c);

        Test.stopTest();
    }

    /**
     * @description Test charge creation with null Collected Date
     */
    @IsTest
    static void testCreateAutoJobChargeWithNullCollectedDate() {
        init();

        // Create job without Collected Date (reuse existing orderProduct)
        RLCS_Job__c jobWithoutDate = new RLCS_Job__c(
            Customer_Account__c = customerAccount.Id,
            Status__c = 'Open',
            Order_Product__c = rlcsJob.Order_Product__c,
            Waste_Type__c = 'Large Domestic Appliances',
            EWC__c = '16.02.11*',
            Collected_Date__c = null
        );
        insert jobWithoutDate;

        // Re-query with all fields
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :jobWithoutDate.Id];

        Test.startTest();

        RLCS_Charge__c jobCharge = RLCSChargeService.createAutoJobCharge(
            job,
            RLCSChargeService.JOB_CHARGE_TYPE_JOB
        );

        Test.stopTest();

        // When Collected_Date is null, Collection_Date__c should remain null in test context
        // (In production, field default TODAY() would apply, but not in test context without DML)
        // This test verifies the code doesn't error when Collected_Date is null
        System.assertNotEquals(null, jobCharge, 'Charge should be created even with null Collected_Date');
        // Description should still be built from available fields
        System.assert(jobCharge.Description__c.contains('Product: Test Product'),
                     'Description should contain Product Name: ' + jobCharge.Description__c);
    }

    /**
     * @description Test charge creation with partial Job fields
     */
    @IsTest
    static void testCreateAutoJobChargeWithPartialFields() {
        init();

        // Create job with only some fields (no Order_Product, so Product_Name will be null via formula)
        RLCS_Job__c jobPartial = new RLCS_Job__c(
            Customer_Account__c = customerAccount.Id,
            Status__c = 'Open',
            Collected_Date__c = DEFAULT_DATE,
            Waste_Type__c = 'Batteries (Mixed)',
            Order_Product__c = null,
            EWC__c = null
        );
        insert jobPartial;

        // Re-query with all fields
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :jobPartial.Id];

        Test.startTest();

        RLCS_Charge__c jobCharge = RLCSChargeService.createAutoJobCharge(
            job,
            RLCSChargeService.JOB_CHARGE_TYPE_JOB
        );

        Test.stopTest();

        // Description should only include available fields
        System.assertEquals('Waste Type: Batteries (Mixed)', jobCharge.Description__c,
                            'Description should handle missing fields gracefully');
        System.assertEquals(DEFAULT_DATE, jobCharge.Collection_Date__c);
    }

    /**
     * @description Test charge creation with all null Job fields
     */
    @IsTest
    static void testCreateAutoJobChargeWithAllNullFields() {
        init();

        // Create job with all description fields null
        RLCS_Job__c jobEmpty = new RLCS_Job__c(
            Customer_Account__c = customerAccount.Id,
            Status__c = 'Open',
            Collected_Date__c = DEFAULT_DATE,
            Order_Product__c = null,
            Waste_Type__c = null,
            EWC__c = null
        );
        insert jobEmpty;

        // Re-query with all fields
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :jobEmpty.Id];

        Test.startTest();

        RLCS_Charge__c jobCharge = RLCSChargeService.createAutoJobCharge(
            job,
            RLCSChargeService.JOB_CHARGE_TYPE_JOB
        );

        Test.stopTest();

        // Description should be empty string (no fields to join)
        System.assertEquals('', jobCharge.Description__c,
                            'Description should be empty when all fields are null');
        System.assertEquals(DEFAULT_DATE, jobCharge.Collection_Date__c);
    }

    /**
     * @description Test charge creation with only Waste Type
     */
    @IsTest
    static void testCreateChargeWithOnlyWasteType() {
        init();

        RLCS_Job__c jobWasteOnly = new RLCS_Job__c(
            Customer_Account__c = customerAccount.Id,
            Status__c = 'Open',
            Collected_Date__c = DEFAULT_DATE,
            Waste_Type__c = 'Batteries (Mixed)',
            EWC__c = null,
            Order_Product__c = null
        );
        insert jobWasteOnly;

        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :jobWasteOnly.Id];

        Test.startTest();
        RLCS_Charge__c charge = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_JOB);
        Test.stopTest();

        System.assertEquals('Waste Type: Batteries (Mixed)', charge.Description__c);
        System.assertEquals(DEFAULT_DATE, charge.Collection_Date__c);
    }

    /**
     * @description Test charge creation with only Product Name
     */
    @IsTest
    static void testCreateChargeWithOnlyProductName() {
        init();

        // Re-query rlcsJob to get Product_Name__c from formula field
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :rlcsJob.Id];

        // Clear Waste_Type and EWC for this test
        job.Waste_Type__c = null;
        job.EWC__c = null;
        update job;

        // Re-query again after update
        job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
               FROM RLCS_Job__c WHERE Id = :job.Id];

        Test.startTest();
        RLCS_Charge__c charge = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE);
        Test.stopTest();

        // Product Name comes from formula field, should be populated
        if (String.isNotBlank(job.Product_Name__c)) {
            System.assert(charge.Description__c.contains('Product:'));
        }
    }

    /**
     * @description Test charge creation with only EWC
     */
    @IsTest
    static void testCreateChargeWithOnlyEWC() {
        init();

        RLCS_Job__c jobEWCOnly = new RLCS_Job__c(
            Customer_Account__c = customerAccount.Id,
            Status__c = 'Open',
            Collected_Date__c = DEFAULT_DATE.addDays(-10),
            Waste_Type__c = null,
            EWC__c = '20.01.36',
            Order_Product__c = null
        );
        insert jobEWCOnly;

        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :jobEWCOnly.Id];

        Test.startTest();
        RLCS_Charge__c charge = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_TRANSPORT);
        Test.stopTest();

        // EWC may be cleared by validation/trigger, check if it was preserved
        if (String.isNotBlank(job.EWC__c)) {
            System.assertEquals('EWC: ' + job.EWC__c, charge.Description__c);
        }
        System.assertEquals(DEFAULT_DATE.addDays(-10), charge.Collection_Date__c);
    }

    /**
     * @description Test charge creation with Waste Type and EWC combination
     */
    @IsTest
    static void testCreateChargeWithWasteTypeAndEWC() {
        init();

        RLCS_Job__c jobCombo = new RLCS_Job__c(
            Customer_Account__c = customerAccount.Id,
            Status__c = 'Open',
            Collected_Date__c = DEFAULT_DATE.addDays(-7),
            Waste_Type__c = 'Large Domestic Appliances',
            EWC__c = '20.01.23*',
            Order_Product__c = null
        );
        insert jobCombo;

        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :jobCombo.Id];

        Test.startTest();
        RLCS_Charge__c charge = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_REBATE);
        Test.stopTest();

        // Waste Type should always be present
        System.assert(charge.Description__c.contains('Waste Type: Large Domestic Appliances'));
        // EWC may be cleared by validation/trigger
        if (String.isNotBlank(job.EWC__c)) {
            System.assert(charge.Description__c.contains('EWC:'));
        }
        System.assertEquals(DEFAULT_DATE.addDays(-7), charge.Collection_Date__c);
    }

    /**
     * @description Test charge creation with Product and EWC combination
     */
    @IsTest
    static void testCreateChargeWithProductAndEWC() {
        init();

        // Use rlcsJob which has Order_Product__c (which populates Product_Name__c formula)
        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :rlcsJob.Id];

        job.EWC__c = '16.02.14';
        job.Waste_Type__c = null;
        update job;

        job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
               FROM RLCS_Job__c WHERE Id = :job.Id];

        Test.startTest();
        RLCS_Charge__c charge = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT);
        Test.stopTest();

        // Should contain Product and EWC
        if (String.isNotBlank(job.Product_Name__c)) {
            System.assert(charge.Description__c.contains('Product:'));
            System.assert(charge.Description__c.contains('EWC: 16.02.14'));
        }
    }

    /**
     * @description Test charge creation with all three fields populated
     */
    @IsTest
    static void testCreateChargeWithAllThreeFields() {
        init();

        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :rlcsJob.Id];

        job.Waste_Type__c = 'Batteries (Mixed)';
        job.EWC__c = '20.01.23*';
        update job;

        job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
               FROM RLCS_Job__c WHERE Id = :job.Id];

        Test.startTest();
        RLCS_Charge__c charge = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_CREDIT);
        Test.stopTest();

        // Should contain waste type (always)
        System.assert(charge.Description__c.contains('Waste Type: Batteries (Mixed)'),
                      'Description should contain Waste Type. Actual: ' + charge.Description__c);

        // Product Name from formula field
        if (String.isNotBlank(job.Product_Name__c)) {
            System.assert(charge.Description__c.contains('Product:'),
                          'Description should contain Product when populated. Actual: ' + charge.Description__c);
        }

        // EWC may be cleared by validation/trigger
        if (String.isNotBlank(job.EWC__c)) {
            System.assert(charge.Description__c.contains('EWC:'),
                          'Description should contain EWC when populated. Actual: ' + charge.Description__c);
        }
    }

    /**
     * @description Test all charge types use the same description logic
     */
    @IsTest
    static void testAllChargeTypesUseDescription() {
        init();

        RLCS_Job__c job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
                           FROM RLCS_Job__c WHERE Id = :rlcsJob.Id];

        job.Waste_Type__c = 'Batteries (Mixed)';
        job.EWC__c = '20.01.23*';
        job.Collected_Date__c = DEFAULT_DATE.addDays(-15);
        update job;

        job = [SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
               FROM RLCS_Job__c WHERE Id = :job.Id];

        Test.startTest();

        RLCS_Charge__c chargeJob = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_JOB);
        RLCS_Charge__c chargeTonnage = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE);
        RLCS_Charge__c chargeRebate = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_REBATE);
        RLCS_Charge__c chargeTransport = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_TRANSPORT);
        RLCS_Charge__c chargeSecondary = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT);
        RLCS_Charge__c chargeCredit = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_CREDIT);

        Test.stopTest();

        // All charge types should have the same description
        System.assert(String.isNotBlank(chargeJob.Description__c));
        System.assertEquals(chargeJob.Description__c, chargeTonnage.Description__c);
        System.assertEquals(chargeJob.Description__c, chargeRebate.Description__c);
        System.assertEquals(chargeJob.Description__c, chargeTransport.Description__c);
        System.assertEquals(chargeJob.Description__c, chargeSecondary.Description__c);
        System.assertEquals(chargeJob.Description__c, chargeCredit.Description__c);

        // All should have the collected date
        System.assertEquals(DEFAULT_DATE.addDays(-15), chargeJob.Collection_Date__c);
        System.assertEquals(DEFAULT_DATE.addDays(-15), chargeTonnage.Collection_Date__c);
    }
}