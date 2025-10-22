/**
 * @description Automatically share Producer_Contract__c records with Account portal users
 * @created 2025-10-21
 */
trigger ProducerContractSharingTrigger on Producer_Contract__c (after insert, after update) {

    List<Producer_Contract__c> recordsToShare = new List<Producer_Contract__c>();

    if (Trigger.isInsert) {
        recordsToShare = Trigger.new;
    } else if (Trigger.isUpdate) {
        // Only share if Account__c changed
        for (Producer_Contract__c record : Trigger.new) {
            if (record.Account__c != Trigger.oldMap.get(record.Id).Account__c) {
                recordsToShare.add(record);
            }
        }
    }

    if (!recordsToShare.isEmpty()) {
        ProducerSharingHelper.shareContracts(recordsToShare);
    }
}