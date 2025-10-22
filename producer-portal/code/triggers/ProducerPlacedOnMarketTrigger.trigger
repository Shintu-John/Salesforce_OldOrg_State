trigger ProducerPlacedOnMarketTrigger on Producer_Placed_on_Market__c (before Insert, after Insert, before update, after Update) {
    if(Trigger.isBefore){
        if(Trigger.isInsert) ProducerPlacedOnMarketTriggerHandler.beforeInsert(Trigger.new);
        if(Trigger.isUpdate) ProducerPlacedOnMarketTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }else if(Trigger.isAfter){
        if(Trigger.isInsert) ProducerPlacedOnMarketTriggerHandler.afterInsert(Trigger.new);
        if( Trigger.isUpdate) ProducerPlacedOnMarketTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}