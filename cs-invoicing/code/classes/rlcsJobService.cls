public class rlcsJobService {
    private static string fixedJobPricingMethod = 'Fixed';
    private static string rebatePricingMethod = 'Rebate';
    private static string variablePricingMethod = 'Variable';
    
	 public static void createUpdateAutoJobCharges(List<RLCS_Job__c> newUpdatedJobs, Map<Id, RLCS_Job__c> oldJobsById) {
         
        List<RLCS_Charge__c> newUpdatedJobCharges = new List<RLCS_Charge__c>();
        Map<Id,RLCS_Charge__c> jobChargesToDeleteMap = new Map<Id,RLCS_Charge__c>();
         
        Map<Id, RLCS_Job__c> jobsToProcessById = new Map<Id, RLCS_Job__c>();
        Map<Id, RLCS_Job__c> jobsToProcessByRebateId = new Map<Id, RLCS_Job__c>();
        Map<Id, RLCS_Job__c> jobsToProcessByVendorChangesId = new Map<Id, RLCS_Job__c>();
        Map<Id, RLCS_Job__c> jobsToProcessByWeightChangesId = new Map<Id, RLCS_Job__c>();
        Map<Id, RLCS_Job__c> jobsToProcessByAdditionalWeightChangesId = new Map<Id, RLCS_Job__c>();

        // Get all jobs where key data has changed
        Set<Id> jobsToIgnoreForSalesTonnage = new Set<Id>();
        Set<Id> jobsToIgnoreForVendorTonnage = new Set<Id>();
         
		Set<String> updates =new Set<String>();
        RLCS_Job__c errorJob = null;

        for (RLCS_Job__c job : newUpdatedJobs) {
            
            if(job.Is_Mixed_Job__c) continue;

            // Get the old Job
            RLCS_Job__c oldJob = oldJobsById?.get(job.Id);
            
            if (oldJob != null) {
                List<sObjectField> refreshChargesFields = new List<sObjectField>();
                refreshChargesFields.add(RLCS_Job__c.Additional_Weight_Sales_Price__c);
                refreshChargesFields.add(RLCS_Job__c.Sales_Cost__c);
                refreshChargesFields.add(RLCS_Job__c.Material_Weight_Tonnes__c);
                refreshChargesFields.add(RLCS_Job__c.Sales_Transport__c);
                refreshChargesFields.add(RLCS_Job__c.Customer_Account__c);
                refreshChargesFields.add(RLCS_Job__c.Supplier_Cost__c);
                refreshChargesFields.add(RLCS_Job__c.Transport__c);
                refreshChargesFields.add(RLCS_Job__c.Transport_Per_Tonne__c);
                refreshChargesFields.add(RLCS_Job__c.Transport_Per_Unit__c);
                refreshChargesFields.add(RLCS_Job__c.Unit_Count__c);
                refreshChargesFields.add(RLCS_Job__c.Haullier__c);
                refreshChargesFields.add(RLCS_Job__c.Processor__c);
                refreshChargesFields.add(RLCS_Job__c.Sales_Tonnage_Inc__c);
                refreshChargesFields.add(RLCS_Job__c.Pricing_Method__c);
                refreshChargesFields.add(RLCS_Job__c.Sales_tonnage_charge_thereafter__c);
                refreshChargesFields.add(RLCS_Job__c.Additional_Weight_Cost__c);
                refreshChargesFields.add(RLCS_Job__c.Partner_Tonnage_charge_thereafter__c);
                refreshChargesFields.add(RLCS_Job__c.Weight_Variance__c);
                refreshChargesFields.add(RLCS_Job__c.Waste_Type__c);
                refreshChargesFields.add(RLCS_Job__c.Client_Transport_Deduction__c);
                refreshChargesFields.add(RLCS_Job__c.Supplier_Transport_Deduction__c);
                
                Boolean needJobChargeRefresh = false;
                for(sObjectField field : refreshChargesFields){
                    String fieldAPIName = field.getDescribe().getName();
                    if(oldJob.get(fieldAPIName) != job.get(fieldAPIName)){
                        needJobChargeRefresh = true;
                    }
                }
                
                if(!needJobChargeRefresh){
                    continue;
                }

                if (job.Pricing_Method__c == rebatePricingMethod){
                    jobsToProcessByRebateId.put(job.Id, job);
                }
                else{
                    // If the prices have changed then create/update jobs
                    if (job.Material_Weight_Tonnes__c != oldJob.Material_Weight_Tonnes__c && job.Pricing_Method__c == variablePricingMethod){
                        if (job.Sales_Tonnage_Inc__c >= 0 && job.Material_Weight_Tonnes__c > job.Sales_Tonnage_Inc__c){
                            jobsToProcessByAdditionalWeightChangesId.put(job.Id, job);
                        }
                        
                        if(job.Transport_Per_Tonne__c != true){
                            jobsToProcessByWeightChangesId.put(job.Id, job);
                        }else{
                            jobsToProcessById.put(job.Id, job);
                        }
                    }
                    else {
                        if(job.Additional_Weight_Sales_Price__c != oldJob.Additional_Weight_Sales_Price__c
                                || job.Sales_Cost__c != oldJob.Sales_Cost__c
                                || job.Delivery_Date__c != oldJob.Delivery_Date__c
                                || job.Sales_Transport__c != oldJob.Sales_Transport__c
                                || job.Transport__c != oldJob.Transport__c
                                || job.Transport_Per_Tonne__c != oldJob.Transport_Per_Tonne__c
                           		|| job.Material_Weight_Tonnes__c != oldJob.Material_Weight_Tonnes__c
                                || job.Unit_Count__c != oldJob.Unit_Count__c
                                || job.Transport_Per_Unit__c != oldJob.Transport_Per_Unit__c
                                || job.Customer_Account__c != oldJob.Customer_Account__c
                                || job.Sales_tonnage_charge_thereafter__c != oldJob.Sales_tonnage_charge_thereafter__c ) {
                            jobsToProcessById.put(job.Id, job);

                        } //sales

                        if(job.Additional_Weight_Cost__c != oldJob.Additional_Weight_Cost__c
                                 || job.Supplier_Cost__c != oldJob.Supplier_Cost__c
                                || job.Transport__c != oldJob.Transport__c
                                || job.Haullier__c != oldJob.Haullier__c
                                || job.Partner_Tonnage_charge_thereafter__c != oldJob.Partner_Tonnage_charge_thereafter__c) { //added by DU
                            jobsToProcessByVendorChangesId.put(job.Id, job);

                        }
                        //supplier
                        if(job.Partner_Tonnage_charge_thereafter__c == oldJob.Partner_Tonnage_charge_thereafter__c)
                         {
                             System.debug('adding job id to ignore list for the partner tonnage ' +job.Id);
                                      jobsToIgnoreForVendorTonnage.add(job.Id);
                        }
                        if(job.Sales_tonnage_charge_thereafter__c == oldJob.Sales_tonnage_charge_thereafter__c)
                        {
                            System.debug('adding job id to ignore list for the sales tonnage ' +job.Id);
                            jobsToIgnoreForSalesTonnage.add(job.Id);
                        }


                    }
                }
            } else {
                if (job.Pricing_Method__c == rebatePricingMethod){
                    jobsToProcessByRebateId.put(job.Id, job);
                }
                else{
                    // This is new so add it
                    jobsToProcessById.put(job.Id, job);
                }
            }
        }

        // Re-query jobs for vendor changes to get description fields
        if (jobsToProcessByVendorChangesId.size() > 0) {
            Map<Id, RLCS_Job__c> jobsWithDescriptionFields = new Map<Id, RLCS_Job__c>(
                [SELECT Id, Material_Weight_Tonnes__c, Unit_Count__c, Transport_Per_Tonne__c, Transport_Per_Unit__c,
                        Transport__c, Sales_Transport__c, Customer_Account__c, Haullier__c, Processor__c, VAT__c,
                        Supplier_Cost__c, Sales_Cost__c, Additional_Weight_Cost__c, Additional_Weight_Sales_Price__c,
                        Pricing_Method__c, Sales_Tonnage_Inc__c, Sales_tonnage_charge_thereafter__c,
                        Partner_Tonnage_charge_thereafter__c,
                        Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c,
                        Order_Product__r.Transport__c,
                        Order_Product__r.Transport_Per_Tonne__c,
                        Order_Product__r.Transport_Per_Unit__c,
                        Order_Product__r.Secondary_Transport_Charge__c,
                        Order_Product__r.Secondary_Transport_P_T__c,
                        Order_Product__r.Secondary_Transport_Per_Tonne__c,
                        Order_Product__r.Secondary_Transport_Per_Unit__c,
                        Order_Product__r.Secondary_Haulier__c
                 FROM RLCS_Job__c
                 WHERE Id IN :jobsToProcessByVendorChangesId.keySet()]
            );
            jobsToProcessByVendorChangesId = jobsWithDescriptionFields;
        }

        // Step through these jobs and get a map of all of the job charges
        if (jobsToProcessByVendorChangesId.size() > 0) {
            // Loop through and get a map of all of the current auto job charges that are not linked to a locked sales invoice
            Map<String, RLCS_Charge__c> jobChargesByKey = new Map<String, RLCS_Charge__c>();
            Map<String, RLCS_Charge__c> jobChargesByKeyLocked = new Map<String, RLCS_Charge__c>();
                   for (RLCS_Charge__c jobCharge : [SELECT Id, RecordTypeId, Charge_Type__c, Cost__c, Sales_Price__c, RLCS_Job__c,Date__c, Collection_Date__c, Description__c, Vendor_Account__c, Sales_Account__c,Vendor_Invoice_Locked__c, VAT__c, Haulier__c
                                                FROM RLCS_Charge__c
                                                WHERE RLCS_Job__c IN:jobsToProcessByVendorChangesId.keySet()
                                                    AND RecordType.DeveloperName =:RLCSChargeService.JOB_CHARGE_RECORD_TYPE_AUTO ]) {//AND (Credited__c = FALSE or Credited__c = null)
                                                        // DU 17/8/21 removed locked added credited
				if(!jobCharge.Vendor_Invoice_Locked__c){
                	jobChargesByKey.put(jobCharge.RLCS_Job__c + '~' + jobCharge.Charge_Type__c, jobCharge);
                } else {
                    jobChargesByKeyLocked.put(jobCharge.RLCS_Job__c + '~' + jobCharge.Charge_Type__c, jobCharge);
                }


            }

            // Loop through the jobs and create/update charges

            for (RLCS_Job__c job : jobsToProcessByVendorChangesId.values()) {
                // If this is not a rebate job then try and create / update the job job charge and tonnage
                String key=job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_JOB;
                // Try and find the job charge
                RLCS_Charge__c jobChargeJob = jobChargesByKey.get(key);
                if (jobChargeJob == null) {
                    //check if an invoice locked job charge exists
                    if(jobChargesByKeyLocked.containsKey(key))
                    {
                        errorJob = jobsToProcessByVendorChangesId.values()[0];
                        errorJob.addError('There is an Vendor Invoice Locked Job Charge! Edits are not allowed.');
                        
                        jobChargeJob = jobChargesByKeyLocked.get(key);
                    }
                    else {
                        jobChargeJob = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_JOB);
                    }
                    
                    
                }
                
                // Update the Job job charge and update the map
                if(jobChargeJob != null && (job.Supplier_Cost__c > 0 || job.Sales_Cost__c > 0))
                {
                    RLCS_Charge__c updatedJobChargeJob = RLCSChargeService.updateJobCharge(jobChargeJob, job, job.Supplier_Cost__c, job.Sales_Cost__c, job.Customer_Account__c, job.Processor__c, job.Haullier__c, job.VAT__c);
                    if (updatedJobChargeJob != null && !updates.contains(key)) {
                        newUpdatedJobCharges.add(updatedJobChargeJob);
                        updates.add(key);
                    }
                }else {
                    // There is no additional charge, so if there is a job charge, mark it for deletion
                    if(jobChargeJob?.Id != null){
                        jobChargesToDeleteMap.put(jobChargeJob.Id, jobChargeJob);
                    }
                }
                
                
                String tonnageKey = job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE;
                RLCS_Charge__c jobChargeTonnage = jobChargesByKey.get(tonnageKey);
              if (job.Additional_Weight_Cost__c != 0 || job.Additional_Weight_Sales_Price__c > 0) {
                    // There is a tonnage charge so create or update the job charge
                    if (jobChargeTonnage == null) {
                        if(jobChargesByKeyLocked.containsKey(tonnageKey))
                        {
                            if(!jobsToIgnoreForVendorTonnage.contains(job.Id))
                            {
                                errorJob = jobsToProcessByVendorChangesId.values()[0];
                                errorJob.addError('There is an Invoice Locked Tonnage Charge! Edits are not allowed.');
                                
                                jobChargeTonnage = jobChargesByKeyLocked.get(tonnageKey);
                            }
                        }
                        else
                        {
                             if(job.Pricing_Method__c != fixedJobPricingMethod){
                            	jobChargeTonnage = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE);
                             }
                        }

                    }

                    // Update the Tonnage job charge and update the map
                    if(!updates.contains(tonnageKey) && jobChargeTonnage !=null )
                    {
                        RLCS_Charge__c updatedTonnageChargeJob = RLCSChargeService.updateJobCharge(jobChargeTonnage, job, job.Additional_Weight_Cost__c, job.Additional_Weight_Sales_Price__c, job.Customer_Account__c, job.Processor__c, job.Haullier__c, job.VAT__c);
                        if (updatedTonnageChargeJob != null) {
                            newUpdatedJobCharges.add(updatedTonnageChargeJob);
                            updates.add(tonnageKey);
                        }
                    }


                } else {
                    // There is no additional charge, so if there is a job charge, mark it for deletion
                    if (jobChargeTonnage?.Id != null) {
                        jobChargesToDeleteMap.put(jobChargeTonnage.Id, jobChargeTonnage);
                    }
                }
            }

            // If there are records to update then
        }


        // Re-query jobs with Order_Product__r and description fields for primary/secondary transport charges
        if (jobsToProcessById.size() > 0) {
            Map<Id, RLCS_Job__c> jobsWithOrderProductMap = new Map<Id, RLCS_Job__c>(
                [SELECT Id, Material_Weight_Tonnes__c, Unit_Count__c, Transport_Per_Tonne__c, Transport_Per_Unit__c,
                        Transport__c, Sales_Transport__c, Customer_Account__c, Haullier__c, Processor__c, VAT__c,
                        Supplier_Cost__c, Sales_Cost__c, Additional_Weight_Sales_Price__c, Additional_Weight_Cost__c,
                        Pricing_Method__c, Sales_Tonnage_Inc__c, Sales_tonnage_charge_thereafter__c,
                        Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c,
                        Order_Product__r.Transport__c,
                        Order_Product__r.Transport_Per_Tonne__c,
                        Order_Product__r.Transport_Per_Unit__c,
                        Order_Product__r.Secondary_Transport_Charge__c,
                        Order_Product__r.Secondary_Transport_P_T__c,
                        Order_Product__r.Secondary_Transport_Per_Tonne__c,
                        Order_Product__r.Secondary_Transport_Per_Unit__c,
                        Order_Product__r.Secondary_Haulier__c
                 FROM RLCS_Job__c
                 WHERE Id IN :jobsToProcessById.keySet()]
            );
            // Re-assign to ensure we use the fully-queried Job records with all required fields
            jobsToProcessById = jobsWithOrderProductMap;
        }

        if (jobsToProcessById.size() > 0) {
            // Loop through and get a map of all of the current auto job charges that are not linked to a locked sales invoice
            Map<String, RLCS_Charge__c> jobChargesByKey = new Map<String, RLCS_Charge__c>();
            Map<String, RLCS_Charge__c> jobChargesByKeyLocked = new Map<String, RLCS_Charge__c>();
            Map<String, RLCS_Charge__c> jobChargesByKeyVendorLocked = new Map<String, RLCS_Charge__c>();
            for (RLCS_Charge__c jobCharge : [SELECT Id, RecordTypeId, Charge_Type__c, Cost__c, Sales_Price__c, RLCS_Job__c,Date__c, Collection_Date__c, Description__c, Vendor_Account__c, Sales_Account__c,Sales_Invoice_Locked__c,Vendor_Invoice_Locked__c, VAT__c, Haulier__c
                                                FROM RLCS_Charge__c
                                                WHERE RLCS_Job__c IN:jobsToProcessById.keySet()
                                                    AND RecordType.DeveloperName =:RLCSChargeService.JOB_CHARGE_RECORD_TYPE_AUTO]) {// AND (Credited__c = FALSE or Credited__c = null)
                                                        // DU 17/8/21 removed locked added credited

				if(!jobCharge.Sales_Invoice_Locked__c){
                	jobChargesByKey.put(jobCharge.RLCS_Job__c + '~' + jobCharge.Charge_Type__c, jobCharge);
                }
                else{
                    jobChargesByKeyLocked.put(jobCharge.RLCS_Job__c + '~' + jobCharge.Charge_Type__c, jobCharge);
                }


            }

            // Loop through the jobs and create/update charges
            for (RLCS_Job__c job : jobsToProcessById.values()) {
                
                // If this is not a rebate job then try and create / update the job job charge and tonnage
                String key=job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_JOB;
                // Try and find the job charge
                RLCS_Charge__c jobChargeJob = jobChargesByKey.get(key);
                if (jobChargeJob == null) {
                    //check if an invoice locked job charge exists
                    if(jobChargesByKeyLocked.containsKey(key))
                    {
                        errorJob = jobsToProcessById.values()[0];
                        errorJob.addError('There is an Invoice Locked Job Charge! Edits are not allowed.');
                        
                        jobChargeJob = jobChargesByKeyLocked.get(key);
                    }
                    else
                    {
                        jobChargeJob = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_JOB);
                    }
                    
                    
                }

                // Update the Job job charge and update the map
                if(jobChargeJob != null && (job.Supplier_Cost__c > 0 || job.Sales_Cost__c > 0))
                {
                    RLCS_Charge__c updatedJobChargeJob = RLCSChargeService.updateJobCharge(jobChargeJob, job, job.Supplier_Cost__c, job.Sales_Cost__c, job.Customer_Account__c, job.Processor__c, job.Haullier__c, job.VAT__c);
                    if (updatedJobChargeJob != null  && !updates.contains(key)) {
                        newUpdatedJobCharges.add(updatedJobChargeJob);
                        updates.add(key);
                    }
                }else {
                    // There is no additional charge, so if there is a job charge, mark it for deletion
                    if(jobChargeJob?.Id != null){
                        jobChargesToDeleteMap.put(jobChargeJob.Id, jobChargeJob);
                    }
                }
                
                
                // Either update the tonnage or remove it, if there is no longer any additional tonnage
                String tonnageKey = job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE;
                RLCS_Charge__c jobChargeTonnage = jobChargesByKey.get(tonnageKey);
                 if (job.Additional_Weight_Sales_Price__c > 0 || job.Additional_Weight_Cost__c > 0) {
                    // There is a tonnage charge so create or update the job charge

                    if (jobChargeTonnage == null) {
                        if(jobChargesByKeyLocked.containsKey(tonnageKey))
                        {
                            if(!jobsToIgnoreForSalesTonnage.contains(job.Id))
                            {
                            errorJob = jobsToProcessById.values()[0];
                            errorJob.addError('There is an Invoice Locked Tonnage Charge! Edits are not allowed.');

                            jobChargeTonnage = jobChargesByKeyLocked.get(tonnageKey);
                            }
                        }
                        else
                        {
                             if(job.Pricing_Method__c != fixedJobPricingMethod){
                            	jobChargeTonnage = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE);
                             }
                        }

                    }

                    // Update the Tonnage job charge and update the map
                    if(!updates.contains(tonnageKey) && jobChargeTonnage !=null)
                    {
                        RLCS_Charge__c updatedTonnageChargeJob = RLCSChargeService.updateJobCharge(jobChargeTonnage, job, job.Additional_Weight_Cost__c, job.Additional_Weight_Sales_Price__c, job.Customer_Account__c, job.Processor__c, job.Haullier__c, job.VAT__c);
                        if (updatedTonnageChargeJob != null) {
                            newUpdatedJobCharges.add(updatedTonnageChargeJob);
                            updates.add(tonnageKey);
                        }
                    }


                } else {
                    // There is no additional charge, so if there is a job charge, mark it for deletion
                    if(jobChargeTonnage?.Id != null){
                        jobChargesToDeleteMap.put(jobChargeTonnage.Id, jobChargeTonnage);
                    }
                }
                
                
                // PRIMARY TRANSPORT CHARGE
                // Read from OrderItem (source of truth), NOT from job.Transport__c
                Decimal primaryTransportRate = job.Order_Product__r?.Transport__c ?? 0;
                Decimal primaryTransportAmount = (job.Order_Product__r?.Transport_Per_Tonne__c ?
                    (job.Material_Weight_Tonnes__c ?? 0) :
                    job.Order_Product__r?.Transport_Per_Unit__c ? (job.Unit_Count__c ?? 0) :
                    1) * primaryTransportRate;

                RLCS_Charge__c transportJobCharge = jobChargesByKey.get(job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_TRANSPORT);

                if (job.Sales_Transport__c > 0 || primaryTransportAmount > 0) {
                    if (transportJobCharge == null) {
                        transportJobCharge = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_TRANSPORT);
                    }
                    RLCS_Charge__c updatedTransportCharge = RLCSChargeService.updateJobCharge(
                        transportJobCharge,
                        job,
                        primaryTransportAmount,
                        job.Sales_Transport__c,
                        job.Customer_Account__c,
                        job.Haullier__c ?? job.Processor__c,
                        job.Haullier__c,
                        job.VAT__c
                    );
                    if (updatedTransportCharge != null) {
                        newUpdatedJobCharges.add(updatedTransportCharge);
                    }
                } else {
                    // There are no longer any values so remove the job charge
                    if (transportJobCharge?.Id != null) {
                        jobChargesToDeleteMap.put(transportJobCharge.Id, transportJobCharge);
                    }
                }

                // SECONDARY TRANSPORT CHARGE (NEW LOGIC)
                if (job.Order_Product__r?.Secondary_Transport_Charge__c == true) {
                    RLCS_Charge__c secondaryTransportCharge = jobChargesByKey.get(job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT);

                    // Determine calculation method (per tonne, per unit, or per load)
                    Decimal secondaryTransportAmount = 0;
                    Decimal secondaryTransportRate = job.Order_Product__r?.Secondary_Transport_P_T__c ?? 0;

                    if (job.Order_Product__r?.Secondary_Transport_Per_Tonne__c == true) {
                        secondaryTransportAmount = (job.Material_Weight_Tonnes__c ?? 0) * secondaryTransportRate;
                    } else if (job.Order_Product__r?.Secondary_Transport_Per_Unit__c == true) {
                        secondaryTransportAmount = (job.Unit_Count__c ?? 0) * secondaryTransportRate;
                    } else {
                        secondaryTransportAmount = 1 * secondaryTransportRate;
                    }

                    if (secondaryTransportAmount > 0) {
                        if (secondaryTransportCharge == null) {
                            secondaryTransportCharge = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT);
                        }

                        Id secondaryHaulier = job.Order_Product__r?.Secondary_Haulier__c != null ?
                            job.Order_Product__r.Secondary_Haulier__c :
                            job.Haullier__c;

                        RLCS_Charge__c updatedSecondaryCharge = RLCSChargeService.updateJobCharge(
                            secondaryTransportCharge,
                            job,
                            secondaryTransportAmount,
                            0,
                            job.Customer_Account__c,
                            secondaryHaulier,
                            secondaryHaulier,
                            job.VAT__c
                        );
                        if (updatedSecondaryCharge != null) {
                            newUpdatedJobCharges.add(updatedSecondaryCharge);
                        }
                    } else {
                        if (secondaryTransportCharge?.Id != null) {
                            jobChargesToDeleteMap.put(secondaryTransportCharge.Id, secondaryTransportCharge);
                        }
                    }
                } else {
                    RLCS_Charge__c secondaryTransportCharge = jobChargesByKey.get(job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT);
                    if (secondaryTransportCharge?.Id != null) {
                        jobChargesToDeleteMap.put(secondaryTransportCharge.Id, secondaryTransportCharge);
                    }
                }
            }
        }

        // Re-query jobs for rebate to get description fields
        if (jobsToProcessByRebateId.size() > 0) {
            Map<Id, RLCS_Job__c> jobsWithDescriptionFields = new Map<Id, RLCS_Job__c>(
                [SELECT Id, Material_Weight_Tonnes__c, Unit_Count__c, Transport_Per_Tonne__c, Transport_Per_Unit__c,
                        Transport__c, Sales_Transport__c, Customer_Account__c, Haullier__c, Processor__c, VAT__c,
                        Supplier_Cost__c, Sales_Cost__c, Additional_Weight_Cost__c, Additional_Weight_Sales_Price__c,
                        Pricing_Method__c, Sales_Tonnage_Inc__c, Sales_tonnage_charge_thereafter__c,
                        Rebate_Sales_Total__c, Rebate_Supplier_Price_Total__c, Client_Transport_Deduction__c, Supplier_Transport_Deduction__c,
                        Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c,
                        Order_Product__r.Transport__c,
                        Order_Product__r.Transport_Per_Tonne__c,
                        Order_Product__r.Transport_Per_Unit__c,
                        Order_Product__r.Secondary_Transport_Charge__c,
                        Order_Product__r.Secondary_Transport_P_T__c,
                        Order_Product__r.Secondary_Transport_Per_Tonne__c,
                        Order_Product__r.Secondary_Transport_Per_Unit__c,
                        Order_Product__r.Secondary_Haulier__c
                 FROM RLCS_Job__c
                 WHERE Id IN :jobsToProcessByRebateId.keySet()]
            );
            jobsToProcessByRebateId = jobsWithDescriptionFields;
        }

        if (jobsToProcessByRebateId.size() > 0) {
            // Loop through and get a map of all of the current auto job charges that are not linked to a locked sales invoice
            Map<String, RLCS_Charge__c> jobChargesByKey = new Map<String, RLCS_Charge__c>();
            Map<String, RLCS_Charge__c> jobChargesByKeyLocked = new Map<String, RLCS_Charge__c>();
            Map<String, RLCS_Charge__c> jobChargesByKeyVendorLocked = new Map<String, RLCS_Charge__c>();
            for (RLCS_Charge__c jobCharge : [SELECT Id, RecordTypeId, Charge_Type__c, Cost__c, Sales_Price__c, RLCS_Job__c,Date__c, Collection_Date__c, Description__c, Vendor_Account__c, Sales_Account__c, VAT__c, Haulier__c
                                                FROM RLCS_Charge__c
                                                WHERE RLCS_Job__c IN:jobsToProcessByRebateId.keySet()
                                                    AND RecordType.DeveloperName =:RLCSChargeService.JOB_CHARGE_RECORD_TYPE_AUTO]) {
                	jobChargesByKey.put(jobCharge.RLCS_Job__c + '~' + jobCharge.Charge_Type__c, jobCharge);
            }

            // Loop through the jobs and create/update charges
            for (RLCS_Job__c job : jobsToProcessByRebateId.values()) {

                // Create the charge for the rebate value if there are amounts at this stage
                RLCS_Charge__c rebateJobCharge = jobChargesByKey.get(job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_REBATE);
                //if (job.Sales_Cost__c > 0 || job.Supplier_Cost__c > 0) {
                if (job.Rebate_Sales_Total__c > 0 || job.Rebate_Supplier_Price_Total__c > 0) {
                    // Create or update the job charge
                    if (rebateJobCharge == null) {rebateJobCharge = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_REBATE); }
                    //RLCS_Charge__c updatedRebateJobCharge = RLCSChargeService.updateJobCharge(rebateJobCharge, job.Sales_Cost__c, job.Supplier_Cost__c, job.Delivery_Date__c, job.Haullier__c, job.Customer_Account__c);
                    Double rebateSalesTotal = (job.Rebate_Sales_Total__c > 0 ? job.Rebate_Sales_Total__c : 0) - (job.Client_Transport_Deduction__c  > 0 ? job.Client_Transport_Deduction__c  : 0);
                    Double rebateSupplierTotal = (job.Rebate_Supplier_Price_Total__c > 0 ? job.Rebate_Supplier_Price_Total__c : 0) - (job.Supplier_Transport_Deduction__c > 0 ? job.Supplier_Transport_Deduction__c : 0);
                    RLCS_Charge__c updatedRebateJobCharge = RLCSChargeService.updateJobCharge(rebateJobCharge, job, rebateSalesTotal, rebateSupplierTotal, job.Processor__c, job.Customer_Account__c, job.Haullier__c, job.VAT__c);
                    if (updatedRebateJobCharge != null) {
                        newUpdatedJobCharges.add(updatedRebateJobCharge);
                    }
                } else {
                    // There are no longer any values so remove the job charge
                    if (rebateJobCharge?.Id != null) {
                        jobChargesToDeleteMap.put(rebateJobCharge.Id, rebateJobCharge);
                    }
                }

                // Create the charge fro the transport part of the rebate job
                RLCS_Charge__c transportJobCharge = jobChargesByKey.get(job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_TRANSPORT);
                Decimal supplierTransport = (job.Order_Product__r?.Transport_Per_Tonne__c ? (job.Material_Weight_Tonnes__c ?? 0) : job.Order_Product__r?.Transport_Per_Unit__c ? (job.Unit_Count__c ?? 0) : 1) * (job.Order_Product__r?.Transport__c ?? 0);
                if (job.Sales_Transport__c > 0 || supplierTransport > 0) { 
                    if (transportJobCharge == null) {transportJobCharge = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_TRANSPORT); }
                    RLCS_Charge__c updatedRebateJobCharge = RLCSChargeService.updateJobCharge(transportJobCharge, job, supplierTransport, job.Sales_Transport__c, job.Processor__c, job.Customer_Account__c, job.Haullier__c, job.VAT__c);
                    if (updatedRebateJobCharge != null) {newUpdatedJobCharges.add(updatedRebateJobCharge);} 
                } else {
                    // There are no longer any values so remove the job charge
                    if (transportJobCharge?.Id != null) {
                        jobChargesToDeleteMap.put(transportJobCharge.Id, transportJobCharge);
                    }
                }
            }
        }

        // Re-query jobs for weight changes to get description fields
        if (jobsToProcessByWeightChangesId.size() > 0) {
            Map<Id, RLCS_Job__c> jobsWithDescriptionFields = new Map<Id, RLCS_Job__c>(
                [SELECT Id, Material_Weight_Tonnes__c, Unit_Count__c, Transport_Per_Tonne__c, Transport_Per_Unit__c,
                        Transport__c, Sales_Transport__c, Customer_Account__c, Haullier__c, Processor__c, VAT__c,
                        Supplier_Cost__c, Sales_Cost__c, Additional_Weight_Cost__c, Additional_Weight_Sales_Price__c,
                        Pricing_Method__c, Sales_Tonnage_Inc__c, Sales_tonnage_charge_thereafter__c,
                        Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c,
                        Order_Product__r.Transport__c,
                        Order_Product__r.Transport_Per_Tonne__c,
                        Order_Product__r.Transport_Per_Unit__c,
                        Order_Product__r.Secondary_Transport_Charge__c,
                        Order_Product__r.Secondary_Transport_P_T__c,
                        Order_Product__r.Secondary_Transport_Per_Tonne__c,
                        Order_Product__r.Secondary_Transport_Per_Unit__c,
                        Order_Product__r.Secondary_Haulier__c
                 FROM RLCS_Job__c
                 WHERE Id IN :jobsToProcessByWeightChangesId.keySet()]
            );
            jobsToProcessByWeightChangesId = jobsWithDescriptionFields;
        }

        if (jobsToProcessByWeightChangesId.size() > 0) {
            // Loop through and get a map of all of the current auto job charges that are not linked to a locked sales invoice
            Map<String, RLCS_Charge__c> jobChargesByKey = new Map<String, RLCS_Charge__c>();
            Map<String, RLCS_Charge__c> jobChargesByKeyLocked = new Map<String, RLCS_Charge__c>();
                   for (RLCS_Charge__c jobCharge : [SELECT Id, RecordTypeId, Charge_Type__c, Cost__c, Sales_Price__c, RLCS_Job__c,Date__c, Collection_Date__c, Description__c, Vendor_Account__c, Sales_Account__c,Vendor_Invoice_Locked__c,Sales_Invoice_Locked__c, VAT__c, Haulier__c
                                                FROM RLCS_Charge__c
                                                WHERE RLCS_Job__c IN:jobsToProcessByWeightChangesId.keySet()
                                                    AND RecordType.DeveloperName =:RLCSChargeService.JOB_CHARGE_RECORD_TYPE_AUTO ]) {
				if(!jobCharge.Vendor_Invoice_Locked__c && !jobCharge.Sales_Invoice_Locked__c){
                	jobChargesByKey.put(jobCharge.RLCS_Job__c + '~' + jobCharge.Charge_Type__c, jobCharge);
                }
                else
                {
                    jobChargesByKeyLocked.put(jobCharge.RLCS_Job__c + '~' + jobCharge.Charge_Type__c, jobCharge);

                }
            }

            // Loop through the jobs and create/update charges

            for (RLCS_Job__c job : jobsToProcessByWeightChangesId.values()) {
                
                // If this is not a rebate job then try and create / update the job job charge and tonnage
                String key=job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_JOB;
                // Try and find the job charge
                RLCS_Charge__c jobChargeJob = jobChargesByKey.get(key);
                boolean skipJobCRU = false;
                if (jobChargeJob == null) {
                    //check if an invoice locked job charge exists
                    if(jobChargesByKeyLocked.containsKey(key)){
                        jobChargeJob = jobChargesByKeyLocked.get(key);
                        //first check if there is an tonnage change
                        if (jobsToProcessByAdditionalWeightChangesId.containsKey(job.Id)){
                            skipJobCRU=true; // don't update the locked job charge
                        }   
                    }
                    else {
                        jobChargeJob = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_JOB);
                    } 
                }
                
                // Update the Job job charge and update the map
             		if(!skipJobCRU)
                    {
                        if(jobChargeJob != null && (job.Supplier_Cost__c > 0 || job.Sales_Cost__c > 0))
                        {
                            RLCS_Charge__c updatedJobChargeJob = RLCSChargeService.updateJobCharge(jobChargeJob, job, job.Supplier_Cost__c, job.Sales_Cost__c, job.Customer_Account__c, job.Processor__c, job.Haullier__c, job.VAT__c);
                            if (updatedJobChargeJob != null && !updates.contains(key)) {
                                newUpdatedJobCharges.add(updatedJobChargeJob);
                                updates.add(key);
                            }
                            system.debug('updatedJobChargeJob:' + updatedJobChargeJob);
                        }else {
                            // There is no additional charge, so if there is a job charge, mark it for deletion
                            if(jobChargeJob?.Id != null){
                                jobChargesToDeleteMap.put(jobChargeJob.Id, jobChargeJob);
                            }
                        }
                    }
                

                // Either update the tonnage or remove it, if there is no longer any additional tonnage
                String tonnageKey = job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE;
                RLCS_Charge__c jobChargeTonnage = jobChargesByKey.get(tonnageKey);
                 if (job.Additional_Weight_Cost__c > 0 || job.Additional_Weight_Sales_Price__c > 0) {
                    // There is a tonnage charge so create or update the job charge
                    if (jobChargeTonnage == null) {
                        if(jobChargesByKeyLocked.containsKey(tonnageKey))
                        {
                            errorJob = jobsToProcessByWeightChangesId.values()[0];
                            errorJob.addError('There is an Invoice Locked Tonnage Charge! Edits are not allowed.');

                            jobChargeTonnage = jobChargesByKeyLocked.get(tonnageKey);
                       }
                        else
                        {
                            system.debug('No tonnage found creating a tonnage charge');
                             if(job.Pricing_Method__c != fixedJobPricingMethod){
                            	jobChargeTonnage = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_TONNAGE);
                             }
                        }

                    }
                     
					if(!updates.contains(tonnageKey)) {
                    // Update the Tonnage job charge and update the map
                        RLCS_Charge__c updatedTonnageChargeJob = RLCSChargeService.updateJobCharge(jobChargeTonnage, job, job.Additional_Weight_Cost__c, job.Additional_Weight_Sales_Price__c, job.Customer_Account__c, job.Processor__c, job.Haullier__c, job.VAT__c);
                        if (updatedTonnageChargeJob != null) {
                            newUpdatedJobCharges.add(updatedTonnageChargeJob);
                            updates.add(tonnageKey);
                        }
                    }

                } else {
                    // There is no additional charge, so if there is a job charge, mark it for deletion
                    if (jobChargeTonnage?.Id != null) {
                        jobChargesToDeleteMap.put(jobChargeTonnage.Id, jobChargeTonnage);
                    }
                }


                // PRIMARY TRANSPORT CHARGE
                // Read from OrderItem (source of truth), NOT from job.Transport__c
                Decimal primaryTransportRate = job.Order_Product__r?.Transport__c ?? 0;
                Decimal primaryTransportAmount = (job.Order_Product__r?.Transport_Per_Tonne__c ?
                    (job.Material_Weight_Tonnes__c ?? 0) :
                    job.Order_Product__r?.Transport_Per_Unit__c ? (job.Unit_Count__c ?? 0) :
                    1) * primaryTransportRate;

                RLCS_Charge__c transportJobCharge = jobChargesByKey.get(job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_TRANSPORT);

                if (job.Sales_Transport__c > 0 || primaryTransportAmount > 0) {
                    if (transportJobCharge == null) {
                        transportJobCharge = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_TRANSPORT);
                    }
                    RLCS_Charge__c updatedTransportCharge = RLCSChargeService.updateJobCharge(
                        transportJobCharge,
                        job,
                        primaryTransportAmount,
                        job.Sales_Transport__c,
                        job.Customer_Account__c,
                        job.Haullier__c ?? job.Processor__c,
                        job.Haullier__c,
                        job.VAT__c
                    );
                    if (updatedTransportCharge != null) {
                        newUpdatedJobCharges.add(updatedTransportCharge);
                    }
                } else {
                    // There are no longer any values so remove the job charge
                    if (transportJobCharge?.Id != null) {
                        jobChargesToDeleteMap.put(transportJobCharge.Id, transportJobCharge);
                    }
                }

                // SECONDARY TRANSPORT CHARGE (NEW LOGIC)
                if (job.Order_Product__r?.Secondary_Transport_Charge__c == true) {
                    RLCS_Charge__c secondaryTransportCharge = jobChargesByKey.get(job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT);

                    // Determine calculation method (per tonne, per unit, or per load)
                    Decimal secondaryTransportAmount = 0;
                    Decimal secondaryTransportRate = job.Order_Product__r?.Secondary_Transport_P_T__c ?? 0;

                    if (job.Order_Product__r?.Secondary_Transport_Per_Tonne__c == true) {
                        secondaryTransportAmount = (job.Material_Weight_Tonnes__c ?? 0) * secondaryTransportRate;
                    } else if (job.Order_Product__r?.Secondary_Transport_Per_Unit__c == true) {
                        secondaryTransportAmount = (job.Unit_Count__c ?? 0) * secondaryTransportRate;
                    } else {
                        secondaryTransportAmount = 1 * secondaryTransportRate;
                    }

                    if (secondaryTransportAmount > 0) {
                        if (secondaryTransportCharge == null) {
                            secondaryTransportCharge = RLCSChargeService.createAutoJobCharge(job,RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT);
                        }

                        Id secondaryHaulier = job.Order_Product__r?.Secondary_Haulier__c != null ?
                            job.Order_Product__r.Secondary_Haulier__c :
                            job.Haullier__c;

                        RLCS_Charge__c updatedSecondaryCharge = RLCSChargeService.updateJobCharge(
                            secondaryTransportCharge,
                            job,
                            secondaryTransportAmount,
                            0,
                            job.Customer_Account__c,
                            secondaryHaulier,
                            secondaryHaulier,
                            job.VAT__c
                        );
                        if (updatedSecondaryCharge != null) {
                            newUpdatedJobCharges.add(updatedSecondaryCharge);
                        }
                    } else {
                        if (secondaryTransportCharge?.Id != null) {
                            jobChargesToDeleteMap.put(secondaryTransportCharge.Id, secondaryTransportCharge);
                        }
                    }
                } else {
                    RLCS_Charge__c secondaryTransportCharge = jobChargesByKey.get(job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT);
                    if (secondaryTransportCharge?.Id != null) {
                        jobChargesToDeleteMap.put(secondaryTransportCharge.Id, secondaryTransportCharge);
                    }
                }
            }

            // If there are records to update then
        }


        // If there are records to update then
        Boolean errorsFound = false;
        if (newUpdatedJobCharges.size() > 0) {
            // Attempt to update the job charges and if there are any problems then catch and display the message against the first job
            try {
                Database.upsert(newUpdatedJobCharges,true);

            } catch (DmlException e) {
                // This just gets the first one. That may not be the one that has failed
                Id jobChargeErrorId = e.getDmlId(0);
                String errorMessage = 'Error Updating Automatic Job Charge : ' + e.getDmlMessage(0);
                if (jobChargeErrorId != null) {
                    errorMessage += ' (' + jobChargeErrorId + ')';
                }

                // Add the error message to the first job
                if (errorJob != null){
                    errorJob.addError(errorMessage);
                }
                else{
                    errorJob = newUpdatedJobs[0];
                    errorJob.addError(errorMessage);
                }

                // Errors found
                errorsFound = true;

            }
        }

        // If there are records to delete then delete them
        if (jobChargesToDeleteMap.size() > 0 && errorsFound == false) {
            try {
                Database.delete(jobChargesToDeleteMap.values(),true);
            } catch (DmlException e) {
                // This just gets the first one. That may not be the one that has failed
                Id jobChargeErrorId = e.getDmlId(0);
                String errorMessage = 'Error Deleting Automatic Job Charge : ' + e.getDmlMessage(0);
                if (jobChargeErrorId != null) {
                    errorMessage += ' (' + jobChargeErrorId + ')';
                }

                // Add the error message to the first job
                if (errorJob != null){
                    errorJob.addError(errorMessage);
                }
                else{
                    errorJob = newUpdatedJobs[0];
                    errorJob.addError(errorMessage);
                }

                // Errors found
                errorsFound = true;

            }
        }

    }
}