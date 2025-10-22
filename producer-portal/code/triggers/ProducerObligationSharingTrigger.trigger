/**
 * @description Automatically share Producer_Obligation__c records with Account portal users
 * @created 2025-10-21
 */
trigger ProducerObligationSharingTrigger on Producer_Obligation__c (after insert, after update) {

    List<Producer_Obligation__c> recordsToShare = new List<Producer_Obligation__c>();

    if (Trigger.isInsert) {
        recordsToShare = Trigger.new;
    } else if (Trigger.isUpdate) {
        // Only share if Producer_Contract__c changed
        for (Producer_Obligation__c record : Trigger.new) {
            if (record.Producer_Contract__c != Trigger.oldMap.get(record.Id).Producer_Contract__c) {
                recordsToShare.add(record);
            }
        }
    }

    if (!recordsToShare.isEmpty()) {
        ProducerSharingHelper.shareObligations(recordsToShare);
    }
}