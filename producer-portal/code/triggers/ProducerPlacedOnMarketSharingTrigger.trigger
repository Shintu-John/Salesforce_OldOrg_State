/**
 * @description Automatically share Producer_Placed_on_Market__c records with Account portal users
 * @created 2025-10-21
 */
trigger ProducerPlacedOnMarketSharingTrigger on Producer_Placed_on_Market__c (after insert, after update) {

    List<Producer_Placed_on_Market__c> recordsToShare = new List<Producer_Placed_on_Market__c>();

    if (Trigger.isInsert) {
        recordsToShare = Trigger.new;
    } else if (Trigger.isUpdate) {
        // Only share if Account__c changed
        for (Producer_Placed_on_Market__c record : Trigger.new) {
            if (record.Account__c != Trigger.oldMap.get(record.Id).Account__c) {
                recordsToShare.add(record);
            }
        }
    }

    if (!recordsToShare.isEmpty()) {
        ProducerSharingHelper.sharePlacedOnMarkets(recordsToShare);
    }
}