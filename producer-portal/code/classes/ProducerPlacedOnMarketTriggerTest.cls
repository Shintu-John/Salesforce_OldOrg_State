@isTest
public class ProducerPlacedOnMarketTriggerTest {
    
    public static testmethod void testProducerPlacedOnMarketTrigger_WithQuestions(){
        Account producer = RLCS_UtilityTest.createProducerAccount(true);
        Producer_Contract__c producerContract = RLCS_UtilityTest.createProducerContract(false, producer.Id);
        producerContract.Obligation_Type__c = 'Household';
        insert producerContract;
        
        ManagePlacedOnMarketDataAction.manage(new List<String>{producerContract.Id});
		        
        List<Producer_Placed_on_Market__c> relatedRecords = [
            SELECT Id, RecordTypeId, Account__c, Quarter_With_Year__c,
            Category_1_Household__c, Category_2_Household__c, Category_3_Household__c,
            Category_4_Household__c, Category_5_Household__c, Category_6_Household__c,
            Category_7_Household__c, Category_8_Household__c, Category_9_Household__c,
            Category_10_Household__c, Category_11_Household__c, Category_12_Household__c,
            Category_13_Household__c, Category_14_Household__c, Category_15_Household__c,
            Category_1_Non_Household__c, Category_2_Non_Household__c, Category_3_Non_Household__c,
            Category_4_Non_Household__c, Category_5_Non_Household__c, Category_6_Non_Household__c,
            Category_7_Non_Household__c, Category_8_Non_Household__c, Category_9_Non_Household__c,
            Category_10_Non_Household__c, Category_11_Non_Household__c, Category_12_Non_Household__c,
            Category_13_Non_Household__c, Category_14_Non_Household__c, Category_15_Non_Household__c
            FROM Producer_Placed_on_Market__c
            WHERE Account__c = :producer.Id
        ];
        Integer index = 1;
        for(Producer_Placed_on_Market__c market : relatedRecords){
            market.Category_1_Household__c = 0;
            market.Category_2_Household__c = 0;
            market.Category_3_Household__c = 0;
            market.Category_4_Household__c = 0;
            market.Category_5_Household__c = 0;
            market.Category_6_Household__c = 0;
            market.Category_7_Household__c = 0;
            market.Category_8_Household__c = 0;
            market.Category_9_Household__c = 0;
            market.Category_10_Household__c = 0;
            market.Category_11_Household__c = 0;
            market.Category_12_Household__c = 0;
            market.Category_13_Household__c = 0;
            market.Category_14_Household__c = 0;
            market.Category_15_Household__c = 0;
            
            market.Category_1_Non_Household__c = index;
            market.Category_2_Non_Household__c = index;
            market.Category_3_Non_Household__c = index;
            market.Category_4_Non_Household__c = index;
            market.Category_5_Non_Household__c = index;
            market.Category_6_Non_Household__c = index;
            market.Category_7_Non_Household__c = index;
            market.Category_8_Non_Household__c = index;
            market.Category_9_Non_Household__c = index;
            market.Category_10_Non_Household__c = index;
            market.Category_11_Non_Household__c = index;
            market.Category_12_Non_Household__c = index;
            market.Category_13_Non_Household__c = index;
            market.Category_14_Non_Household__c = index;
            market.Category_15_Non_Household__c = index;
            
            index *= 2;
        }
        update relatedRecords;
        
        RLCS_UtilityTest.acknowledgeMarketData(producer.Id); 
    }
    
     public static testmethod void testProducerPlacedOnMarketTrigger_ZeroTotal(){
        Account producer = RLCS_UtilityTest.createProducerAccount(true);
        Producer_Contract__c producerContract = RLCS_UtilityTest.createProducerContract(false, producer.Id);
        producerContract.Obligation_Type__c = 'Household';
        insert producerContract;
        
        ManagePlacedOnMarketDataAction.manage(new List<String>{producerContract.Id});
        
        List<Producer_Placed_on_Market__c> relatedRecords = [
            SELECT Id, RecordTypeId, Account__c, Quarter_With_Year__c,
            Category_1_Household__c, Category_2_Household__c, Category_3_Household__c,
            Category_4_Household__c, Category_5_Household__c, Category_6_Household__c,
            Category_7_Household__c, Category_8_Household__c, Category_9_Household__c,
            Category_10_Household__c, Category_11_Household__c, Category_12_Household__c,
            Category_13_Household__c, Category_14_Household__c, Category_15_Household__c,
            Category_1_Non_Household__c, Category_2_Non_Household__c, Category_3_Non_Household__c,
            Category_4_Non_Household__c, Category_5_Non_Household__c, Category_6_Non_Household__c,
            Category_7_Non_Household__c, Category_8_Non_Household__c, Category_9_Non_Household__c,
            Category_10_Non_Household__c, Category_11_Non_Household__c, Category_12_Non_Household__c,
            Category_13_Non_Household__c, Category_14_Non_Household__c, Category_15_Non_Household__c
            FROM Producer_Placed_on_Market__c
            WHERE Account__c = :producer.Id
        ];
        
        for(Producer_Placed_on_Market__c market : relatedRecords){
            market.Category_1_Household__c = 0;
            market.Category_2_Household__c = 0;
            market.Category_3_Household__c = 0;
            market.Category_4_Household__c = 0;
            market.Category_5_Household__c = 0;
            market.Category_6_Household__c = 0;
            market.Category_7_Household__c = 0;
            market.Category_8_Household__c = 0;
            market.Category_9_Household__c = 0;
            market.Category_10_Household__c = 0;
            market.Category_11_Household__c = 0;
            market.Category_12_Household__c = 0;
            market.Category_13_Household__c = 0;
            market.Category_14_Household__c = 0;
            market.Category_15_Household__c = 0;
            
            market.Category_1_Non_Household__c = 0;
            market.Category_2_Non_Household__c = 0;
            market.Category_3_Non_Household__c = 0;
            market.Category_4_Non_Household__c = 0;
            market.Category_5_Non_Household__c = 0;
            market.Category_6_Non_Household__c = 0;
            market.Category_7_Non_Household__c = 0;
            market.Category_8_Non_Household__c = 0;
            market.Category_9_Non_Household__c = 0;
            market.Category_10_Non_Household__c = 0;
            market.Category_11_Non_Household__c = 0;
            market.Category_12_Non_Household__c = 0;
            market.Category_13_Non_Household__c = 0;
            market.Category_14_Non_Household__c = 0;
            market.Category_15_Non_Household__c = 0;
        }
        update relatedRecords;
        
        RLCS_UtilityTest.acknowledgeMarketData(producer.Id); 
         relatedRecords[0].Category_1_Household__c = 10;
         update relatedRecords;
    }
    
    public static testmethod void testProducerPlacedOnMarketTrigger_Household(){
        Account producer = RLCS_UtilityTest.createProducerAccount(true);
        Producer_Contract__c producerContract = RLCS_UtilityTest.createProducerContract(false, producer.Id);
        producerContract.Obligation_Type__c = 'Household';
        insert producerContract;
        
        ManagePlacedOnMarketDataAction.manage(new List<String>{producerContract.Id});
        
        List<Producer_Placed_on_Market__c> relatedRecords = [
            SELECT Id, RecordTypeId, Account__c, Quarter_With_Year__c,
            Category_1_Household__c, Category_2_Household__c, Category_3_Household__c,
            Category_4_Household__c, Category_5_Household__c, Category_6_Household__c,
            Category_7_Household__c, Category_8_Household__c, Category_9_Household__c,
            Category_10_Household__c, Category_11_Household__c, Category_12_Household__c,
            Category_13_Household__c, Category_14_Household__c, Category_15_Household__c,
            Category_1_Non_Household__c, Category_2_Non_Household__c, Category_3_Non_Household__c,
            Category_4_Non_Household__c, Category_5_Non_Household__c, Category_6_Non_Household__c,
            Category_7_Non_Household__c, Category_8_Non_Household__c, Category_9_Non_Household__c,
            Category_10_Non_Household__c, Category_11_Non_Household__c, Category_12_Non_Household__c,
            Category_13_Non_Household__c, Category_14_Non_Household__c, Category_15_Non_Household__c
            FROM Producer_Placed_on_Market__c
            WHERE Account__c = :producer.Id
        ];
        
        for(Producer_Placed_on_Market__c market : relatedRecords){
            market.Category_1_Household__c = 1;
            market.Category_2_Household__c = 1;
            market.Category_3_Household__c = 1;
            market.Category_4_Household__c = 1;
            market.Category_5_Household__c = 1;
            market.Category_6_Household__c = 1;
            market.Category_7_Household__c = 1;
            market.Category_8_Household__c = 1;
            market.Category_9_Household__c = 1;
            market.Category_10_Household__c = 1;
            market.Category_11_Household__c = 1;
            market.Category_12_Household__c = 1;
            market.Category_13_Household__c = 1;
            market.Category_14_Household__c = 1;
            market.Category_15_Household__c = 1;
            
            market.Category_1_Non_Household__c = 1;
            market.Category_2_Non_Household__c = 1;
            market.Category_3_Non_Household__c = 1;
            market.Category_4_Non_Household__c = 1;
            market.Category_5_Non_Household__c = 1;
            market.Category_6_Non_Household__c = 1;
            market.Category_7_Non_Household__c = 1;
            market.Category_8_Non_Household__c = 1;
            market.Category_9_Non_Household__c = 1;
            market.Category_10_Non_Household__c = 1;
            market.Category_11_Non_Household__c = 1;
            market.Category_12_Non_Household__c = 1;
            market.Category_13_Non_Household__c = 1;
            market.Category_14_Non_Household__c = 1;
            market.Category_15_Non_Household__c = 1;
        }
        update relatedRecords;
        
        RLCS_UtilityTest.acknowledgeMarketData(producer.Id);
        
        producerContract.Obligation_Type__c = 'Household & Non-Household';
        update producerContract;
        
        relatedRecords[0].Category_1_Non_Household__c = 1.2;
        update relatedRecords[0]; 
    }
    
    public static testmethod void testProducerPlacedOnMarketTrigger_NonHousehold(){
        Account producer = RLCS_UtilityTest.createProducerAccount(true);
        Producer_Contract__c producerContract = RLCS_UtilityTest.createProducerContract(false, producer.Id);
        producerContract.Obligation_Type__c = 'Non-Household';
        insert producerContract;
        
        ManagePlacedOnMarketDataAction.manage(new List<String>{producerContract.Id});
        
        List<Producer_Placed_on_Market__c> relatedRecords = [
            SELECT Id, RecordTypeId, Account__c, Quarter_With_Year__c,
            Category_1_Household__c, Category_2_Household__c, Category_3_Household__c,
            Category_4_Household__c, Category_5_Household__c, Category_6_Household__c,
            Category_7_Household__c, Category_8_Household__c, Category_9_Household__c,
            Category_10_Household__c, Category_11_Household__c, Category_12_Household__c,
            Category_13_Household__c, Category_14_Household__c, Category_15_Household__c,
            Category_1_Non_Household__c, Category_2_Non_Household__c, Category_3_Non_Household__c,
            Category_4_Non_Household__c, Category_5_Non_Household__c, Category_6_Non_Household__c,
            Category_7_Non_Household__c, Category_8_Non_Household__c, Category_9_Non_Household__c,
            Category_10_Non_Household__c, Category_11_Non_Household__c, Category_12_Non_Household__c,
            Category_13_Non_Household__c, Category_14_Non_Household__c, Category_15_Non_Household__c
            FROM Producer_Placed_on_Market__c
            WHERE Account__c = :producer.Id
        ];
        
        for(Producer_Placed_on_Market__c market : relatedRecords){
            market.Category_1_Household__c = 1;
            market.Category_2_Household__c = 1;
            market.Category_3_Household__c = 1;
            market.Category_4_Household__c = 1;
            market.Category_5_Household__c = 1;
            market.Category_6_Household__c = 1;
            market.Category_7_Household__c = 1;
            market.Category_8_Household__c = 1;
            market.Category_9_Household__c = 1;
            market.Category_10_Household__c = 1;
            market.Category_11_Household__c = 1;
            market.Category_12_Household__c = 1;
            market.Category_13_Household__c = 1;
            market.Category_14_Household__c = 1;
            market.Category_15_Household__c = 1;
            
            market.Category_1_Non_Household__c = 1;
            market.Category_2_Non_Household__c = 1;
            market.Category_3_Non_Household__c = 1;
            market.Category_4_Non_Household__c = 1;
            market.Category_5_Non_Household__c = 1;
            market.Category_6_Non_Household__c = 1;
            market.Category_7_Non_Household__c = 1;
            market.Category_8_Non_Household__c = 1;
            market.Category_9_Non_Household__c = 1;
            market.Category_10_Non_Household__c = 1;
            market.Category_11_Non_Household__c = 1;
            market.Category_12_Non_Household__c = 1;
            market.Category_13_Non_Household__c = 1;
            market.Category_14_Non_Household__c = 1;
            market.Category_15_Non_Household__c = 1;
        }
        update relatedRecords;
        
        RLCS_UtilityTest.acknowledgeMarketData(producer.Id);
        
        
        producerContract.Obligation_Type__c = 'Household & Non-Household';
        update producerContract; 
    }
    
    public static testmethod void testProducerPlacedOnMarketTrigger_Household_Non_Household(){
        Account producer = RLCS_UtilityTest.createProducerAccount(true);
        Producer_Contract__c producerContract = RLCS_UtilityTest.createProducerContract(false, producer.Id);
        producerContract.Obligation_Type__c = 'Household & Non-Household';
        insert producerContract;
        
        ManagePlacedOnMarketDataAction.manage(new List<String>{producerContract.Id});
        
        List<Producer_Placed_on_Market__c> relatedRecords = [
            SELECT Id, RecordTypeId, Account__c, Quarter_With_Year__c,
            Category_1_Household__c, Category_2_Household__c, Category_3_Household__c,
            Category_4_Household__c, Category_5_Household__c, Category_6_Household__c,
            Category_7_Household__c, Category_8_Household__c, Category_9_Household__c,
            Category_10_Household__c, Category_11_Household__c, Category_12_Household__c,
            Category_13_Household__c, Category_14_Household__c, Category_15_Household__c,
            Category_1_Non_Household__c, Category_2_Non_Household__c, Category_3_Non_Household__c,
            Category_4_Non_Household__c, Category_5_Non_Household__c, Category_6_Non_Household__c,
            Category_7_Non_Household__c, Category_8_Non_Household__c, Category_9_Non_Household__c,
            Category_10_Non_Household__c, Category_11_Non_Household__c, Category_12_Non_Household__c,
            Category_13_Non_Household__c, Category_14_Non_Household__c, Category_15_Non_Household__c
            FROM Producer_Placed_on_Market__c
            WHERE Account__c = :producer.Id
        ];
        
        for(Producer_Placed_on_Market__c market : relatedRecords){
            market.Category_1_Household__c = 1;
            market.Category_2_Household__c = 1;
            market.Category_3_Household__c = 1;
            market.Category_4_Household__c = 1;
            market.Category_5_Household__c = 1;
            market.Category_6_Household__c = 1;
            market.Category_7_Household__c = 1;
            market.Category_8_Household__c = 1;
            market.Category_9_Household__c = 1;
            market.Category_10_Household__c = 1;
            market.Category_11_Household__c = 1;
            market.Category_12_Household__c = 1;
            market.Category_13_Household__c = 1;
            market.Category_14_Household__c = 1;
            market.Category_15_Household__c = 1;
            
            market.Category_1_Non_Household__c = 1;
            market.Category_2_Non_Household__c = 1;
            market.Category_3_Non_Household__c = 1;
            market.Category_4_Non_Household__c = 1;
            market.Category_5_Non_Household__c = 1;
            market.Category_6_Non_Household__c = 1;
            market.Category_7_Non_Household__c = 1;
            market.Category_8_Non_Household__c = 1;
            market.Category_9_Non_Household__c = 1;
            market.Category_10_Non_Household__c = 1;
            market.Category_11_Non_Household__c = 1;
            market.Category_12_Non_Household__c = 1;
            market.Category_13_Non_Household__c = 1;
            market.Category_14_Non_Household__c = 1;
            market.Category_15_Non_Household__c = 1;
        }
        update relatedRecords;
        
        RLCS_UtilityTest.acknowledgeMarketData(producer.Id);
        
        producerContract.Obligation_Type__c = 'Household';
        update producerContract;
        
        relatedRecords[0].Category_1_Non_Household__c = 1.2;
        update relatedRecords[0]; 
    }
}