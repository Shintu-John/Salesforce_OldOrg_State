trigger InvoiceTrigger on Invoice__c (after insert,after update,before delete) {
    if(Trigger.isInsert && Trigger.isAfter){ 
        InvoiceTriggerHandler.afterInsert(Trigger.new,Trigger.newMap);
    }
    if(Trigger.isUpdate && Trigger.isAfter){ 
        InvoiceTriggerHandler.afterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    else if (Trigger.isDelete && Trigger.isBefore) { 
        InvoiceTriggerHandler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }
}