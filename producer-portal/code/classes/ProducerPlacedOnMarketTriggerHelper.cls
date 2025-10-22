public without sharing class ProducerPlacedOnMarketTriggerHelper {
    public static Id householdRecordTypeId = Schema.SObjectType.Producer_Placed_on_Market__c.getRecordTypeInfosByDeveloperName().get('Household').getRecordTypeId();
    public static Id nonHouseholdRecordTypeId = Schema.SObjectType.Producer_Placed_on_Market__c.getRecordTypeInfosByDeveloperName().get('Non_Household').getRecordTypeId();
    public static Id bothRecordTypeId = Schema.SObjectType.Producer_Placed_on_Market__c.getRecordTypeInfosByDeveloperName().get('Household_Non_Household').getRecordTypeId();
    
    public static List<Id> weeeRecordTypeIds = new List<Id>{householdRecordTypeId, nonHouseholdRecordTypeId, bothRecordTypeId};
    
    /* manage question start */    
    public static void manageQuestions(List<Producer_Placed_on_Market__c> recs, Map<Id, Producer_Placed_on_Market__c> oldMap){
        Set<Id> recIds = new Set<Id>();
        
        for(Producer_Placed_on_Market__c rec :recs){
            if(weeeRecordTypeIds.contains(rec.RecordTypeId) && rec.Acknowledgement_of_Statements__c && rec.Acknowledgement_of_Statements__c != oldMap.get(rec.Id).Acknowledgement_of_Statements__c) recIds.add(rec.Id);
        }
        manageQuestions(recIds);
    }
    
    public static void manageQuestions(Set<Id> recIds) {
        if(recIds == null || recIds.size() == 0) return;
        // Query the current and related records
        List<Producer_Placed_on_Market__c> records = [
            SELECT Id, Name, RecordTypeId, Category_Household_Total__c, Category_Non_Household_Total__c, 
            Category_1_Household__c, Category_2_Household__c, Category_3_Household__c, Category_4_Household__c, Category_5_Household__c,
            Category_6_Household__c, Category_7_Household__c, Category_8_Household__c, Category_9_Household__c, Category_10_Household__c,
            Category_11_Household__c, Category_12_Household__c, Category_13_Household__c, Category_14_Household__c, Category_15_Household__c,
            Category_1_Non_Household__c, Category_2_Non_Household__c, Category_3_Non_Household__c, Category_4_Non_Household__c, Category_5_Non_Household__c,
            Category_6_Non_Household__c, Category_7_Non_Household__c, Category_8_Non_Household__c, Category_9_Non_Household__c, Category_10_Non_Household__c,
            Category_11_Non_Household__c, Category_12_Non_Household__c, Category_13_Non_Household__c, Category_14_Non_Household__c, Category_15_Non_Household__c,
            Last_Quarter_Producer_Placed_on_Market__c, 
            Last_Year_Producer_Placed_on_Market__c,
            Last_Quarter_Producer_Placed_on_Market__r.Quarter_With_Year__c, Last_Quarter_Producer_Placed_on_Market__r.Acknowledgement_of_Statements__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_1_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_2_Household__c, 
            Last_Quarter_Producer_Placed_on_Market__r.Category_3_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_4_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_5_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_6_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_7_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_8_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_9_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_10_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_11_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_12_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_13_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_14_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_15_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_1_Non_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_2_Non_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_3_Non_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_4_Non_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_5_Non_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_6_Non_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_7_Non_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_8_Non_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_9_Non_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_10_Non_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_11_Non_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_12_Non_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_13_Non_Household__c, Last_Quarter_Producer_Placed_on_Market__r.Category_14_Non_Household__c,
            Last_Quarter_Producer_Placed_on_Market__r.Category_15_Non_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Quarter_With_Year__c, Last_Year_Producer_Placed_on_Market__r.Acknowledgement_of_Statements__c,
            Last_Year_Producer_Placed_on_Market__r.Category_1_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_2_Household__c, 
            Last_Year_Producer_Placed_on_Market__r.Category_3_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_4_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_5_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_6_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_7_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_8_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_9_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_10_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_11_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_12_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_13_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_14_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_15_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_1_Non_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_2_Non_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_3_Non_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_4_Non_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_5_Non_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_6_Non_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_7_Non_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_8_Non_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_9_Non_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_10_Non_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_11_Non_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_12_Non_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_13_Non_Household__c, Last_Year_Producer_Placed_on_Market__r.Category_14_Non_Household__c,
            Last_Year_Producer_Placed_on_Market__r.Category_15_Non_Household__c
            FROM Producer_Placed_on_Market__c
            WHERE Id IN :recIds
            
        ];
        
        // Fetch existing questions to avoid duplicates
        Map<Id, Set<String>> existingQuestionsMap = new Map<Id, Set<String>>();
        List<Validation_Question__c> existingValidationQuestions = [
            SELECT Producer_Placed_on_Market__c, Name 
            FROM Validation_Question__c 
            WHERE Producer_Placed_on_Market__c IN :recIds
        ];
        for (Validation_Question__c question : existingValidationQuestions) {
            if (!existingQuestionsMap.containsKey(question.Producer_Placed_on_Market__c)) {
                existingQuestionsMap.put(question.Producer_Placed_on_Market__c, new Set<String>());
            }
            existingQuestionsMap.get(question.Producer_Placed_on_Market__c).add(question.Name);
        }
        
        List<Validation_Question__c> questionsToInsert = new List<Validation_Question__c>();
        // Iterate over records and calculate variances for Category_1
        for (Producer_Placed_on_Market__c record : records) {
            Set<String> existingQuestions = existingQuestionsMap.get(record.Id);
            
            if(record.RecordTypeId == bothRecordTypeId || record.RecordTypeId == householdRecordTypeId){
                Decimal currentCategory1Household = record.Category_1_Household__c;
                Decimal lastQuarterCategory1Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_1_Household__c;
                Decimal lastYearCategory1Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_1_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory1Household, lastQuarterCategory1Household, lastYearCategory1Household, 'Category 1 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory2Household = record.Category_2_Household__c;
                Decimal lastQuarterCategory2Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_2_Household__c;
                Decimal lastYearCategory2Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_2_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory2Household, lastQuarterCategory2Household, lastYearCategory2Household, 'Category 2 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory3Household = record.Category_3_Household__c;
                Decimal lastQuarterCategory3Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_3_Household__c;
                Decimal lastYearCategory3Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_3_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory3Household, lastQuarterCategory3Household, lastYearCategory3Household, 'Category 3 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory4Household = record.Category_4_Household__c;
                Decimal lastQuarterCategory4Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_4_Household__c;
                Decimal lastYearCategory4Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_4_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory4Household, lastQuarterCategory4Household, lastYearCategory4Household, 'Category 4 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory5Household = record.Category_5_Household__c;
                Decimal lastQuarterCategory5Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_5_Household__c;
                Decimal lastYearCategory5Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_5_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory5Household, lastQuarterCategory5Household, lastYearCategory5Household, 'Category 5 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory6Household = record.Category_6_Household__c;
                Decimal lastQuarterCategory6Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_6_Household__c;
                Decimal lastYearCategory6Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_6_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory6Household, lastQuarterCategory6Household, lastYearCategory6Household, 'Category 6 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory7Household = record.Category_7_Household__c;
                Decimal lastQuarterCategory7Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_7_Household__c;
                Decimal lastYearCategory7Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_7_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory7Household, lastQuarterCategory7Household, lastYearCategory7Household, 'Category 7 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory8Household = record.Category_8_Household__c;
                Decimal lastQuarterCategory8Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_8_Household__c;
                Decimal lastYearCategory8Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_8_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory8Household, lastQuarterCategory8Household, lastYearCategory8Household, 'Category 8 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory9Household = record.Category_9_Household__c;
                Decimal lastQuarterCategory9Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_9_Household__c;
                Decimal lastYearCategory9Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_9_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory9Household, lastQuarterCategory9Household, lastYearCategory9Household, 'Category 9 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory10Household = record.Category_10_Household__c;
                Decimal lastQuarterCategory10Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_10_Household__c;
                Decimal lastYearCategory10Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_10_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory10Household, lastQuarterCategory10Household, lastYearCategory10Household, 'Category 10 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory11Household = record.Category_11_Household__c;
                Decimal lastQuarterCategory11Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_11_Household__c;
                Decimal lastYearCategory11Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_11_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory11Household, lastQuarterCategory11Household, lastYearCategory11Household, 'Category 11 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory12Household = record.Category_12_Household__c;
                Decimal lastQuarterCategory12Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_12_Household__c;
                Decimal lastYearCategory12Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_12_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory12Household, lastQuarterCategory12Household, lastYearCategory12Household, 'Category 12 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory13Household = record.Category_13_Household__c;
                Decimal lastQuarterCategory13Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_13_Household__c;
                Decimal lastYearCategory13Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_13_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory13Household, lastQuarterCategory13Household, lastYearCategory13Household, 'Category 13 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory14Household = record.Category_14_Household__c;
                Decimal lastQuarterCategory14Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_14_Household__c;
                Decimal lastYearCategory14Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_14_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory14Household, lastQuarterCategory14Household, lastYearCategory14Household, 'Category 14 Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory15Household = record.Category_15_Household__c;
                Decimal lastQuarterCategory15Household = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_15_Household__c;
                Decimal lastYearCategory15Household = record.Last_Year_Producer_Placed_on_Market__r?.Category_15_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory15Household, lastQuarterCategory15Household, lastYearCategory15Household, 'Category 15 Household', questionsToInsert, existingQuestions);
            }
            
            if(record.RecordTypeId == bothRecordTypeId || record.RecordTypeId == nonHouseholdRecordTypeId){
                Decimal currentCategory1NonHousehold = record.Category_1_Non_Household__c;
                Decimal lastQuarterCategory1NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_1_Non_Household__c;
                Decimal lastYearCategory1NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_1_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory1NonHousehold, lastQuarterCategory1NonHousehold, lastYearCategory1NonHousehold, 'Category 1 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory2NonHousehold = record.Category_2_Non_Household__c;
                Decimal lastQuarterCategory2NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_2_Non_Household__c;
                Decimal lastYearCategory2NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_2_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory2NonHousehold, lastQuarterCategory2NonHousehold, lastYearCategory2NonHousehold, 'Category 2 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory3NonHousehold = record.Category_3_Non_Household__c;
                Decimal lastQuarterCategory3NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_3_Non_Household__c;
                Decimal lastYearCategory3NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_3_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory3NonHousehold, lastQuarterCategory3NonHousehold, lastYearCategory3NonHousehold, 'Category 3 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory4NonHousehold = record.Category_4_Non_Household__c;
                Decimal lastQuarterCategory4NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_4_Non_Household__c;
                Decimal lastYearCategory4NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_4_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory4NonHousehold, lastQuarterCategory4NonHousehold, lastYearCategory4NonHousehold, 'Category 4 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory5NonHousehold = record.Category_5_Non_Household__c;
                Decimal lastQuarterCategory5NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_5_Non_Household__c;
                Decimal lastYearCategory5NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_5_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory5NonHousehold, lastQuarterCategory5NonHousehold, lastYearCategory5NonHousehold, 'Category 5 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory6NonHousehold = record.Category_6_Non_Household__c;
                Decimal lastQuarterCategory6NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_6_Non_Household__c;
                Decimal lastYearCategory6NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_6_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory6NonHousehold, lastQuarterCategory6NonHousehold, lastYearCategory6NonHousehold, 'Category 6 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory7NonHousehold = record.Category_7_Non_Household__c;
                Decimal lastQuarterCategory7NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_7_Non_Household__c;
                Decimal lastYearCategory7NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_7_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory7NonHousehold, lastQuarterCategory7NonHousehold, lastYearCategory7NonHousehold, 'Category 7 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory8NonHousehold = record.Category_8_Non_Household__c;
                Decimal lastQuarterCategory8NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_8_Non_Household__c;
                Decimal lastYearCategory8NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_8_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory8NonHousehold, lastQuarterCategory8NonHousehold, lastYearCategory8NonHousehold, 'Category 8 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory9NonHousehold = record.Category_9_Non_Household__c;
                Decimal lastQuarterCategory9NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_9_Non_Household__c;
                Decimal lastYearCategory9NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_9_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory9NonHousehold, lastQuarterCategory9NonHousehold, lastYearCategory9NonHousehold, 'Category 9 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory10NonHousehold = record.Category_10_Non_Household__c;
                Decimal lastQuarterCategory10NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_10_Non_Household__c;
                Decimal lastYearCategory10NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_10_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory10NonHousehold, lastQuarterCategory10NonHousehold, lastYearCategory10NonHousehold, 'Category 10 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory11NonHousehold = record.Category_11_Non_Household__c;
                Decimal lastQuarterCategory11NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_11_Non_Household__c;
                Decimal lastYearCategory11NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_11_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory11NonHousehold, lastQuarterCategory11NonHousehold, lastYearCategory11NonHousehold, 'Category 11 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory12NonHousehold = record.Category_12_Non_Household__c;
                Decimal lastQuarterCategory12NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_12_Non_Household__c;
                Decimal lastYearCategory12NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_12_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory12NonHousehold, lastQuarterCategory12NonHousehold, lastYearCategory12NonHousehold, 'Category 12 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory13NonHousehold = record.Category_13_Non_Household__c;
                Decimal lastQuarterCategory13NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_13_Non_Household__c;
                Decimal lastYearCategory13NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_13_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory13NonHousehold, lastQuarterCategory13NonHousehold, lastYearCategory13NonHousehold, 'Category 13 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory14NonHousehold = record.Category_14_Non_Household__c;
                Decimal lastQuarterCategory14NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_14_Non_Household__c;
                Decimal lastYearCategory14NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_14_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory14NonHousehold, lastQuarterCategory14NonHousehold, lastYearCategory14NonHousehold, 'Category 14 Non-Household', questionsToInsert, existingQuestions);
                
                Decimal currentCategory15NonHousehold = record.Category_15_Non_Household__c;
                Decimal lastQuarterCategory15NonHousehold = record.Last_Quarter_Producer_Placed_on_Market__r?.Category_15_Non_Household__c;
                Decimal lastYearCategory15NonHousehold = record.Last_Year_Producer_Placed_on_Market__r?.Category_15_Non_Household__c;
                checkVarianceAndCreateQuestion(record, currentCategory15NonHousehold, lastQuarterCategory15NonHousehold, lastYearCategory15NonHousehold, 'Category 15 Non-Household', questionsToInsert, existingQuestions);
            }
            
            if((record.Category_Household_Total__c ?? 0) + (record.Category_Non_Household_Total__c ?? 0) == 0){
                String zeroTotalQuestionName = generateZeroTotalQuestion();
                if (existingQuestions == null || !existingQuestions.contains(zeroTotalQuestionName)) {
                    questionsToInsert.add(new Validation_Question__c(
                        Producer_Placed_on_Market__c = record.Id,
                        Name = zeroTotalQuestionName,
                        Reason__c = 'Zero Total'
                    ));
                }
            }
        }
        
        // Insert validation questions
        if (!questionsToInsert.isEmpty()) {
            insert questionsToInsert;
        }
    }
    
    // Helper method to check variance and create questions
    private static void checkVarianceAndCreateQuestion(Producer_Placed_on_Market__c record, Decimal currentTonnage, Decimal lastQuarterTonnage, Decimal lastYearTonnage, String categoryType, List<Validation_Question__c> questionsToInsert, Set<String> existingQuestions) {
        Map<String, Decimal> tonnageThresholds = new Map<String, Decimal>{
            '0.25to1' => 500, '1to5' => 350, '5to15' => 150, '15to50' => 75, '50to200' => 50, '200plus' => 25
                };

        // Data integrity check: Ensure Last Quarter and Last Year don't have same Quarter_with_Year__c
        if (record.Last_Quarter_Producer_Placed_on_Market__r?.Quarter_with_Year__c != null
            && record.Last_Year_Producer_Placed_on_Market__r?.Quarter_with_Year__c != null
            && record.Last_Quarter_Producer_Placed_on_Market__r?.Quarter_with_Year__c
               == record.Last_Year_Producer_Placed_on_Market__r?.Quarter_with_Year__c) {
            System.debug(LoggingLevel.ERROR, 'Data Integrity Issue - Last Quarter and Last Year have same Quarter_with_Year__c: '
                         + record.Last_Quarter_Producer_Placed_on_Market__r?.Quarter_with_Year__c
                         + ' for record: ' + record.Id);
        }

        Map<String, Decimal> compareTonnageMap = new Map<String, Decimal>{
            record.Last_Quarter_Producer_Placed_on_Market__r?.Quarter_with_Year__c => lastQuarterTonnage,
                record.Last_Year_Producer_Placed_on_Market__r?.Quarter_with_Year__c => lastYearTonnage
                };  
                                
        // Check new/dropped categories and variances for BOTH last quarter and last year
        for (String quarterWithYear: compareTonnageMap.keyset()) {
            // Explicit null check for defensive programming
            if(quarterWithYear == null || String.isBlank(quarterWithYear)) continue;

            Decimal comparisonTonnage = compareTonnageMap.get(quarterWithYear);

            // Check for NEW category (current has value, comparison was zero/null)
            if(currentTonnage != null && currentTonnage > 0 && (comparisonTonnage == null || comparisonTonnage == 0)){
                String questionName = generateNewCategoryQuestion(quarterWithYear, categoryType);
                if (existingQuestions == null || !existingQuestions.contains(questionName)) {
                    questionsToInsert.add(new Validation_Question__c(
                        Producer_Placed_on_Market__c = record.Id,
                        Name = questionName,
                        Reason__c = 'New Category',
                        Current_Tonnage_Stamp__c =  currentTonnage,
                        Comparision_Tonnage_Stamp__c =comparisonTonnage
                    ));
                }
            }
            // Check for DROPPED category (current is zero/null, comparison had value)
            else if(comparisonTonnage != null && comparisonTonnage > 0 && (currentTonnage == null || currentTonnage == 0)){
                String questionName = generateOldCategoryQuestion(quarterWithYear, categoryType);
                if (existingQuestions == null || !existingQuestions.contains(questionName)) {
                    questionsToInsert.add(new Validation_Question__c(
                        Producer_Placed_on_Market__c = record.Id,
                        Name = questionName,
                        Reason__c = 'Zero Total',
                        Current_Tonnage_Stamp__c =  currentTonnage,
                        Comparision_Tonnage_Stamp__c =comparisonTonnage
                    ));
                }
            }
            // Check for VARIANCE (both have values)
            else if (comparisonTonnage != null && currentTonnage != null && comparisonTonnage > 0) {
                // Safe: currentTonnage and comparisonTonnage guaranteed > 0 here due to line 316 check
                // Formula: |((current - previous) / previous)| * 100 = percentage variance
                Decimal variance = Math.abs(((currentTonnage - comparisonTonnage) / comparisonTonnage) * 100);
                Decimal threshold = getThreshold(comparisonTonnage, tonnageThresholds);

                if (threshold > 0 && variance >= threshold) {
                    // Generate the question using a separate helper function
                    String questionName = generateThresholdQuestion(quarterWithYear, categoryType, threshold, currentTonnage, comparisonTonnage);

                    // Check if a question already exists for this record
                    if (existingQuestions == null || !existingQuestions.contains(questionName)) {
                        questionsToInsert.add(new Validation_Question__c(
                            Producer_Placed_on_Market__c = record.Id,
                            Name = questionName,
                            Reason__c = 'Variance',
                            Current_Tonnage_Stamp__c =  currentTonnage,
                            Comparision_Tonnage_Stamp__c =comparisonTonnage
                        ));
                    }
                }
            }
        }
    }
    
    private static string generateZeroTotalQuestion(){
         String questionName = 'Why has 0 tonnes been submitted?';
        return questionName;
    }
    
    private static string generateNewCategoryQuestion(String quarterWithYear, String categoryType){
        String questionName = 'Why does ' + categoryType + ' have a value despite no values in ' + quarterWithYear + '?';
        return questionName;
    }
    
    private static string generateOldCategoryQuestion(String quarterWithYear, String categoryType){
        String questionName = 'Why does ' + categoryType + ' not have a value despite values in ' + quarterWithYear + '?';
        return questionName;
    }
    // Separate helper function to generate the question string
    private static String generateThresholdQuestion(String quarterWithYear, String categoryType, Decimal threshold, Decimal currentTonnage, Decimal comparisonTonnage) {
        String increasedOrDecreased = comparisonTonnage < currentTonnage ? 'increased' : 'decreased';
        String questionName = 'Why has ' + categoryType + ' EEE ' + increasedOrDecreased + ' by over ' + String.valueOf(threshold) + '% versus '+ quarterWithYear + '?';
        return questionName;
    }
    
    // Helper method to get threshold based on tonnage
    private static Decimal getThreshold(Decimal currentTonnage, Map<String, Decimal> tonnageThresholds) {
        // Stakeholder confirmed: Small tonnages (< 0.25) should still be validated if they differ from previous periods
        // Use highest threshold (500%) for very small tonnages to catch significant variances
        if (currentTonnage < 0.25) {
            return tonnageThresholds.get('0.25to1'); // 500% threshold for small tonnages
        } else if (currentTonnage >= 0.25 && currentTonnage < 1) {
            return tonnageThresholds.get('0.25to1'); // 500%
        } else if (currentTonnage >= 1 && currentTonnage < 5) {
            return tonnageThresholds.get('1to5'); // 350%
        } else if (currentTonnage >= 5 && currentTonnage < 15) {
            return tonnageThresholds.get('5to15'); // 300%
        } else if (currentTonnage >= 15 && currentTonnage < 50) {
            return tonnageThresholds.get('15to50'); // 250%
        } else if (currentTonnage >= 50 && currentTonnage < 200) {
            return tonnageThresholds.get('50to200'); // 200%
        } else if (currentTonnage >= 200) {
            return tonnageThresholds.get('200plus'); // 150%
        }
        return 0; // Should never reach here
    }
    
    
    /* manage question end */
    
    /* link last quarter and last year quarter producer placed on market start */
    public static List<Producer_Placed_on_Market__c> linkProducerPlacedOnMarket(List<Producer_Placed_on_Market__c> recs, Map<Id, Producer_Placed_on_Market__c> oldMap){
        List<Producer_Placed_on_Market__c> recordToProcess = new List<Producer_Placed_on_Market__c>();
        
        for(Producer_Placed_on_Market__c rec :recs){
            if(oldMap == null || rec.RecordTypeId != oldMap.get(rec.Id).RecordTypeId
               || rec.Type__c != oldMap.get(rec.Id).Type__c
               || rec.Account__c != oldMap.get(rec.Id).Account__c
               || rec.Quarter__c != oldMap.get(rec.Id).Quarter__c
               || rec.Acknowledgement_of_Statements__c != oldMap.get(rec.Id).Acknowledgement_of_Statements__c
               || rec.Compliance_Year__c != oldMap.get(rec.Id).Compliance_Year__c) recordToProcess.add(rec);
        }
        return linkProducerPlacedOnMarket(recordToProcess);
    }
    
    public static List<Producer_Placed_on_Market__c> linkProducerPlacedOnMarket(List<Producer_Placed_on_Market__c> recs){
        if(recs == null || recs.size() == 0){return recs;}
        Set<Id> accountIds = new Set<Id>();
        Set<Id> recordTypeIds = new Set<Id>();
        for(Producer_Placed_on_Market__c rec :recs){
            accountIds.add(rec.Account__c);
            recordTypeIds.add(rec.RecordTypeId);
        }
        
        Map<String, Producer_Placed_on_Market__c> relatedMap = new Map<String, Producer_Placed_on_Market__c>();
        for(Producer_Placed_on_Market__c rec : [Select Id, Type__c, Account__c, Quarter__c, Compliance_Year__c
                                                from Producer_Placed_on_Market__c 
                                                Where Account__c IN :accountIds and RecordTypeId IN :recordTypeIds]){
                                                    String key = rec.Account__c + '|' + rec.Quarter__c + '|' + rec.Compliance_Year__c + '|' + rec.Type__c;
                                                    relatedMap.put(key, rec);
                                                }
        
        Map<Id, Producer_Placed_on_Market__c> recToUpdateMap = new Map<Id, Producer_Placed_on_Market__c>();
        for(Producer_Placed_on_Market__c rec :recs){
            String lastQuarterKey = rec.Account__c + '|' + 
                (rec.Quarter__c == 'Q1' ? 'Q4' : 'Q' + String.valueOf(Integer.valueOf(rec.Quarter__c.right(1)) - 1)) + '|' + 
                (rec.Quarter__c == 'Q1' ? String.valueOf(Integer.valueOf(rec.Compliance_Year__c) - 1) : rec.Compliance_Year__c) + '|' + 
                rec.Type__c;
            String lastYearQuarterKey = rec.Account__c + '|' +  rec.Quarter__c + '|' + 
                String.valueOf(Integer.valueOf(rec.Compliance_Year__c) - 1) + '|' +  
                rec.Type__c;
            
            recToUpdateMap.put(rec.Id,
                               new Producer_Placed_on_Market__c(
                                   Id = rec.Id,
                                   Last_Quarter_Producer_Placed_on_Market__c = relatedMap.get(lastQuarterKey)?.Id,
                                   Last_Year_Producer_Placed_on_Market__c = relatedMap.get(lastYearQuarterKey)?.Id
                               ));
        }
        
        return recToUpdateMap.values();
        
    }
    /* link last quarter and last year quarter producer placed on market end */
}