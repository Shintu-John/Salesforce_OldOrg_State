/**
 * Trigger to automatically assign Cases from Customer Service Email queue to appropriate users.
 * Delegates all assignment logic to rlsServiceCaseAutoAssign class.
 *
 * @author Recycling Lives Service
 * @date Oct 2025
 */
trigger rlsServiceCaseAutoAssignTrigger on Case (after insert, after update) {
    // First, identify the Customer Service Email queue ID
    Id csEmailQueueId = null;
    try {
        Group csQueue = [
            SELECT Id 
            FROM Group 
            WHERE Type = 'Queue' 
            AND Name = 'Customer Service Email' 
            LIMIT 1
        ];
        csEmailQueueId = csQueue.Id;
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'Error finding Customer Service Email queue: ' + e.getMessage());
        return; // Exit if we can't find the queue
    }
    
    // Set to collect case IDs that need to be processed
    Set<Id> caseIdsToProcess = new Set<Id>();
    
    // Collect cases where owner is the CS Email queue and account is populated
    if (Trigger.isAfter) {
        for (Case c : Trigger.new) {
            if (c.OwnerId == csEmailQueueId && c.AccountId != null) {
                caseIdsToProcess.add(c.Id);
            }
        }
    }
    
    // If we have cases to process, call our assignment logic
    if (!caseIdsToProcess.isEmpty()) {
        // Convert set to list for the method call
        List<Id> caseIdsList = new List<Id>(caseIdsToProcess);
        
        // Call the assignment logic - class will handle both key accounts and workload distribution
        rlsServiceCaseAutoAssign.assignCasesToUsers(caseIdsList);
    }
}