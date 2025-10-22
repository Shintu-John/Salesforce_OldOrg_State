/**
 * @description Helper class to manage sharing for Producer Portal objects
 * @purpose Grants portal users (both Customer Community Plus and Login licenses)
 *          access to Producer records for their Account
 * @created 2025-10-21
 * @revised User-based sharing (not Group-based) since portal role Groups don't exist
 */
public without sharing class ProducerSharingHelper {

    /**
     * @description Share Producer_Contract__c records with Account portal users
     * @param contracts List of Producer_Contract__c records to share
     */
    public static void shareContracts(List<Producer_Contract__c> contracts) {
        List<Producer_Contract__Share> sharesToCreate = new List<Producer_Contract__Share>();

        // Get Account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Producer_Contract__c contract : contracts) {
            if (contract.Account__c != null) {
                accountIds.add(contract.Account__c);
            }
        }

        if (accountIds.isEmpty()) return;

        // Get portal users for these accounts
        Map<Id, List<Id>> accountToUsersMap = getAccountPortalUsers(accountIds);

        // Create shares for each user
        for (Producer_Contract__c contract : contracts) {
            if (contract.Account__c != null && accountToUsersMap.containsKey(contract.Account__c)) {
                for (Id userId : accountToUsersMap.get(contract.Account__c)) {
                    Producer_Contract__Share share = new Producer_Contract__Share();
                    share.ParentId = contract.Id;
                    share.UserOrGroupId = userId;
                    share.AccessLevel = 'Edit';
                    share.RowCause = Schema.Producer_Contract__Share.RowCause.Manual;
                    sharesToCreate.add(share);
                }
            }
        }

        if (!sharesToCreate.isEmpty()) {
            Database.SaveResult[] results = Database.insert(sharesToCreate, false);
            logErrors(results, 'Producer_Contract__Share');
        }
    }

    /**
     * @description Share Producer_Obligation__c records based on parent Contract's Account
     * @param obligations List of Producer_Obligation__c records to share
     */
    public static void shareObligations(List<Producer_Obligation__c> obligations) {
        List<Producer_Obligation__Share> sharesToCreate = new List<Producer_Obligation__Share>();

        // Get Contract IDs to find Accounts
        Set<Id> contractIds = new Set<Id>();
        for (Producer_Obligation__c obligation : obligations) {
            if (obligation.Producer_Contract__c != null) {
                contractIds.add(obligation.Producer_Contract__c);
            }
        }

        if (contractIds.isEmpty()) return;

        // Query contracts to get Account__c
        Map<Id, Id> contractToAccountMap = new Map<Id, Id>();
        for (Producer_Contract__c contract : [SELECT Id, Account__c FROM Producer_Contract__c WHERE Id IN :contractIds]) {
            if (contract.Account__c != null) {
                contractToAccountMap.put(contract.Id, contract.Account__c);
            }
        }

        Set<Id> accountIds = new Set<Id>(contractToAccountMap.values());
        Map<Id, List<Id>> accountToUsersMap = getAccountPortalUsers(accountIds);

        // Create shares for each user
        for (Producer_Obligation__c obligation : obligations) {
            if (obligation.Producer_Contract__c != null) {
                Id accountId = contractToAccountMap.get(obligation.Producer_Contract__c);
                if (accountId != null && accountToUsersMap.containsKey(accountId)) {
                    for (Id userId : accountToUsersMap.get(accountId)) {
                        Producer_Obligation__Share share = new Producer_Obligation__Share();
                        share.ParentId = obligation.Id;
                        share.UserOrGroupId = userId;
                        share.AccessLevel = 'Edit';
                        share.RowCause = Schema.Producer_Obligation__Share.RowCause.Manual;
                        sharesToCreate.add(share);
                    }
                }
            }
        }

        if (!sharesToCreate.isEmpty()) {
            Database.SaveResult[] results = Database.insert(sharesToCreate, false);
            logErrors(results, 'Producer_Obligation__Share');
        }
    }

    /**
     * @description Share Producer_Placed_on_Market__c records with Account portal users
     * @param placedOnMarkets List of Producer_Placed_on_Market__c records to share
     */
    public static void sharePlacedOnMarkets(List<Producer_Placed_on_Market__c> placedOnMarkets) {
        List<Producer_Placed_on_Market__Share> sharesToCreate = new List<Producer_Placed_on_Market__Share>();

        // Get Account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Producer_Placed_on_Market__c record : placedOnMarkets) {
            if (record.Account__c != null) {
                accountIds.add(record.Account__c);
            }
        }

        if (accountIds.isEmpty()) return;

        // Get portal users for these accounts
        Map<Id, List<Id>> accountToUsersMap = getAccountPortalUsers(accountIds);

        // Create shares for each user
        for (Producer_Placed_on_Market__c record : placedOnMarkets) {
            if (record.Account__c != null && accountToUsersMap.containsKey(record.Account__c)) {
                for (Id userId : accountToUsersMap.get(record.Account__c)) {
                    Producer_Placed_on_Market__Share share = new Producer_Placed_on_Market__Share();
                    share.ParentId = record.Id;
                    share.UserOrGroupId = userId;
                    share.AccessLevel = 'Edit';
                    share.RowCause = Schema.Producer_Placed_on_Market__Share.RowCause.Manual;
                    sharesToCreate.add(share);
                }
            }
        }

        if (!sharesToCreate.isEmpty()) {
            Database.SaveResult[] results = Database.insert(sharesToCreate, false);
            logErrors(results, 'Producer_Placed_on_Market__Share');
        }
    }

    /**
     * @description Validation_Question__c sharing handled automatically through parent
     * NOTE: Validation_Question__Share object doesn't exist - sharing is inherited
     * from the parent Producer_Placed_on_Market__c relationship automatically.
     * @param questions List of Validation_Question__c records (parameter kept for interface consistency)
     */
    public static void shareValidationQuestions(List<Validation_Question__c> questions) {
        // No action needed - sharing inherited from parent Producer_Placed_on_Market__c
        System.debug('Validation_Question sharing is automatic through parent relationship');
    }

    /**
     * @description Get active portal user IDs for given Account IDs
     * @param accountIds Set of Account IDs
     * @return Map of Account ID to List of portal user IDs
     */
    private static Map<Id, List<Id>> getAccountPortalUsers(Set<Id> accountIds) {
        Map<Id, List<Id>> accountToUsersMap = new Map<Id, List<Id>>();

        // Query for active portal users associated with these accounts
        // Includes both Customer Community Plus and Customer Community Plus Login licenses
        for (User portalUser : [
            SELECT Id, ContactId, Contact.AccountId
            FROM User
            WHERE Contact.AccountId IN :accountIds
            AND IsActive = true
            AND ContactId != null
            AND (
                Profile.UserLicense.Name = 'Customer Community Plus'
                OR Profile.UserLicense.Name = 'Customer Community Plus Login'
            )
        ]) {
            Id accountId = portalUser.Contact.AccountId;
            if (!accountToUsersMap.containsKey(accountId)) {
                accountToUsersMap.put(accountId, new List<Id>());
            }
            accountToUsersMap.get(accountId).add(portalUser.Id);
        }

        return accountToUsersMap;
    }

    /**
     * @description Log errors from Database.SaveResult
     * @param results List of save results
     * @param objectName Name of the object for logging
     */
    private static void logErrors(Database.SaveResult[] results, String objectName) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error error : results[i].getErrors()) {
                    System.debug('Error creating ' + objectName + ': ' + error.getMessage());
                }
            }
        }
    }
}