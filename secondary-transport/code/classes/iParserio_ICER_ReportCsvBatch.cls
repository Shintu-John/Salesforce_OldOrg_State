public class iParserio_ICER_ReportCsvBatch implements Database.Batchable<sObject> {
    
    public static void runBatch(List<String> documentIds){
        if(System.isFuture() || System.isBatch()){
            String query = getQuery();
           	new iParserio_ICER_ReportCsvBatch(null).execute(null, Database.query(query));
        }else{
            Database.executeBatch(new iParserio_ICER_ReportCsvBatch(documentIds), Integer.valueOf(Label.IcerReportBatchSize));
        }
    }
    
    private List<string> documentIds;
    
    String WEEE_MATERIAL_CATEGORY = 'WEEE Material Category'.toLowerCase();
    String TICKET_NO = 'Ticket No'.toLowerCase();
    String VEHICLE_LICENSE = 'Vehicle License'.toLowerCase();
    String DATE_COLLECTED = 'Date Collected'.toLowerCase();
    String DATE_RECEIVED = 'Date Received'.toLowerCase();
    String WASTE_NOTE_NUMBER = 'Waste Note Number'.toLowerCase();
    String MATERIAL_WEIGHT_TONNES = 'Material Weight (Tonnes)'.toLowerCase();
    String UNIT_COUNT = 'Unit Count'.toLowerCase();
    
    List<String> columnNames = new List<String>{WEEE_MATERIAL_CATEGORY, TICKET_NO, VEHICLE_LICENSE, DATE_COLLECTED, DATE_RECEIVED, WASTE_NOTE_NUMBER, 
        MATERIAL_WEIGHT_TONNES, UNIT_COUNT};
            
            
            public iParserio_ICER_ReportCsvBatch(List<String> documentIds) {
                this.documentIds = documentIds;
            }
    
    public static string getQuery(){
        String query = 'Select ';
        query += 'Id, iparseio__RowIndex__c, iparseio__ColumnName__c, iparseio__TransformValue__c, ';
        query += 'iparseio__TransformSuccess__c, iparseio__TransformApplied__c, iparseio__Value__c, iparseio__Document__c';
        query += ' FROM iparseio__CSVData__c';
        query += ' Where iparseio__Document__c IN :documentIds AND iparseio__ColumnName__c = :WASTE_NOTE_NUMBER  and iparseio__Document__c != null ';
        return query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getQuery());
    }
    
    public void execute(Database.BatchableContext bc, List<iparseio__CSVData__c> recs) {
        Set<String> consignmentNoteList = new Set<String>(); 
        Set<Double> rowIndexes = new Set<Double>();
        for(iparseio__CSVData__c rec : recs){
            String value = rec.iparseio__TransformApplied__c ? (rec.iparseio__TransformSuccess__c ? rec.iparseio__TransformValue__c : null)  : rec.iparseio__Value__c;
            if(String.isNotBlank(value)) consignmentNoteList.add(value);
            rowIndexes.add(rec.iparseio__RowIndex__c);
        }
        
        Map<String, RLCS_Job__c> jobMap = new Map<String, RLCS_Job__c>();
        for(RLCS_Job__c job : [SELECT Id, Consignment_Note_Reference__c 
                               , (Select Id, Material_Category__r.Name from Protocol_Breakdowns__r)
                               FROM RLCS_Job__c 
                               Where Consignment_Note_Reference__c IN :consignmentNoteList and Consignment_Note_Reference__c != null]){
                                   jobMap.put(job.Consignment_Note_Reference__c , job);
                               }
        
        
        List<iparseio__CSVData__c> csvData = [SELECT Id, iparseio__RowIndex__c, iparseio__ColumnName__c, iparseio__TransformValue__c, 
                                              iparseio__TransformSuccess__c, iparseio__TransformApplied__c, iparseio__Value__c, 
                                              iparseio__Document__c 
                                              FROM iparseio__CSVData__c
                                              Where iparseio__Document__c IN :documentIds
                                              AND iparseio__ColumnName__c IN :columnNames
                                              AND iparseio__RowIndex__c IN :rowIndexes];
        
        
        Map<String, Map<String, String>> rowsMap = new Map<String, Map<String, String>>();
        
        for(iparseio__CSVData__c rec : csvData){
            
            String value = rec.iparseio__TransformApplied__c ? (rec.iparseio__TransformSuccess__c ? rec.iparseio__TransformValue__c : null)  : rec.iparseio__Value__c;
            if(String.isBlank(value)){continue;}
            
            String key = rec.iparseio__Document__c + '~' + rec.iparseio__RowIndex__c;
            if(!rowsMap.containsKey(key)){
                rowsMap.put(key, new Map<String, String>());
            }
            rowsMap.get(key).put(rec.iparseio__ColumnName__c.toLowerCase(), value);
        }
        
        Map<String, RLCS_Job__c> jobsToUpdate = new Map<String, RLCS_Job__c>();
        List<Material_Category_Breakdown__c> categoryBreakDownToUpsert = new List<Material_Category_Breakdown__c>();
        for(String key : rowsMap.keyset()){
            Map<String, String> row = rowsMap.get(key);
            if(row.containsKey(WASTE_NOTE_NUMBER) && row.get(WASTE_NOTE_NUMBER) != null && jobMap.containsKey(row.get(WASTE_NOTE_NUMBER))){
                
                RLCS_Job__c job = jobMap.get(row.get(WASTE_NOTE_NUMBER));
                
                Map<String, Material_Category_Breakdown__c> breakdownMap = new Map<String, Material_Category_Breakdown__c>();
                for(Material_Category_Breakdown__c breakDown : job.Protocol_Breakdowns__r){
                    if(String.isBlank(breakDown.Material_Category__r?.Name)) continue;
                    breakdownMap.put(breakDown.Material_Category__r.Name.toLowerCase(), breakDown);
                }
                
                if(row.containsKey(TICKET_NO) && String.isNotBlank(row.get(TICKET_NO))){
                    job.Weightbridge_Reference__c = row.get(TICKET_NO);
                }
                if(row.containsKey(VEHICLE_LICENSE) && String.isNotBlank(row.get(VEHICLE_LICENSE))){
                    job.Vehicle_Reg__c = row.get(VEHICLE_LICENSE);
                }
                if(row.containsKey(DATE_COLLECTED) && String.isNotBlank(row.get(DATE_COLLECTED))){
                    job.Collected_Date__c = iParserio_Helper.convertToDate(row.get(DATE_COLLECTED));
                }
                if(row.containsKey(DATE_RECEIVED) && String.isNotBlank(row.get(DATE_RECEIVED))){
                    job.AATF_Received_Date__c = iParserio_Helper.convertToDate(row.get(DATE_RECEIVED));
                }
                job.CSV_Document__c = key.split('~')[0];

                // ALSO populate Job-level fields for Material_Weight_Tonnes__c and Unit_Count__c
                // This ensures charges calculate correctly (trigger will recalculate when these fields change)
                if(row.containsKey(MATERIAL_WEIGHT_TONNES) && String.isNotBlank(row.get(MATERIAL_WEIGHT_TONNES))){
                    job.Material_Weight_Tonnes__c = iParserio_Helper.convertToDecimal(row.get(MATERIAL_WEIGHT_TONNES));
                }
                if(row.containsKey(UNIT_COUNT) && String.isNotBlank(row.get(UNIT_COUNT))){
                    job.Unit_Count__c = iParserio_Helper.convertToInteger(row.get(UNIT_COUNT));
                }

                jobsToUpdate.put(job.Id, job);


                //MATERIAL CATEGORY BREAKDOWN
                Material_Category_Breakdown__c categoryBreakDownRec = new Material_Category_Breakdown__c();
                categoryBreakDownRec.RLCS_Job__c = job.Id;
                if(row.containsKey(MATERIAL_WEIGHT_TONNES) && String.isNotBlank(row.get(MATERIAL_WEIGHT_TONNES))){
                    categoryBreakDownRec.Material_Weight_Tonnes__c = iParserio_Helper.convertToDecimal(row.get(MATERIAL_WEIGHT_TONNES));
                }
                if(row.containsKey(WEEE_MATERIAL_CATEGORY) && String.isNotBlank(row.get(WEEE_MATERIAL_CATEGORY))){
                    categoryBreakDownRec.Material_Category_T__c = row.get(WEEE_MATERIAL_CATEGORY);
                    if(row.get(WEEE_MATERIAL_CATEGORY) != null && breakdownMap.containsKey(row.get(WEEE_MATERIAL_CATEGORY).toLowerCase())) categoryBreakDownRec.Id = breakdownMap.get(row.get(WEEE_MATERIAL_CATEGORY).toLowerCase()).Id;
                }
                if(row.containsKey(UNIT_COUNT) && String.isNotBlank(row.get(UNIT_COUNT))){
                    categoryBreakDownRec.Unit_Count__c = iParserio_Helper.convertToInteger(row.get(UNIT_COUNT));
                }
                categoryBreakDownToUpsert.add(categoryBreakDownRec);
            }
        }
        
        Update jobsToUpdate.values();
        Upsert categoryBreakDownToUpsert;
    }
    
    
    public void finish(Database.BatchableContext bc) {
        // Optional: Add post-processing logic here
    }
}