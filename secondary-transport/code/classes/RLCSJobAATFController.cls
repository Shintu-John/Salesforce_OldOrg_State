/**
 * Controller for processing AATF CSV files and creating RLCS_Job__c records
 * @author The Claude/Bagshaw Collective for Recycling Lives Services
 */
public with sharing class RLCSJobAATFController {
    
    /**
     * Start batch processing of CSV to create Job records
     * @param csvContent String representing the uploaded CSV file content
     * @return Map with processing results including batch ID and status
     */
    @AuraEnabled
    public static Map<String, Object> processCSVAndCreateJobsBatch(String csvContent) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Create a batch tracker
            RLCS_Batch_Tracker__c tracker = new RLCS_Batch_Tracker__c(
                Name = 'AATF Batch ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss'),
                Status__c = 'Processing',
                Processed_Records__c = 0
            );
            insert tracker;
            
            // Create and enqueue the batch job
            RLCSJobAATFBatchProcessor batchProcessor = new RLCSJobAATFBatchProcessor(csvContent, tracker.Id);
            Id batchId = Database.executeBatch(batchProcessor, 200); // Process 200 rows at a time
            
            // Update the tracker with the batch ID
            tracker.Batch_Id__c = batchId;
            update tracker;
            
            // Return the tracker ID to the LWC
            result.put('success', true);
            result.put('trackerId', tracker.Id);
            result.put('message', 'Processing started');
        } catch (Exception e) {
            result.put('success', false);
            result.put('errors', new List<Map<String, Object>>{
                new Map<String, Object>{
                    'message' => 'Error starting batch process: ' + e.getMessage(),
                    'stackTrace' => e.getStackTraceString()
                }
            });
        }
        
        return result;
    }
    
    /**
     * Check the status of a batch process
     * @param trackerId ID of the batch tracker record
     * @return Map with status and results
     */
    @AuraEnabled
    public static Map<String, Object> checkBatchStatus(Id trackerId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Query for the batch tracker
            RLCS_Batch_Tracker__c tracker = [
                SELECT Id, Batch_Id__c, Status__c, Content_Document_Id__c, Filename__c, 
                       Job_Count__c, Error_Messages__c, Total_Rows__c, Processed_Records__c
                FROM RLCS_Batch_Tracker__c
                WHERE Id = :trackerId
                LIMIT 1
            ];
            
            result.put('status', tracker.Status__c);
            
            // Calculate progress percentage
            if (tracker.Total_Rows__c != null && tracker.Total_Rows__c > 0 &&
                tracker.Processed_Records__c != null) {
                Decimal progress = (tracker.Processed_Records__c / tracker.Total_Rows__c) * 100;
                result.put('progress', Math.min(95, progress.setScale(0))); // Cap at 95% until fully complete
            } else {
                result.put('progress', 10); // Default progress if we don't have metrics yet
            }
            
            if (tracker.Status__c == 'Completed') {
                result.put('success', true);
                result.put('contentDocumentId', tracker.Content_Document_Id__c);
                result.put('filename', tracker.Filename__c);
                result.put('jobCount', tracker.Job_Count__c);
                
                // Get the CSV content if requested
                if (tracker.Content_Document_Id__c != null) {
                    List<ContentVersion> cvList = [
                        SELECT Id, VersionData
                        FROM ContentVersion
                        WHERE ContentDocumentId = :tracker.Content_Document_Id__c
                        AND IsLatest = true
                        LIMIT 1
                    ];
                    
                    if (!cvList.isEmpty()) {
                        result.put('outputCSV', cvList[0].VersionData.toString());
                    }
                }
            } else if (tracker.Status__c == 'Failed') {
                result.put('success', false);
                result.put('errors', new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'message' => 'Batch processing failed',
                        'details' => tracker.Error_Messages__c
                    }
                });
            } else {
                // Still processing
                result.put('success', true);
                result.put('message', 'Processing in progress');
            }
        } catch (Exception e) {
            result.put('success', false);
            result.put('errors', new List<Map<String, Object>>{
                new Map<String, Object>{
                    'message' => 'Error checking batch status: ' + e.getMessage(),
                    'stackTrace' => e.getStackTraceString()
                }
            });
        }
        
        return result;
    }
    
    /**
     * Main method to process CSV and create Job records (original, non-batch method)
     * Kept for small files and backward compatibility
     * @param csvContent String representing the uploaded CSV file content
     * @return Map with processing results including success flag, errors, and output CSV
     */
    @AuraEnabled
    public static Map<String, Object> processCSVAndCreateJobs(String csvContent) {
        Map<String, Object> result = new Map<String, Object>();
        List<RLCS_Job__c> jobsToInsert = new List<RLCS_Job__c>();
        List<List<String>> csvRows = new List<List<String>>();
        List<Map<String, Object>> errorRecords = new List<Map<String, Object>>();
        
        try {
            // Parse CSV
            csvRows = parseCSV(csvContent);
            
            System.debug('Total rows in CSV (including header): ' + csvRows.size());
            
            // Print the first few row contents to debug
            for (Integer i = 0; i < Math.min(5, csvRows.size()); i++) {
                System.debug('Row ' + i + ' content: ' + String.join(csvRows[i], '|'));
            }
            
            // Check if CSV has at least a header row
            if (csvRows.isEmpty()) {
                throw new CSVException('The CSV file appears to be empty');
            }
            
            List<String> headerRow = csvRows[0];
            
            // Find Order ID and Order Product ID columns
            Integer orderIdColIndex = -1;
            Integer orderProductIdColIndex = -1;
            
            for (Integer i = 0; i < headerRow.size(); i++) {
                String header = headerRow[i].trim();
                if (header == 'Order ID') {
                    orderIdColIndex = i;
                } else if (header == 'Order Product ID') {
                    orderProductIdColIndex = i;
                }
            }
            
            // If we couldn't find the columns, use default positions (last two columns)
            if (orderIdColIndex == -1) {
                orderIdColIndex = headerRow.size() - 2;
            }
            if (orderProductIdColIndex == -1) {
                orderProductIdColIndex = headerRow.size() - 1;
            }
            
            System.debug('Order ID column index: ' + orderIdColIndex);
            System.debug('Order Product ID column index: ' + orderProductIdColIndex);
            
            // Track which rows had valid jobs created
            List<Integer> validRowIndices = new List<Integer>();
            Map<Integer, String> rowContents = new Map<Integer, String>();
            
            // Process data rows (skip header)
            Integer validRows = 0;
            for (Integer i = 1; i < csvRows.size(); i++) {
                List<String> row = csvRows[i];
                
                // Skip empty rows
                if (row.isEmpty()) {
                    System.debug('Row ' + i + ' is empty, skipping');
                    continue;
                }
                
                // Log the first column content (Record number)
                String firstCol = row.size() > 0 ? row[0].trim() : '';
                rowContents.put(i, 'Row ' + i + ' first column: ' + firstCol);
                
                // Skip if the row doesn't have enough columns
                if (row.size() <= Math.max(orderIdColIndex, orderProductIdColIndex)) {
                    System.debug('Row ' + i + ' doesn\'t have enough columns, skipping');
                    continue;
                }
                
                // Get Order ID and Order Product ID
                String orderId = row[orderIdColIndex].trim();
                String orderProductId = row[orderProductIdColIndex].trim();
                
                System.debug('Row ' + i + ' Order ID: ' + orderId + ', Order Product ID: ' + orderProductId);
                
                // Validate IDs
                if (String.isBlank(orderId) || String.isBlank(orderProductId)) {
                    System.debug('Row ' + i + ' has blank Order ID or Order Product ID, skipping');
                    continue;
                }
                
                // Validate ID format (must start with 801/802 and be 15 or 18 chars)
                Boolean validOrderId = orderId.startsWith('801') && 
                                      (orderId.length() == 15 || orderId.length() == 18);
                Boolean validOrderProductId = orderProductId.startsWith('802') && 
                                            (orderProductId.length() == 15 || orderProductId.length() == 18);
                
                if (!validOrderId || !validOrderProductId) {
                    System.debug('Row ' + i + ' has invalid IDs: ' + orderId + ', ' + orderProductId);
                    continue;
                }
                
                validRows++;
                System.debug('Row ' + i + ' is VALID (' + validRows + ' valid rows so far)');
                
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
                validRowIndices.add(i);
            }
            
            // Show all row contents at the end
            for (Integer rowNum : rowContents.keySet()) {
                System.debug(rowContents.get(rowNum));
            }
            
            System.debug('Found ' + validRows + ' valid rows');
            System.debug('Created ' + jobsToInsert.size() + ' jobs to insert');
            
            // Check if we have any jobs to insert
            if (jobsToInsert.isEmpty()) {
                result.put('success', false);
                result.put('errors', new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'message' => 'No valid records found to process'
                    }
                });
                return result;
            }
            
            // Insert jobs in a single transaction
            Savepoint sp = Database.setSavepoint();
            try {
                insert jobsToInsert;
                
                // Reload jobs with generated fields
                List<RLCS_Job__c> insertedJobs = [
                    SELECT Id, Order__c, Order_Product__c, Consignment_Note_Reference__c,
                           Weightbridge_Reference__c, Consignment_Note_Reference_Ticket__c
                    FROM RLCS_Job__c 
                    WHERE Id IN :jobsToInsert
                    ORDER BY CreatedDate ASC
                ];
                
                // Generate output CSV
                String outputCSV = generateOutputCSV(csvRows, validRowIndices, insertedJobs);
                String filename = generateFileName(csvRows);
                
                result.put('success', true);
                result.put('outputCSV', outputCSV);
                result.put('filename', filename);
                result.put('jobCount', insertedJobs.size());
            } catch (Exception e) {
                // Roll back if any insertion fails
                Database.rollback(sp);
                result.put('success', false);
                result.put('errors', new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'message' => 'Error inserting records: ' + e.getMessage(),
                        'stackTrace' => e.getStackTraceString()
                    }
                });
                System.debug('Error: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());
            }
        } catch (Exception e) {
            result.put('success', false);
            result.put('errors', new List<Map<String, Object>>{
                new Map<String, Object>{
                    'message' => 'Error processing CSV: ' + e.getMessage(),
                    'stackTrace' => e.getStackTraceString()
                }
            });
            System.debug('Error processing CSV: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * Parse CSV content into a list of rows
     * This is now public so the batch class can use it
     * @param csvContent String representing the CSV content
     * @return List of rows, each row containing a list of column values
     */
    public static List<List<String>> parseCSV(String csvContent) {
        List<List<String>> rows = new List<List<String>>();
        
        if (String.isBlank(csvContent)) {
            return rows;
        }
        
        // Split into lines
        List<String> lines = csvContent.split('\n');
        System.debug('Raw line count: ' + lines.size());
        
        // Inspect last few lines for hidden content
        for (Integer i = Math.max(0, lines.size() - 5); i < lines.size(); i++) {
            String line = lines[i];
            System.debug('Line ' + i + ' length: ' + line.length());
            System.debug('Line ' + i + ' content: ' + line);
            // Show ASCII codes for each character in the last line
            if (i == lines.size() - 1) {
                String asciiCodes = '';
                for (Integer j = 0; j < line.length(); j++) {
                    Integer code = line.charAt(j);
                    asciiCodes += code + ' ';
                }
                System.debug('ASCII codes for last line: ' + asciiCodes);
            }
        }
        
        for (String line : lines) {
            if (String.isBlank(line)) {
                System.debug('Skipping blank line');
                continue;
            }
            
            // Parse CSV line
            List<String> columns = parseCSVLine(line);
            rows.add(columns);
        }
        
        return rows;
    }
    
    /**
     * Parse a single CSV line into a list of column values
     * Handles quoted values and commas within quoted values
     * @param line String representing a single CSV line
     * @return List of column values
     */
    private static List<String> parseCSVLine(String line) {
        List<String> columns = new List<String>();
        Boolean inQuotes = false;
        String currentColumn = '';
        
        // Process each character
        for (Integer i = 0; i < line.length(); i++) {
            String currentChar = line.substring(i, i + 1);
            
            if (currentChar == '"') {
                inQuotes = !inQuotes;
            } else if (currentChar == ',' && !inQuotes) {
                // End of column
                columns.add(currentColumn);
                currentColumn = '';
            } else {
                currentColumn += currentChar;
            }
        }
        
        // Add the last column
        columns.add(currentColumn);
        
        return columns;
    }
    
    /**
     * Generate the output CSV based on the input CSV and inserted jobs
     * Now public so the batch class can use it
     * @param csvRows List of rows from the input CSV
     * @param validRowIndices List of indices for valid rows
     * @param insertedJobs List of inserted job records
     * @return String representing the output CSV
     */
    public static String generateOutputCSV(List<List<String>> csvRows, List<Integer> validRowIndices, 
                                           List<RLCS_Job__c> insertedJobs) {
        List<String> outputRows = new List<String>();
        
        // Add header row with updated column order
        outputRows.add('"Council Ref","DC/Source","Postcode","Date Collected","Date Received","Transport Company","AATF Site Reference","Ticket No","Consignment Note Ref","Waste Note Number","Vehicle License","WEEE Material Category","Material Weight (Tonnes)","Unit Count"');
        
        // We need column indices for each field
        Map<String, Integer> columnMap = new Map<String, Integer>();
        
        // Find all required column indices
        List<String> headers = csvRows[0];
        for (Integer i = 0; i < headers.size(); i++) {
            String header = headers[i].trim();
            
            if (header.contains('WDA/Other')) {
                columnMap.put('councilRef', i);
            } else if (header.contains('DCF/Source')) {
                columnMap.put('dcSource', i);
            } else if (header.contains('Postcode')) {
                columnMap.put('postcode', i);
            } else if (header.contains('Date Coll')) {
                columnMap.put('dateCollected', i);
            } else if (header.contains('Date Rec')) {
                columnMap.put('dateReceived', i);
            } else if (header.contains('AATF/Haulier')) {
                columnMap.put('transportCompany', i);
            } else if (header.equals('AATF Site')) {
                columnMap.put('aatfSite', i);
            } else if (header.contains('Ticket No')) {
                columnMap.put('ticketNo', i);
            } else if (header.contains('Waste Note')) {
                columnMap.put('wasteNote', i);
            } else if (header.contains('Vehicle')) {
                columnMap.put('vehicleLicense', i);
            } else if (header.contains('WEEE Stream') || header.contains('Category')) {
                columnMap.put('weeeCategory', i);
            } else if (header.contains('WEEE Tonnes')) {
                columnMap.put('weeeTonnage', i);
            } else if (header.contains('WEEE Units')) {
                columnMap.put('weeeUnits', i);
            }
        }
        
        // For each valid row, create an output row
        for (Integer i = 0; i < validRowIndices.size() && i < insertedJobs.size(); i++) {
            Integer rowIndex = validRowIndices[i];
            List<String> inputRow = csvRows[rowIndex];
            RLCS_Job__c job = insertedJobs[i];
            
            // Create output CSV columns
            List<String> outputCols = new List<String>();
            
            // Council Ref (WDA/Other)
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'councilRef')));
            
            // DC/Source
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'dcSource')));
            
            // Postcode
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'postcode')));
            
            // Date Collected
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'dateCollected')));
            
            // Date Received
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'dateReceived')));
            
            // Transport Company
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'transportCompany')));
            
            // AATF Site Reference
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'aatfSite')));
            
            // Ticket No
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'ticketNo')));
            
            // Consignment Note Ref (previously Waste Note Number)
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'wasteNote')));
            
            // Waste Note Number (previously PCS Reference)
            outputCols.add(escapeCSV(job.Consignment_Note_Reference__c));
            
            // Vehicle License
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'vehicleLicense')));
            
            // WEEE Material Category
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'weeeCategory')));
            
            // Material Weight (Tonnes)
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'weeeTonnage')));
            
            // Unit Count
            outputCols.add(escapeCSV(getColumnValue(inputRow, columnMap, 'weeeUnits')));
            
            // Add the row to the output
            outputRows.add(String.join(outputCols, ','));
        }
        
        return String.join(outputRows, '\n');
    }
    
    /**
     * Helper method to safely get a column value
     * @param row List of column values
     * @param columnMap Map of column names to indices
     * @param columnName Name of the column to get
     * @return Value of the column, or empty string if not found
     */
    private static String getColumnValue(List<String> row, Map<String, Integer> columnMap, String columnName) {
        if (columnMap.containsKey(columnName)) {
            Integer index = columnMap.get(columnName);
            if (row != null && index < row.size()) {
                return row[index];
            }
        }
        return '';
    }
    
    /**
     * Escape a string for CSV (wrap in quotes and escape internal quotes)
     * @param value String to escape
     * @return Escaped string
     */
    private static String escapeCSV(String value) {
        if (value == null) {
            return '""';
        }
        
        // Replace quotes with double quotes and wrap in quotes
        return '"' + value.replace('"', '""') + '"';
    }
    
    /**
     * Generate the output filename based on the input CSV
     * Now public so the batch class can use it
     * Format: "ICER Report -{Current User} - {Current Date Time} - {First AATF Site}"
     * @param csvRows List of rows from the input CSV
     * @return String representing the filename
     */
    public static String generateFileName(List<List<String>> csvRows) {
        String userName = UserInfo.getName();
        String timestamp = Datetime.now().format('yyyy-MM-dd_HH-mm-ss');
        String aatfSite = '';
        
        // Try to find AATF Site
        Integer aatfSiteIndex = -1;
        if (!csvRows.isEmpty()) {
            List<String> headers = csvRows[0];
            for (Integer i = 0; i < headers.size(); i++) {
                if (headers[i].equals('AATF Site')) {
                    aatfSiteIndex = i;
                    break;
                }
            }
            
            // Get first AATF Site value
            if (aatfSiteIndex >= 0 && csvRows.size() > 1) {
                List<String> firstDataRow = csvRows[1];
                if (firstDataRow.size() > aatfSiteIndex) {
                    aatfSite = firstDataRow[aatfSiteIndex].trim();
                }
            }
        }
        
        return 'ICER Report - ' + userName + ' - ' + timestamp + ' - ' + aatfSite;
    }
    
    /**
     * Custom exception class for CSV processing errors
     */
    public class CSVException extends Exception {}
}