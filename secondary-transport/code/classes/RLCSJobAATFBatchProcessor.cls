/**
 * Batch Apex class for processing large AATF CSV files
 * @author The Claude/Bagshaw Collective for Recycling Lives Services
 */
public class RLCSJobAATFBatchProcessor implements Database.Batchable<String>, Database.Stateful {
    // Store the original CSV content and parsed rows
    private List<List<String>> csvRows;
    
    // Store processing results
    private List<RLCS_Job__c> insertedJobs = new List<RLCS_Job__c>();
    private List<Integer> validRowIndices = new List<Integer>();
    private List<Map<String, Object>> errors = new List<Map<String, Object>>();
    
    // Store batch processing metadata
    private Id batchTrackerId;
    private Integer orderIdColIndex = -1;
    private Integer orderProductIdColIndex = -1;
    
    /**
     * Constructor
     * @param csvContent The CSV content to process
     * @param batchTrackerId Id of the batch tracker record
     */
    public RLCSJobAATFBatchProcessor(String csvContent, Id batchTrackerId) {
        this.batchTrackerId = batchTrackerId;
        
        // Parse the CSV content
        this.csvRows = RLCSJobAATFController.parseCSV(csvContent);
        
        // Find Order ID and Order Product ID columns
        if (!this.csvRows.isEmpty()) {
            List<String> headerRow = this.csvRows[0];
            
            for (Integer i = 0; i < headerRow.size(); i++) {
                String header = headerRow[i].trim();
                if (header == 'Order ID') {
                    this.orderIdColIndex = i;
                } else if (header == 'Order Product ID') {
                    this.orderProductIdColIndex = i;
                }
            }
            
            // If we couldn't find the columns, use default positions (last two columns)
            if (this.orderIdColIndex == -1) {
                this.orderIdColIndex = headerRow.size() - 2;
            }
            if (this.orderProductIdColIndex == -1) {
                this.orderProductIdColIndex = headerRow.size() - 1;
            }
        }
        
        // Update the batch tracker with column indices for debugging
        RLCS_Batch_Tracker__c tracker = new RLCS_Batch_Tracker__c(
            Id = this.batchTrackerId,
            Order_ID_Column__c = this.orderIdColIndex,
            Order_Product_ID_Column__c = this.orderProductIdColIndex,
            Total_Rows__c = this.csvRows.size() - 1 // Exclude header row
        );
        update tracker;
    }
    
    /**
     * Start method - return the CSV rows to process
     */
    public Iterable<String> start(Database.BatchableContext bc) {
        // Skip the header row (index 0)
        List<String> rowsToProcess = new List<String>();
        for (Integer i = 1; i < csvRows.size(); i++) {
            // Convert each row to a JSON string to pass to the execute method
            rowsToProcess.add(JSON.serialize(new Map<String, Object>{
                'rowIndex' => i,
                'rowData' => csvRows[i]
            }));
        }
        return rowsToProcess;
    }
    
    /**
     * Execute method - process each batch of rows
     */
    public void execute(Database.BatchableContext bc, List<String> scope) {
        List<RLCS_Job__c> jobsToInsert = new List<RLCS_Job__c>();
        Map<Integer, Integer> rowIndexToJobIndex = new Map<Integer, Integer>();
        Integer processedInBatch = 0;
        
        try {
            for (String rowJson : scope) {
                Map<String, Object> rowMap = (Map<String, Object>)JSON.deserializeUntyped(rowJson);
                Integer rowIndex = Integer.valueOf(rowMap.get('rowIndex'));
                List<Object> rowDataObj = (List<Object>)rowMap.get('rowData');
                
                // Convert Object list to String list
                List<String> row = new List<String>();
                for (Object obj : rowDataObj) {
                    row.add(String.valueOf(obj));
                }
                
                // Skip empty rows
                if (row.isEmpty()) {
                    continue;
                }
                
                // Skip if the row doesn't have enough columns
                if (row.size() <= Math.max(orderIdColIndex, orderProductIdColIndex)) {
                    continue;
                }
                
                // Get Order ID and Order Product ID
                String orderId = row[orderIdColIndex].trim();
                String orderProductId = row[orderProductIdColIndex].trim();
                
                // Validate IDs
                if (String.isBlank(orderId) || String.isBlank(orderProductId)) {
                    continue;
                }
                
                // Validate ID format (must start with 801/802 and be 15 or 18 chars)
                Boolean validOrderId = orderId.startsWith('801') && 
                                      (orderId.length() == 15 || orderId.length() == 18);
                Boolean validOrderProductId = orderProductId.startsWith('802') && 
                                            (orderProductId.length() == 15 || orderProductId.length() == 18);
                
                if (!validOrderId || !validOrderProductId) {
                    continue;
                }
                
                // Find the indices for Weightbridge Reference and Consignment Note Ticket
                Integer weighbridgeIndex = -1;
                Integer consignmentNoteTicketIndex = -1;
                Integer weeeTonnesIndex = -1;
                Integer weeeUnitsIndex = -1;

                // Check if we have at least 12 columns
                if (row.size() >= 12) {
                    weighbridgeIndex = 10; // 11th column (0-based index)
                    consignmentNoteTicketIndex = 11; // 12th column (0-based index)
                }

                // Check if we have columns 14 and 15 for WEEE Tonnes and WEEE Units
                if (row.size() >= 15) {
                    weeeTonnesIndex = 13; // 14th column (0-based index) - "WEEE Tonnes"
                    weeeUnitsIndex = 14; // 15th column (0-based index) - "WEEE Units"
                }

                // Create Job record with additional fields
                RLCS_Job__c job = new RLCS_Job__c(
                    Order__c = orderId,
                    Order_Product__c = orderProductId
                );

                // Add Weightbridge Reference if available
                if (weighbridgeIndex >= 0 && weighbridgeIndex < row.size()) {
                    job.Weightbridge_Reference__c = row[weighbridgeIndex].trim();
                }

                // Add Consignment Note Ticket if available
                if (consignmentNoteTicketIndex >= 0 && consignmentNoteTicketIndex < row.size()) {
                    job.Consignment_Note_Reference_Ticket__c = row[consignmentNoteTicketIndex].trim();
                }

                // Add Material Weight (Tonnes) if available
                if (weeeTonnesIndex >= 0 && weeeTonnesIndex < row.size()) {
                    String weightValue = row[weeeTonnesIndex].trim();
                    if (String.isNotBlank(weightValue)) {
                        try {
                            job.Material_Weight_Tonnes__c = Decimal.valueOf(weightValue);
                        } catch (Exception e) {
                            System.debug('Error parsing WEEE Tonnes value: ' + weightValue + ' - ' + e.getMessage());
                        }
                    }
                }

                // Add Unit Count if available
                if (weeeUnitsIndex >= 0 && weeeUnitsIndex < row.size()) {
                    String unitsValue = row[weeeUnitsIndex].trim();
                    if (String.isNotBlank(unitsValue)) {
                        try {
                            job.Unit_Count__c = Integer.valueOf(unitsValue);
                        } catch (Exception e) {
                            System.debug('Error parsing WEEE Units value: ' + unitsValue + ' - ' + e.getMessage());
                        }
                    }
                }
                
                jobsToInsert.add(job);
                rowIndexToJobIndex.put(rowIndex, processedInBatch);
                processedInBatch++;
            }
            
            // Insert jobs for this batch
            if (!jobsToInsert.isEmpty()) {
                insert jobsToInsert;
                
                // Query the inserted jobs to get generated fields
                List<RLCS_Job__c> insertedBatchJobs = [
                    SELECT Id, Order__c, Order_Product__c, Consignment_Note_Reference__c,
                           Weightbridge_Reference__c, Consignment_Note_Reference_Ticket__c
                    FROM RLCS_Job__c 
                    WHERE Id IN :jobsToInsert
                    ORDER BY CreatedDate ASC
                ];
                
                // Add to the overall list in the correct order based on row indices
                for (Integer rowIndex : rowIndexToJobIndex.keySet()) {
                    Integer jobIndex = rowIndexToJobIndex.get(rowIndex);
                    if (jobIndex < insertedBatchJobs.size()) {
                        this.insertedJobs.add(insertedBatchJobs[jobIndex]);
                        this.validRowIndices.add(rowIndex);
                    }
                }
                
                // Update batch tracker with progress
                RLCS_Batch_Tracker__c tracker = [
                    SELECT Id, Processed_Records__c 
                    FROM RLCS_Batch_Tracker__c 
                    WHERE Id = :batchTrackerId
                ];
                
                tracker.Processed_Records__c = (tracker.Processed_Records__c != null ? 
                                               tracker.Processed_Records__c : 0) + jobsToInsert.size();
                update tracker;
            }
        } catch (Exception e) {
            // Handle errors
            this.errors.add(new Map<String, Object>{
                'message' => 'Error processing batch: ' + e.getMessage(),
                'stackTrace' => e.getStackTraceString()
            });
            
            // Log error to tracker
            RLCS_Batch_Tracker__c tracker = [
                SELECT Id, Error_Messages__c 
                FROM RLCS_Batch_Tracker__c 
                WHERE Id = :batchTrackerId
            ];
            
            tracker.Error_Messages__c = (String.isBlank(tracker.Error_Messages__c) ? '' : 
                                        tracker.Error_Messages__c + '\n\n') + 
                                        'Batch error: ' + e.getMessage() + '\n' + e.getStackTraceString();
            update tracker;
        }
    }
    
    /**
     * Finish method - generate the final output CSV and update the tracker
     */
    public void finish(Database.BatchableContext bc) {
        try {
            // Generate output CSV
            String outputCSV = RLCSJobAATFController.generateOutputCSV(csvRows, validRowIndices, insertedJobs);
            String filename = RLCSJobAATFController.generateFileName(csvRows);
            
            // Create a ContentVersion to store the CSV
            ContentVersion cv = new ContentVersion();
            cv.Title = filename + '.csv';
            cv.PathOnClient = filename + '.csv';
            cv.VersionData = Blob.valueOf(outputCSV);
            cv.IsMajorVersion = true;
            insert cv;
            
            // Get the ContentDocumentId
            ContentVersion insertedCv = [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv.Id 
                LIMIT 1
            ];
            
            // Update the batch tracker with results
            RLCS_Batch_Tracker__c tracker = [
                SELECT Id, Status__c 
                FROM RLCS_Batch_Tracker__c 
                WHERE Id = :batchTrackerId 
                LIMIT 1
            ];
            
            if (this.errors.isEmpty()) {
                tracker.Status__c = 'Completed';
                tracker.Content_Document_Id__c = insertedCv.ContentDocumentId;
                tracker.Filename__c = filename;
                tracker.Job_Count__c = this.insertedJobs.size();
                
                // Empty error messages if we succeeded after previous errors
                tracker.Error_Messages__c = null;
            } else {
                tracker.Status__c = 'Failed';
                tracker.Error_Messages__c = (String.isBlank(tracker.Error_Messages__c) ? '' : 
                                          tracker.Error_Messages__c + '\n\n') + 
                                          'Final errors: ' + JSON.serialize(this.errors);
            }
            
            update tracker;
            
            // Publish platform event
            RLCS_Batch_Complete__e batchEvent = new RLCS_Batch_Complete__e(
                Batch_Id__c = bc.getJobId(),
                Tracker_Id__c = batchTrackerId,
                Status__c = tracker.Status__c
            );
            EventBus.publish(batchEvent);
        } catch (Exception e) {
            // Update the tracker with error
            RLCS_Batch_Tracker__c tracker = [
                SELECT Id, Status__c, Error_Messages__c 
                FROM RLCS_Batch_Tracker__c 
                WHERE Id = :batchTrackerId 
                LIMIT 1
            ];
            
            tracker.Status__c = 'Failed';
            tracker.Error_Messages__c = (String.isBlank(tracker.Error_Messages__c) ? '' : 
                                      tracker.Error_Messages__c + '\n\n') + 
                                      'Finish method error: ' + e.getMessage() + '\n' + e.getStackTraceString();
            
            update tracker;
            
            // Publish platform event
            RLCS_Batch_Complete__e batchEvent = new RLCS_Batch_Complete__e(
                Batch_Id__c = bc.getJobId(),
                Tracker_Id__c = batchTrackerId,
                Status__c = 'Failed'
            );
            EventBus.publish(batchEvent);
        }
    }
}