/**
 * @description This is an invocable method that can be called from a Flow to credit all or part of an invoice for RLCS Charges
 */

public with sharing class RLCSCreditInvoiceAction {

    /**
     * @description This is called from a flow to create credit RLCS charges for selected invoices and charges
     * @param inputParams Details of the invoice and charges that should be credited
     * @return The results of the update including totals etc
     */
    @InvocableMethod(Label='Create/Test Invoice Credit RLCS Charges' Description='This either credits the selected invoice RLCS charges or tests this and returns the total')
    public static List<ActionResults> createTestInvoiceCreditCharges(List<InputParameters> inputParams) {
        System.debug(inputParams);

        // Loop through the input parameters and get the Ids for all of the complete invoices and the selected RLCS charges
        Set<Id> wholeInvoiceIds = new Set<Id>();
        Set<Id> selectedRLCSChargeIds = new Set<Id>();
        Map<Id, InputParameters> inputParamsByInvoiceId = new Map<Id, InputParameters>();
        for (InputParameters inputParam : inputParams) {
            if (inputParam.creditWholeInvoice == true) {
                wholeInvoiceIds.add(inputParam.invoiceId);
            } else if (inputParam.selectedRLCSChargeIds != null) {
                for (String rlcsChargeId : inputParam.selectedRLCSChargeIds.split(';')) {
                    selectedRLCSChargeIds.add(rlcsChargeId.trim());
                }
            }

            // Add to the map by invoice Id
            inputParamsByInvoiceId.put(inputParam.invoiceId, inputParam);

        }

        // If there are any whole invoices then get all of the related RLCS charges
        if (wholeInvoiceIds != null) {
            Map<Id, RLCS_Charge__c> wholeInvoiceRLCSCharges = new Map<Id, RLCS_Charge__c>([SELECT Id FROM RLCS_Charge__c WHERE Sales_Invoice__c IN:wholeInvoiceIds]);
            selectedRLCSChargeIds.addAll(wholeInvoiceRLCSCharges.keySet());
        }

        // Get all the RLCS charge records for these charges and add them to a map by Invoice Id
        Map<Id, List<RLCS_Charge__c>> rlcsChargesToCreditByInvoice = new Map<Id, List<RLCS_Charge__c>>();
        for (RLCS_Charge__c rc : [SELECT Id, Sales_Invoice__c, Sales_Price__c, Sales_Account__c, Charge_Type__c, RecordTypeId,
                                        Date__c, Name, RLCS_Job__c, Credited_RLCS_Charge__c,
                                        RLCS_Job__r.Product_Name__c, RLCS_Job__r.Waste_Type__c, RLCS_Job__r.EWC__c, RLCS_Job__r.Collected_Date__c
                                    FROM RLCS_Charge__c
                                    WHERE Charge_Type__c!=:RLCSChargeService.JOB_CHARGE_TYPE_CREDIT AND Id IN:selectedRLCSChargeIds]) {
            if (rlcsChargesToCreditByInvoice.containsKey(rc.Sales_Invoice__c) == false) {rlcsChargesToCreditByInvoice.put(rc.Sales_Invoice__c, new List<RLCS_Charge__c>());}
            rlcsChargesToCreditByInvoice.get(rc.Sales_Invoice__c).add(rc);
        }

        // Step through the Invoices and create credit RLCS charges each of these
        Map<Id, ActionResults> actionResultsByInvoiceId = new Map<Id, ActionResults>();
        List<RLCS_Charge__c> creditRLCSCharges = new List<RLCS_Charge__c>();
        for (Id invoiceId : rlcsChargesToCreditByInvoice.keySet()) {
            // Get the the input parameters for this invoice
            InputParameters invoiceInputParams = inputParamsByInvoiceId.get(invoiceId);

            // Start the counts
            Decimal invoiceCreditTotal = 0;
            Integer creditChargesCount = 0;

            // Get the RLCS charges
            List<RLCS_Charge__c> rlcsCharges = rlcsChargesToCreditByInvoice.get(invoiceId);

            // Step through the RLCS charges and create credit RLCS charges
            for (RLCS_Charge__c rc : rlcsCharges) {
                // Create the RLCS charge for the credit
                RLCS_Charge__c creditRLCSCharge = RLCSChargeService.createAutoJobCharge(rc.RLCS_Job__r, RLCSChargeService.JOB_CHARGE_TYPE_CREDIT);

                // Update the RLCS charge with credit details
                creditRLCSCharge.Sales_Price__c = -1 * rc.Sales_Price__c;
                creditRLCSCharge.Sales_Account__c = rc.Sales_Account__c;
                creditRLCSCharge.Date__c = System.today();

                // Add a link to the RLCS charge being credited
                creditRLCSCharge.Credited_RLCS_Charge__c = rc.Id;

                // Add to the list of new charges if this is NOT a test
                if (invoiceInputParams.isTest == false) {
                    creditRLCSCharges.add(creditRLCSCharge);
                }

                // Add up the amounts
                invoiceCreditTotal += rc.Sales_Price__c;
                creditChargesCount ++;
            }

            // Add to the results
            actionResultsByInvoiceId.put(invoiceId, new ActionResults(invoiceId, invoiceCreditTotal, creditChargesCount,true,null));

        }

        // If there are any credit RLCS charges to insert then add them
        if (creditRLCSCharges.size() > 0) {
            insert creditRLCSCharges;

            // Update the RLCS charges with links to the credit charges
            List<RLCS_Charge__c> creditedRLCSCharges = new List<RLCS_Charge__c>();
            for (RLCS_Charge__c creditRLCSCharge : creditRLCSCharges) {
                RLCS_Charge__c rlcsCharge = new RLCS_Charge__c();
                rlcsCharge.Id = creditRLCSCharge.Credited_RLCS_Charge__c;
                rlcsCharge.Credit_RLCS_Charge__c = creditRLCSCharge.Id;
                creditedRLCSCharges.add(rlcsCharge);
            }
            update creditedRLCSCharges;

        }

        // Return the results
        return actionResultsByInvoiceId.values();

    }

    /************** PRIVATE METHODS **************/


    /*************** INNER CLASSES ***************/
    public class InputParameters {
        @InvocableVariable(Label='Invoice Id' Description='The Id of the invoice that should be credited' Required=true)
        public Id invoiceId;
        @InvocableVariable(Label='Credit Whole Invoice' Description='Select this if the whole invoice should be credited' Required=false)
        public Boolean creditWholeInvoice;
        @InvocableVariable(Label='Selected RLCS Charge Ids' Description='A string containing the selected RLCS charges if this is a partial credit' Required=false)
        public String selectedRLCSChargeIds;
        @InvocableVariable(Label='Test Run' Description='If this is selected the code will run a test and return the total amount that will be ' Required=false)
        public Boolean isTest;

    }

    public class ActionResults {
        @InvocableVariable(Label='Invoice Id' Description='The Id of the invoice thta was credited' Required=true)
        public Id invoiceId;
        @InvocableVariable(Label='Credit Total' Description='The total of the RLCS charges that are being credited' Required=true)
        public Decimal creditTotal;
        @InvocableVariable(Label='Success' Description='Indicates whether this was a success or not' Required=true)
        public Boolean isSuccess;
        @InvocableVariable(Label='RLCS Charge Count' Description='The number of RLCS charges that will be credited' Required=false)
        public Integer jobChargeCount;
        @InvocableVariable(Label='Errors' Description='Any errors returned by the process' Required=false)
        public String errorMsg;

        public ActionResults(Id invoiceId, Decimal creditTotal, Integer jobChargeCount, Boolean isSuccess, String errorMsg) {
            this.invoiceId = invoiceId;
            this.creditTotal = creditTotal;
            this.jobChargeCount = jobChargeCount;
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }

    }



}