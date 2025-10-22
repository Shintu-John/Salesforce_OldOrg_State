/**
 * Apex Class to automatically assign Cases to Customer Service users based on specified criteria.
 * Updated to handle key accounts first, then workload distribution for remaining cases.
 * Optimized to perform a single DML update operation.
 *
 * @author Recycling Lives Service
 * @date Oct  2nd 2025
 * @modified Oct 20, 2025 - Added recursion prevention and caching for SOQL optimization
 */
public class rlsServiceCaseAutoAssign {

    // Recursion prevention flag
    private static Boolean hasRun = false;

    // Cached IDs to reduce SOQL queries
    private static Id cachedEmailRecordTypeId;
    private static Id cachedCSEmailQueueId;

    /**
     * Wrapper class to hold user workload information
     */
    private class UserWorkload {
        public Integer caseCount;
        public Datetime lastCaseAssignedTime;

        public UserWorkload() {
            this.caseCount = 0;
            this.lastCaseAssignedTime = null;
        }
    }
    
    /**
     * Input class for Flow integration
     */
    public class FlowInputs {
        @InvocableVariable(required=true)
        public Id caseId;
    }
    
    /**
     * Invocable method wrapper for Flow integration
     */
    @InvocableMethod(label='Auto Assign Cases to Users' description='Assigns cases to Customer Service users based on workload')
    public static void assignCasesFromFlow(List<FlowInputs> inputs) {
        List<Id> caseIds = new List<Id>();
        for (FlowInputs input : inputs) {
            if (input.caseId != null) {
                caseIds.add(input.caseId);
            }
        }
        if (!caseIds.isEmpty()) {
            assignCasesToUsers(caseIds);
        }
    }
    
    /**
     * Main method to assign cases - handles key accounts first, then workload distribution
     * Optimized to perform single DML update
     * Now includes recursion prevention to avoid SOQL limit issues
     */
    public static void assignCasesToUsers(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            System.debug('No case IDs provided for assignment.');
            return;
        }

        // Recursion prevention - exit if already processed in this transaction
        if (hasRun) {
            System.debug('Assignment logic already executed in this transaction. Skipping to prevent recursion.');
            return;
        }
        hasRun = true;

        try {
            List<Case> allCasesToUpdate = new List<Case>();
            
            // Step 1: Handle key accounts first (accounts with CS Contact assigned)
            List<Case> keyAccountCases = assignKeyAccountCases(caseIds);
            allCasesToUpdate.addAll(keyAccountCases);
            
            // Remove key account case IDs from the list
            Set<Id> keyAccountCaseIds = new Set<Id>();
            for (Case c : keyAccountCases) {
                keyAccountCaseIds.add(c.Id);
            }
            
            // Create new list without key account cases
            List<Id> remainingCaseIds = new List<Id>();
            for (Id caseId : caseIds) {
                if (!keyAccountCaseIds.contains(caseId)) {
                    remainingCaseIds.add(caseId);
                }
            }
            
            if (!keyAccountCases.isEmpty()) {
                System.debug('Prepared ' + keyAccountCases.size() + ' key account cases for assignment to account managers.');
            }
            
            // Step 2: Handle remaining cases with workload distribution
            if (!remainingCaseIds.isEmpty()) {
                // Query eligible cases for workload assignment
                List<Case> eligibleCases = queryEligibleCases(remainingCaseIds);
                
                if (!eligibleCases.isEmpty()) {
                    // Query eligible users based on criteria
                    List<User> eligibleUsers = queryEligibleUsers();
                    
                    if (!eligibleUsers.isEmpty()) {
                        // Get user workload and last case assignment time
                        Map<Id, UserWorkload> userWorkloadMap = getUserWorkloadAndTiming(eligibleUsers);
                        
                        // Assign cases to users with the lowest workload
                        List<Case> workloadCases = assignCasesToUsersWithLowestWorkload(
                            eligibleCases, eligibleUsers, userWorkloadMap
                        );
                        allCasesToUpdate.addAll(workloadCases);
                        
                        System.debug('Prepared ' + workloadCases.size() + ' cases for workload distribution.');
                        
                        // Log final workload after all assignments
                        logFinalWorkload(eligibleUsers, userWorkloadMap);
                    } else {
                        System.debug('No eligible users found for case assignment.');
                    }
                } else {
                    System.debug('No eligible cases found for automatic assignment.');
                }
            } else {
                System.debug('No remaining cases for workload assignment.');
            }
            
            // Single DML update for all cases (key accounts + workload distribution)
            if (!allCasesToUpdate.isEmpty()) {
                update allCasesToUpdate;
                System.debug('Successfully assigned and updated ' + allCasesToUpdate.size() + ' total cases.');
            }
            
        } catch (Exception e) {
            // Log any exceptions that occur
            System.debug(LoggingLevel.ERROR, 'Error in rlsServiceCaseAutoAssign: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * Get cached Email Record Type ID (reduces repeated Schema describes)
     */
    private static Id getEmailRecordTypeId() {
        if (cachedEmailRecordTypeId == null) {
            cachedEmailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Email').getRecordTypeId();
            System.debug('Cached Email Record Type ID: ' + cachedEmailRecordTypeId);
        }
        return cachedEmailRecordTypeId;
    }

    /**
     * Get cached Customer Service Email Queue ID (reduces repeated SOQL queries)
     */
    private static Id getCSEmailQueueId() {
        if (cachedCSEmailQueueId == null) {
            try {
                Group csQueue = [
                    SELECT Id
                    FROM Group
                    WHERE Type = 'Queue'
                    AND Name = 'Customer Service Email'
                    LIMIT 1
                ];
                cachedCSEmailQueueId = csQueue.Id;
                System.debug('Cached CS Email Queue ID: ' + cachedCSEmailQueueId);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error finding Customer Service Email queue: ' + e.getMessage());
            }
        }
        return cachedCSEmailQueueId;
    }

    /**
     * Assign cases from key accounts to their designated account managers
     * Special handling: Kaylie Morris bypasses threshold check
     * Other CS Contacts respect threshold - only assigns if under threshold
     * Returns list of cases with updated ownership (does not perform DML)
     * Returns empty list for cases where CS Contact is over threshold (they'll go through normal distribution)
     */
    private static List<Case> assignKeyAccountCases(List<Id> caseIds) {
        // Get cached IDs
        Id emailRecordTypeId = getEmailRecordTypeId();
        Id csEmailQueueId = getCSEmailQueueId();

        if (csEmailQueueId == null) {
            return new List<Case>();
        }

        // Get threshold
        Integer threshold = getMaxOpenCasesThreshold();

        // Query cases from key accounts (where CS_Contact__c is populated)
        // Now includes CS Contact name to check for Kaylie Morris exemption
        List<Case> keyAccountCases = [
            SELECT Id, OwnerId, AccountId, Account.CS_Contact__c, Account.CS_Contact__r.Name, Status, RecordTypeId
            FROM Case
            WHERE Id IN :caseIds
            AND OwnerId = :csEmailQueueId
            AND RecordTypeId = :emailRecordTypeId
            AND Account.CS_Contact__c != null
        ];

        System.debug('Found ' + keyAccountCases.size() + ' key account cases with CS Contact.');

        if (keyAccountCases.isEmpty()) {
            return new List<Case>();
        }

        // Get unique CS Contact user IDs
        Set<Id> csContactIds = new Set<Id>();
        for (Case c : keyAccountCases) {
            csContactIds.add(c.Account.CS_Contact__c);
        }

        // Get workload for each CS Contact
        Map<Id, Integer> csContactWorkload = new Map<Id, Integer>();
        for (Id userId : csContactIds) {
            csContactWorkload.put(userId, 0);
        }

        // Query open case counts for CS Contacts
        for (AggregateResult ar : [
            SELECT OwnerId, COUNT(Id) caseCount
            FROM Case
            WHERE OwnerId IN :csContactIds
            AND RecordTypeId = :emailRecordTypeId
            AND Status != 'Case Closed'
            GROUP BY OwnerId
        ]) {
            Id userId = (Id)ar.get('OwnerId');
            Integer caseCount = (Integer)ar.get('caseCount');
            csContactWorkload.put(userId, caseCount);
        }

        // Assign cases - Kaylie Morris bypasses threshold, others respect it
        List<Case> casesToAssign = new List<Case>();
        for (Case c : keyAccountCases) {
            Id csContactId = c.Account.CS_Contact__c;
            String csContactName = c.Account.CS_Contact__r.Name;
            Integer currentLoad = csContactWorkload.get(csContactId);

            // Special handling: Kaylie Morris always gets assigned (bypasses threshold)
            Boolean isKaylieMorris = (csContactName == 'Kaylie Morris');

            if (isKaylieMorris) {
                System.debug('Assigning key account case ' + c.Id + ' to Kaylie Morris (bypassing threshold check)' +
                    ' (current load: ' + currentLoad + ')');
                c.OwnerId = csContactId;
                c.rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now();
                casesToAssign.add(c);

                // Update workload for next iteration
                csContactWorkload.put(csContactId, currentLoad + 1);
            }
            else if (currentLoad < threshold) {
                System.debug('Assigning key account case ' + c.Id + ' to CS Contact: ' + csContactName +
                    ' (current load: ' + currentLoad + ', threshold: ' + threshold + ')');
                c.OwnerId = csContactId;
                c.rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now();
                casesToAssign.add(c);

                // Update workload for next iteration
                csContactWorkload.put(csContactId, currentLoad + 1);
            } else {
                System.debug('CS Contact ' + csContactName + ' is at/over threshold (' + currentLoad + ' >= ' + threshold +
                    '). Case ' + c.Id + ' will go through normal distribution.');
            }
        }

        System.debug('Assigned ' + casesToAssign.size() + ' key account cases to CS Contacts (with Kaylie Morris exemption).');
        return casesToAssign;
    }
    
    /**
     * Query cases that meet the workload assignment criteria
     * Now includes ALL cases still in queue (both non-key accounts AND key accounts where CS Contact is over threshold)
     */
    private static List<Case> queryEligibleCases(List<Id> caseIds) {
        // Get cached IDs
        Id emailRecordTypeId = getEmailRecordTypeId();
        Id csEmailQueueId = getCSEmailQueueId();

        if (csEmailQueueId == null) {
            return new List<Case>();
        }

        // Query ALL cases still in queue (includes key accounts where CS Contact was over threshold)
        List<Case> eligibleCases = [
            SELECT Id, OwnerId, AccountId, Status, RecordTypeId, CreatedDate,
                   rlsServiceCaseAutoAssign_Date_Time__c, Previous_Auto_Assigned_Owner__c,
                   Most_Recent_Message__c, Account.CS_Contact__c
            FROM Case
            WHERE Id IN :caseIds
            AND OwnerId = :csEmailQueueId
            AND RecordTypeId = :emailRecordTypeId
            ORDER BY CreatedDate ASC
        ];

        System.debug('Found ' + eligibleCases.size() + ' eligible cases for workload-based assignment.');
        return eligibleCases;
    }
    
    /**
     * Query users who meet the assignment criteria
     */
    private static List<User> queryEligibleUsers() {
        Date today = Date.today();
        
        List<User> users;
        if (Test.isRunningTest()) {
            users = [
                SELECT Id, Name, LastLoginDate, Dont_Auto_Assign_Cases__c
                FROM User
                WHERE Profile.Name LIKE '%Customer Service%'
                AND (Dont_Auto_Assign_Cases__c = false OR Dont_Auto_Assign_Cases__c = null)
                AND IsActive = true
            ];
        } else {
            users = [
                SELECT Id, Name, LastLoginDate, Dont_Auto_Assign_Cases__c
                FROM User
                WHERE Profile.Name LIKE '%Customer Service%'
                AND LastLoginDate >= :today
                AND (Dont_Auto_Assign_Cases__c = false OR Dont_Auto_Assign_Cases__c = null)
                AND IsActive = true
            ];
        }
        
        System.debug('Found ' + users.size() + ' eligible users for case assignment.');
        for (User u : users) {
            System.debug('Eligible user: ' + u.Name + ', Last login: ' + u.LastLoginDate);
        }
        
        return users;
    }
    
    /**
     * Get the workload and most recent case assignment time for each user
     */
    private static Map<Id, UserWorkload> getUserWorkloadAndTiming(List<User> users) {
        Map<Id, UserWorkload> userWorkloadMap = new Map<Id, UserWorkload>();
        Map<Id, User> userMap = new Map<Id, User>();

        // Initialize all users with 0 cases and null last assignment time
        for (User u : users) {
            userWorkloadMap.put(u.Id, new UserWorkload());
            userMap.put(u.Id, u);
        }

        // Get cached Email record type ID
        Id emailRecordTypeId = getEmailRecordTypeId();
        
        // Get count of open Email cases for each user
        for (AggregateResult ar : [
            SELECT OwnerId, COUNT(Id) caseCount
            FROM Case
            WHERE OwnerId IN :userWorkloadMap.keySet()
            AND RecordTypeId = :emailRecordTypeId
            AND Status != 'Case Closed'
            GROUP BY OwnerId
        ]) {
            Id userId = (Id)ar.get('OwnerId');
            Integer caseCount = (Integer)ar.get('caseCount');
            userWorkloadMap.get(userId).caseCount = caseCount;
        }
        
        // Get the most recent case assignment time for each user
        for (AggregateResult ar : [
            SELECT OwnerId, MAX(rlsServiceCaseAutoAssign_Date_Time__c) maxDateTime
            FROM Case
            WHERE OwnerId IN :userWorkloadMap.keySet()
            AND Status != 'Case Closed'
            AND rlsServiceCaseAutoAssign_Date_Time__c != null
            GROUP BY OwnerId
        ]) {
            Id userId = (Id)ar.get('OwnerId');
            Datetime maxDateTime = (Datetime)ar.get('maxDateTime');
            userWorkloadMap.get(userId).lastCaseAssignedTime = maxDateTime;
        }
        
        // Debug log current workload
        System.debug('Current user workloads and last assignment times:');
        for (Id userId : userWorkloadMap.keySet()) {
            User u = userMap.get(userId);
            UserWorkload workload = userWorkloadMap.get(userId);
            System.debug('User: ' + u.Name +
                ' has ' + workload.caseCount + ' open cases, ' +
                'Last case assigned at: ' + workload.lastCaseAssignedTime);
        }
        
        return userWorkloadMap;
    }
    
    /**
     * Assign cases to users with the lowest workload
     * Returns list of cases with updated ownership (does not perform DML)
     */
    private static List<Case> assignCasesToUsersWithLowestWorkload(
        List<Case> casesToAssign,
        List<User> eligibleUsers,
        Map<Id, UserWorkload> userWorkloadMap
    ) {
        if (eligibleUsers.isEmpty()) {
            return new List<Case>();
        }

        List<Case> casesToUpdate = new List<Case>();

        // Get threshold from custom setting
        Integer threshold = getMaxOpenCasesThreshold();

        for (Case c : casesToAssign) {
            User selectedUser = null;

            // STEP 1: Check same-day previous owner eligibility first
            User previousOwner = checkPreviousOwnerEligibility(c, eligibleUsers, userWorkloadMap, threshold);

            if (previousOwner != null) {
                selectedUser = previousOwner;
                System.debug('Assigning case ' + c.Id + ' to same-day previous owner: ' + selectedUser.Name);
            }

            // STEP 2: If no previous owner eligible, use workload distribution with threshold
            if (selectedUser == null) {
                // Debug workload before assignment
                System.debug('Current workload before assignment for case ' + c.Id + ':');
                for (User u : eligibleUsers) {
                    UserWorkload workload = userWorkloadMap.get(u.Id);
                    System.debug('User: ' + u.Name +
                        ', Case count: ' + workload.caseCount +
                        ', Last case time: ' + workload.lastCaseAssignedTime);
                }

                // Filter users under threshold
                List<User> usersUnderThreshold = new List<User>();
                for (User u : eligibleUsers) {
                    if (userWorkloadMap.get(u.Id).caseCount < threshold) {
                        usersUnderThreshold.add(u);
                    }
                }

                // Determine which user pool to use
                List<User> candidateUsers;
                if (!usersUnderThreshold.isEmpty()) {
                    candidateUsers = usersUnderThreshold;
                    System.debug('Using ' + candidateUsers.size() + ' users under threshold of ' + threshold);
                } else {
                    candidateUsers = eligibleUsers;
                    System.debug('All users over threshold. Using all ' + candidateUsers.size() + ' eligible users (soft limit).');
                }

                // Find minimum case count from candidate pool
                Integer lowestCaseCount = 2147483647;
                for (User u : candidateUsers) {
                    Integer userCaseCount = userWorkloadMap.get(u.Id).caseCount;
                    if (userCaseCount < lowestCaseCount) {
                        lowestCaseCount = userCaseCount;
                    }
                }

                // Find all users with that minimum case count
                List<User> usersWithLowestCount = new List<User>();
                for (User u : candidateUsers) {
                    if (userWorkloadMap.get(u.Id).caseCount == lowestCaseCount) {
                        usersWithLowestCount.add(u);
                    }
                }

                // If only one user has the lowest count, select them
                if (usersWithLowestCount.size() == 1) {
                    selectedUser = usersWithLowestCount[0];
                    System.debug('Selected user ' + selectedUser.Name + ' based on lowest case count: ' + lowestCaseCount);
                }
                // If multiple users have the same lowest count, use tiebreaker
                else if (usersWithLowestCount.size() > 1) {
                    // Check if any users have null assignment time (never assigned a case)
                    List<User> usersWithNullTime = new List<User>();
                    for (User u : usersWithLowestCount) {
                        if (userWorkloadMap.get(u.Id).lastCaseAssignedTime == null) {
                            usersWithNullTime.add(u);
                        }
                    }

                    // If we have users who've never been assigned, pick one of them
                    if (!usersWithNullTime.isEmpty()) {
                        selectedUser = usersWithNullTime[0];
                        System.debug('Selected user ' + selectedUser.Name + ' who has no previous cases');
                    }
                    // Otherwise find user with most recent assignment to EXCLUDE
                    else {
                        Datetime mostRecentTime = Datetime.newInstance(1900, 1, 1);
                        User userWithMostRecent = null;

                        for (User u : usersWithLowestCount) {
                            Datetime userLastCaseTime = userWorkloadMap.get(u.Id).lastCaseAssignedTime;
                            if (userLastCaseTime > mostRecentTime) {
                                mostRecentTime = userLastCaseTime;
                                userWithMostRecent = u;
                            }
                        }

                        // Select a user other than the one with most recent assignment
                        for (User u : usersWithLowestCount) {
                            if (u.Id != userWithMostRecent.Id) {
                                selectedUser = u;
                                System.debug('Tiebreaker: Selected user ' + selectedUser.Name +
                                    ' by avoiding most recently assigned user ' + userWithMostRecent.Name);
                                break;
                            }
                        }

                        // Fallback if somehow we couldn't select
                        if (selectedUser == null && usersWithLowestCount.size() > 1) {
                            selectedUser = usersWithLowestCount[0].Id != userWithMostRecent.Id ?
                                usersWithLowestCount[0] : usersWithLowestCount[1];
                            System.debug('Fallback selection: ' + selectedUser.Name);
                        }
                    }
                }
            }
            
            // If we found a user, assign the case and update workload
            if (selectedUser != null) {
                System.debug('Assigning case ' + c.Id + ' to user: ' + selectedUser.Name);
                
                c.OwnerId = selectedUser.Id;
                c.rlsServiceCaseAutoAssign_Date_Time__c = Datetime.now();
                casesToUpdate.add(c);
                
                // Update the user's workload in our map
                UserWorkload workload = userWorkloadMap.get(selectedUser.Id);
                workload.caseCount++;
                workload.lastCaseAssignedTime = c.rlsServiceCaseAutoAssign_Date_Time__c;
                
                System.debug('Updated workload for ' + selectedUser.Name +
                    ' to ' + workload.caseCount + ' cases, ' +
                    'Last case time: ' + workload.lastCaseAssignedTime);
            }
        }
        
        return casesToUpdate;
    }
    
    /**
     * Log final workload after all assignments
     */
    private static void logFinalWorkload(List<User> users, Map<Id, UserWorkload> userWorkloadMap) {
        System.debug('Final workload after all assignments:');
        for (User u : users) {
            UserWorkload workload = userWorkloadMap.get(u.Id);
            System.debug('User: ' + u.Name +
                ' has ' + workload.caseCount + ' open cases, ' +
                'Last case assigned at: ' + workload.lastCaseAssignedTime);
        }
    }

    /**
     * Get the maximum open cases threshold from Custom Setting
     * Returns org default, profile override, or user-level override (in order of precedence)
     */
    private static Integer getMaxOpenCasesThreshold() {
        Case_Auto_Assignment_Settings__c settings = Case_Auto_Assignment_Settings__c.getInstance();

        if (settings != null && settings.Max_Open_Cases_Per_User__c != null) {
            Integer threshold = Integer.valueOf(settings.Max_Open_Cases_Per_User__c);
            System.debug('Retrieved threshold from custom setting: ' + threshold);
            return threshold;
        }

        // Fallback default if custom setting not configured
        System.debug('No custom setting found, using fallback default threshold: 20');
        return 20;
    }

    /**
     * Check if a case can be reassigned to its previous owner (same-day logic)
     * Returns the previous owner User object if eligible, null otherwise
     */
    private static User checkPreviousOwnerEligibility(Case c, List<User> eligibleUsers, Map<Id, UserWorkload> userWorkloadMap, Integer threshold) {
        // Check if case has previous owner
        if (c.Previous_Auto_Assigned_Owner__c == null) {
            System.debug('Case ' + c.Id + ' has no previous owner recorded.');
            return null;
        }

        // Check if case has most recent message timestamp
        if (c.Most_Recent_Message__c == null) {
            System.debug('Case ' + c.Id + ' has no Most_Recent_Message__c timestamp.');
            return null;
        }

        // Check if most recent message is on same calendar day as today
        Date messageDate = c.Most_Recent_Message__c.date();
        Date today = Date.today();

        if (messageDate != today) {
            System.debug('Case ' + c.Id + ' most recent message (' + messageDate + ') is not today (' + today + ').');
            return null;
        }

        System.debug('Case ' + c.Id + ' reopened on same day. Checking if previous owner is eligible...');

        // Find previous owner in eligible users list
        User previousOwner = null;
        for (User u : eligibleUsers) {
            if (u.Id == c.Previous_Auto_Assigned_Owner__c) {
                previousOwner = u;
                break;
            }
        }

        if (previousOwner == null) {
            System.debug('Previous owner not in eligible users list (inactive, logged out, or opted out).');
            return null;
        }

        // Check if previous owner is under threshold
        Integer previousOwnerCaseCount = userWorkloadMap.get(previousOwner.Id).caseCount;
        if (previousOwnerCaseCount < threshold) {
            System.debug('Previous owner ' + previousOwner.Name + ' is eligible (has ' + previousOwnerCaseCount + ' cases, under threshold of ' + threshold + ').');
            return previousOwner;
        }

        System.debug('Previous owner ' + previousOwner.Name + ' is over threshold (' + previousOwnerCaseCount + ' >= ' + threshold + ').');
        return null;
    }
}