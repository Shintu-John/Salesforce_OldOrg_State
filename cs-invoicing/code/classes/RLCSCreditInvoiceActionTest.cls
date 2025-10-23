/**
 * @description Test class for RLCSCreditInvoiceAction - tests the process for creating credit RLCS charges
 */

@IsTest
private class RLCSCreditInvoiceActionTest {
    private static Account customerAccount;
    private static Map<String, RLCS_Charge__c> rlcsChargesByRef;
    private static final Date DEFAULT_DATE = Date.newInstance(2019,1,1);
    private static Map<String, Invoice__c> invoicesByRef;

    static {}

    private static void init() {
        // Create a client account
        customerAccount = new Account(Name = 'Big Company', Type = 'Customer');
        insert customerAccount;

        // Create a vendor account
        Account vendorAccount = new Account(Name = 'Vendor 1', Type = 'Supplier');
        insert vendorAccount;

        // Create some sites (adapting from existing pattern)
        Map<String, Site__c> sitesByName = new Map<String, Site__c>();
        sitesByName.put('Site1', new Site__c(Name = 'Site 1', Account__c = customerAccount.Id));
        sitesByName.put('Site2', new Site__c(Name = 'Site 2', Account__c = customerAccount.Id));
        sitesByName.put('Site3', new Site__c(Name = 'Site 3', Account__c = customerAccount.Id));
        insert sitesByName.values();

        // Create RLCS Jobs
        Map<String, RLCS_Job__c> rlcsJobsByRef = new Map<String, RLCS_Job__c>();
        for (Integer i = 1; i <= 6; i++) {
            RLCS_Job__c rlcsJob = new RLCS_Job__c(
                Customer_Account__c = customerAccount.Id,
                Status__c = 'Open',
                Delivery_Date__c = DEFAULT_DATE
            );
            rlcsJobsByRef.put('RJob' + i, rlcsJob);
        }
        insert rlcsJobsByRef.values();

        // Create RLCS charges (manual charges)
        rlcsChargesByRef = new Map<String, RLCS_Charge__c>();
        Map<Id, String> rlcsJobRefsById = new Map<Id, String>();
        
        for (String jobRef : rlcsJobsByRef.keySet()) {
            RLCS_Job__c rlcsJob = rlcsJobsByRef.get(jobRef);
            
            // Create manual charge
            RLCS_Charge__c manualCharge = new RLCS_Charge__c(
                RLCS_Job__c = rlcsJob.Id,
                Charge_Type__c = 'Transport',
                Date__c = DEFAULT_DATE,
                Sales_Price__c = 123.56,
                Cost__c = 200.56,
                Sales_Account__c = customerAccount.Id
            );
            rlcsChargesByRef.put('MC_' + jobRef, manualCharge);
            rlcsJobRefsById.put(rlcsJob.Id, jobRef);
        }
        insert rlcsChargesByRef.values();

        // Re-query RLCS Jobs with required fields for charge description
        Map<Id, RLCS_Job__c> rlcsJobsWithFieldsById = new Map<Id, RLCS_Job__c>([
            SELECT Id, Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
            FROM RLCS_Job__c
            WHERE Id IN :rlcsJobsByRef.values()
        ]);

        // Create automatic RLCS Job charges using the service
        for (String jobRef : rlcsJobsByRef.keySet()) {
            RLCS_Job__c rlcsJob = rlcsJobsByRef.get(jobRef);
            RLCS_Job__c rlcsJobWithFields = rlcsJobsWithFieldsById.get(rlcsJob.Id);
            RLCS_Charge__c autoCharge = RLCSChargeService.createAutoJobCharge(
                rlcsJobWithFields,
                RLCSChargeService.JOB_CHARGE_TYPE_JOB
            );
            autoCharge.Sales_Price__c = 250;
            autoCharge.Sales_Account__c = customerAccount.Id;
            rlcsChargesByRef.put('AC_' + jobRef, autoCharge);
        }
        
        // Insert the auto charges
        List<RLCS_Charge__c> autoCharges = new List<RLCS_Charge__c>();
        for (String key : rlcsChargesByRef.keySet()) {
            if (key.startsWith('AC_')) {
                autoCharges.add(rlcsChargesByRef.get(key));
            }
        }
        insert autoCharges;

        System.assertEquals(12, rlcsChargesByRef.size());

        // Create some invoices. One draft and one sent.
        invoicesByRef = new Map<String, Invoice__c>();
        invoicesByRef.put('draft', new Invoice__c(
            Account__c = customerAccount.Id, 
            Raised_Date__c = System.today(),
            Status__c = 'Draft'
        ));
        invoicesByRef.put('sent', new Invoice__c(
            Account__c = customerAccount.Id, 
            Raised_Date__c = System.today(),
            Status__c = 'Sent'
        ));
        insert invoicesByRef.values();
    }

    @TestSetup 
    private static void setup() {}

    /**
     * @description Test the process of crediting part of an invoice with RLCS charges
     */
    @IsTest
    static void testPartialInvoiceCredit() {

        // Setup standard data
        init();

        // Allocate some of the RLCS charges to the sent invoice
        rlcsChargesByRef.get('MC_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('AC_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('MC_RJob2').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('AC_RJob2').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('MC_RJob3').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('AC_RJob3').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        update rlcsChargesByRef.values();

        // Start the test
        Test.startTest();

        // Create the input parameters to credit RLCS charges
        RLCSCreditInvoiceAction.InputParameters inputParams = new RLCSCreditInvoiceAction.InputParameters();
        inputParams.invoiceId = invoicesByRef.get('sent').Id;
        inputParams.creditWholeInvoice = false;
        inputParams.isTest = true;
        inputParams.selectedRLCSChargeIds = rlcsChargesByRef.get('MC_RJob1').Id + '; ' + rlcsChargesByRef.get('AC_RJob1').Id + '; ' + rlcsChargesByRef.get('AC_RJob3').Id;

        // Do a test run
        List<RLCSCreditInvoiceAction.ActionResults> actionResults = RLCSCreditInvoiceAction.createTestInvoiceCreditCharges(new List<RLCSCreditInvoiceAction.InputParameters>{inputParams});
        System.assertEquals(623.56, actionResults[0].creditTotal);
        System.assertEquals(3, actionResults[0].jobChargeCount);
        System.assertEquals(invoicesByRef.get('sent').Id, actionResults[0].invoiceId);

        // Get credit RLCS charges - should be none yet since it was a test
        List<RLCS_Charge__c> creditRLCSCharges = [SELECT Id, Sales_Price__c, Sales_Account__c, Sales_Invoice__c, RLCS_Job__c, Credited_RLCS_Charge__c, Credit_RLCS_Charge__c
        FROM RLCS_Charge__c WHERE Charge_Type__c='Credit'];
        System.assertEquals(0, creditRLCSCharges.size());

        // Change the parameters to make this commit changes
        inputParams.isTest = false;

        // Do a proper run
        actionResults = RLCSCreditInvoiceAction.createTestInvoiceCreditCharges(new List<RLCSCreditInvoiceAction.InputParameters>{inputParams});
        System.assertEquals(623.56, actionResults[0].creditTotal);
        System.assertEquals(3, actionResults[0].jobChargeCount);
        System.assertEquals(invoicesByRef.get('sent').Id, actionResults[0].invoiceId);

        // Stop the test
        Test.stopTest();

        // Get credit RLCS charges
        Map<Id, Id> creditRLCSChargeIdByRLCSChargeId = new Map<Id, Id>();
        creditRLCSCharges = [SELECT Id, Sales_Price__c, Sales_Account__c, Sales_Invoice__c, RLCS_Job__c, Credited_RLCS_Charge__c
                                                    FROM RLCS_Charge__c WHERE Charge_Type__c='Credit'];
        System.assertEquals(3, creditRLCSCharges.size());
        for (RLCS_Charge__c rlcsCharge : creditRLCSCharges) {
            if (rlcsCharge.Credited_RLCS_Charge__c == rlcsChargesByRef.get('MC_RJob1').Id) {
                System.assertEquals(-1 * rlcsChargesByRef.get('MC_RJob1').Sales_Price__c, rlcsCharge.Sales_Price__c);
                System.assertEquals(rlcsChargesByRef.get('MC_RJob1').RLCS_Job__c, rlcsCharge.RLCS_Job__c);
            } else if (rlcsCharge.Credited_RLCS_Charge__c == rlcsChargesByRef.get('AC_RJob1').Id) {
                System.assertEquals(-1 * rlcsChargesByRef.get('AC_RJob1').Sales_Price__c, rlcsCharge.Sales_Price__c);
                System.assertEquals(rlcsChargesByRef.get('AC_RJob1').RLCS_Job__c, rlcsCharge.RLCS_Job__c);
            } else if (rlcsCharge.Credited_RLCS_Charge__c == rlcsChargesByRef.get('AC_RJob3').Id) {
                System.assertEquals(-1 * rlcsChargesByRef.get('AC_RJob3').Sales_Price__c, rlcsCharge.Sales_Price__c);
                System.assertEquals(rlcsChargesByRef.get('AC_RJob3').RLCS_Job__c, rlcsCharge.RLCS_Job__c);
            } else {
                System.assert(false, 'This is not a valid RLCS charge : ' + rlcsCharge);
            }

            // Add to the map to be used later
            creditRLCSChargeIdByRLCSChargeId.put(rlcsCharge.Credited_RLCS_Charge__c, rlcsCharge.Id);
        }
        System.assertEquals(3, creditRLCSChargeIdByRLCSChargeId.size());

        // Get the credited RLCS charges
        List<RLCS_Charge__c> creditedRLCSCharges = [SELECT Id, Credit_RLCS_Charge__c FROM RLCS_Charge__c WHERE Credit_RLCS_Charge__c != NULL];
        System.assertEquals(3, creditedRLCSCharges.size());
        for (RLCS_Charge__c rlcsCharge : creditedRLCSCharges) {
            System.assertEquals(creditRLCSChargeIdByRLCSChargeId.get(rlcsCharge.Id), rlcsCharge.Credit_RLCS_Charge__c);
        }
    }

    /**
     * @description Test crediting a whole invoice
     */
    @IsTest
    static void testWholeInvoiceCredit() {
        
        // Setup standard data
        init();

        // Allocate all RLCS charges to the sent invoice
        for (RLCS_Charge__c rlcsCharge : rlcsChargesByRef.values()) {
            rlcsCharge.Sales_Invoice__c = invoicesByRef.get('sent').Id;
        }
        update rlcsChargesByRef.values();

        // Start the test
        Test.startTest();

        // Create the input parameters to credit whole invoice
        RLCSCreditInvoiceAction.InputParameters inputParams = new RLCSCreditInvoiceAction.InputParameters();
        inputParams.invoiceId = invoicesByRef.get('sent').Id;
        inputParams.creditWholeInvoice = true;
        inputParams.isTest = false;

        // Execute the credit action
        List<RLCSCreditInvoiceAction.ActionResults> actionResults = RLCSCreditInvoiceAction.createTestInvoiceCreditCharges(new List<RLCSCreditInvoiceAction.InputParameters>{inputParams});
        
        // Stop the test
        Test.stopTest();

        // Verify results
        System.assertEquals(1, actionResults.size());
        System.assertEquals(invoicesByRef.get('sent').Id, actionResults[0].invoiceId);
        System.assertEquals(true, actionResults[0].isSuccess);
        System.assertEquals(12, actionResults[0].jobChargeCount);

        // Get credit RLCS charges
        List<RLCS_Charge__c> creditRLCSCharges = [SELECT Id FROM RLCS_Charge__c WHERE Charge_Type__c='Credit'];
        System.assertEquals(12, creditRLCSCharges.size());
    }

    /**
     * @description Test with empty selection
     */
    @IsTest
    static void testEmptySelection() {
        
        // Setup standard data
        init();

        // Start the test
        Test.startTest();

        // Create the input parameters with no selections
        RLCSCreditInvoiceAction.InputParameters inputParams = new RLCSCreditInvoiceAction.InputParameters();
        inputParams.invoiceId = invoicesByRef.get('sent').Id;
        inputParams.creditWholeInvoice = false;
        inputParams.isTest = false;
        inputParams.selectedRLCSChargeIds = null;

        // Execute the credit action
        List<RLCSCreditInvoiceAction.ActionResults> actionResults = RLCSCreditInvoiceAction.createTestInvoiceCreditCharges(new List<RLCSCreditInvoiceAction.InputParameters>{inputParams});
        
        // Stop the test
        Test.stopTest();

        // Should have no results since no charges were selected
        System.assertEquals(0, actionResults.size());
    }
}