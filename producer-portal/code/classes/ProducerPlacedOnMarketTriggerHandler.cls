public without sharing class ProducerPlacedOnMarketTriggerHandler {
    public static void beforeInsert(List<Producer_Placed_on_Market__c> newList){
        //ProducerPlacedOnMarketTriggerHelper.populateDataInProducerPlacedOnMarket(newList);
    }
    public static void afterInsert(List<Producer_Placed_on_Market__c> newList){
        Update ProducerPlacedOnMarketTriggerHelper.linkProducerPlacedOnMarket(newList);
    }
    
    public static void beforeUpdate(List<Producer_Placed_on_Market__c> newList, Map<Id, Producer_Placed_on_Market__c> oldMap){
    }
    
    public static void afterUpdate(List<Producer_Placed_on_Market__c> newList, Map<Id, Producer_Placed_on_Market__c> oldMap){
        //ProducerPlacedOnMarketTriggerHelper.manageDataInProducerPlacedOnMarket(newList, oldMap); 
        ProducerPlacedOnMarketTriggerHelper.manageQuestions(newList, oldMap); 
        Update ProducerPlacedOnMarketTriggerHelper.linkProducerPlacedOnMarket(newList, oldMap);
    }
    
    
}