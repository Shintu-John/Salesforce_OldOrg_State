public class RLCSChargeService {
    
    public static final String JOB_CHARGE_TYPE_JOB = 'RLCS Job';
    public static final String JOB_CHARGE_TYPE_TONNAGE = 'Tonnage';
    public static final String JOB_CHARGE_TYPE_REBATE = 'Rebate';
    public static final String JOB_CHARGE_TYPE_TRANSPORT = 'Transport';
    public static final String JOB_CHARGE_TYPE_SECONDARY_TRANSPORT = 'Secondary Transport';
    public static final String JOB_CHARGE_TYPE_CREDIT = 'Credit';
    
    public static final String JOB_CHARGE_RECORD_TYPE_AUTO = 'Automatic';
    public static final String JOB_CHARGE_RECORD_TYPE_MANUAL = 'Manual';
    
    public static RLCS_Charge__c createAutoJobCharge(RLCS_Job__c job, String chargeType) {
        RLCS_Charge__c jobCharge = new RLCS_Charge__c();
        jobCharge.RLCS_Job__c = job.Id;
        jobCharge.Charge_Type__c = chargeType;
        jobCharge.RecordTypeId = Schema.SObjectType.RLCS_Charge__c.getRecordTypeInfosByDeveloperName().get(JOB_CHARGE_RECORD_TYPE_AUTO)?.getRecordTypeId();
        jobCharge.Sales_Price__c = 0;
        jobCharge.Cost__c = 0;
        jobCharge.VAT__C = '0';

        // Set collection date from Job collected date
        if (job.Collected_Date__c != null) {
            jobCharge.Collection_Date__c = job.Collected_Date__c;
        }

        // Set description from Job fields
        jobCharge.Description__c = buildChargeDescription(job);

        return jobCharge;
    }

    private static String buildChargeDescription(RLCS_Job__c job) {
        List<String> parts = new List<String>();

        if (String.isNotBlank(job.Waste_Type__c)) {
            parts.add('Waste Type: ' + job.Waste_Type__c);
        }
        if (String.isNotBlank(job.Product_Name__c)) {
            parts.add('Product: ' + job.Product_Name__c);
        }
        if (String.isNotBlank(job.EWC__c)) {
            parts.add('EWC: ' + job.EWC__c);
        }

        return String.join(parts, ', ');
    }
    
    // Overloaded method WITH Job object - updates Collection_Date__c and Description__c
    public static RLCS_Charge__c updateJobCharge(RLCS_Charge__c jobCharge, RLCS_Job__c job, Decimal chargeCost, Decimal chargeSalesPrice, Id salesAccountId, Id vendorAccountId, Id haulierAccountId, String vat) {
        Boolean jobChargeUpdated = false;

        // Update Collection_Date__c from Job's Collected_Date__c
        Date newCollectionDate = job.Collected_Date__c;
        if (jobCharge.Collection_Date__c != newCollectionDate) {
            jobCharge.Collection_Date__c = newCollectionDate;
            jobChargeUpdated = true;
        }

        // Update Description__c from Job fields
        String newDescription = buildChargeDescription(job);
        if (jobCharge.Description__c != newDescription) {
            jobCharge.Description__c = newDescription;
            jobChargeUpdated = true;
        }

        if (jobCharge.Cost__c != chargeCost) {
            jobCharge.Cost__c = chargeCost;
            jobChargeUpdated = true;
        }

        if (jobCharge.Sales_Price__c != chargeSalesPrice) {
            jobCharge.Sales_Price__c = chargeSalesPrice;
            jobChargeUpdated = true;
        }

        if (jobCharge.Vendor_Account__c != vendorAccountId) {
            jobCharge.Vendor_Account__c = vendorAccountId;
            jobChargeUpdated = true;
        }

        if (jobCharge.Sales_Account__c != salesAccountId) {
            jobCharge.Sales_Account__c = salesAccountId;
            jobChargeUpdated = true;
        }

        if (jobCharge.Haulier__c != haulierAccountId) {
            jobCharge.Haulier__c = haulierAccountId;
            jobChargeUpdated = true;
        }

        if (jobCharge.VAT__c != vat) {
            jobCharge.VAT__c = vat;
            jobChargeUpdated = true;
        }

        if (jobChargeUpdated == true) {
            return jobCharge;
        } else {
            return null;
        }
    }

    // Original method WITHOUT Job object - for backward compatibility
    public static RLCS_Charge__c updateJobCharge(RLCS_Charge__c jobCharge, Decimal chargeCost, Decimal chargeSalesPrice, Id salesAccountId, Id vendorAccountId, Id haulierAccountId, String vat) {
        Boolean jobChargeUpdated = false;
        if (jobCharge.Cost__c != chargeCost) {
            jobCharge.Cost__c = chargeCost;
            jobChargeUpdated = true;
        }

        if (jobCharge.Sales_Price__c != chargeSalesPrice) {
            jobCharge.Sales_Price__c = chargeSalesPrice;
            jobChargeUpdated = true;
        }

        if (jobCharge.Vendor_Account__c != vendorAccountId) {
            jobCharge.Vendor_Account__c = vendorAccountId;
            jobChargeUpdated = true;
        }

        if (jobCharge.Sales_Account__c != salesAccountId) {
            jobCharge.Sales_Account__c = salesAccountId;
            jobChargeUpdated = true;
        }

        if (jobCharge.Haulier__c != haulierAccountId) {
            jobCharge.Haulier__c = haulierAccountId;
            jobChargeUpdated = true;
        }
        if (jobCharge.VAT__c != vat) {
            jobCharge.VAT__c = vat;
            jobChargeUpdated = true;
        }

        if (jobChargeUpdated == true) {
            return jobCharge;
        } else {
            return null;
        }

    }
}