/**
 * @description Helper class to automatically backfill sharing when new portal users are created
 * @purpose When a new portal user is created, this class shares all existing Producer records
 *          for their Account so they can immediately see existing data
 * @created 2025-10-21
 */
public class UserSharingBackfillHelper {

    /**
     * @description Backfill sharing for newly created portal users
     * @param userIds List of User IDs to process
     * @future annotation needed because this is called from User trigger
     */
    @future
    public static void backfillSharingForNewUsers(List<Id> userIds) {
        System.debug('=== Starting backfill for ' + userIds.size() + ' new users ===');

        // Get Account IDs for these users
        Map<Id, Id> userToAccountMap = new Map<Id, Id>();
        for (User u : [
            SELECT Id, ContactId, Contact.AccountId
            FROM User
            WHERE Id IN :userIds
            AND ContactId != null
        ]) {
            if (u.Contact?.AccountId != null) {
                userToAccountMap.put(u.Id, u.Contact.AccountId);
                System.debug('User ' + u.Id + ' linked to Account ' + u.Contact.AccountId);
            }
        }

        if (userToAccountMap.isEmpty()) {
            System.debug('No portal users with Accounts found. Skipping backfill.');
            return;
        }

        Set<Id> accountIds = new Set<Id>(userToAccountMap.values());
        System.debug('Processing ' + accountIds.size() + ' unique Accounts');

        // Share ALL Producer records for these Accounts
        shareContracts(accountIds);
        shareObligations(accountIds);
        sharePlacedOnMarkets(accountIds);

        System.debug('=== Backfill complete ===');
    }

    /**
     * @description Share Producer_Contract__c records for given Accounts
     * @param accountIds Set of Account IDs
     */
    private static void shareContracts(Set<Id> accountIds) {
        List<Producer_Contract__c> contracts = [
            SELECT Id, Account__c
            FROM Producer_Contract__c
            WHERE Account__c IN :accountIds
        ];

        System.debug('Sharing ' + contracts.size() + ' Producer_Contract__c records');

        if (!contracts.isEmpty()) {
            ProducerSharingHelper.shareContracts(contracts);
        }
    }

    /**
     * @description Share Producer_Obligation__c records for given Accounts
     * @param accountIds Set of Account IDs
     */
    private static void shareObligations(Set<Id> accountIds) {
        List<Producer_Obligation__c> obligations = [
            SELECT Id, Producer_Contract__c
            FROM Producer_Obligation__c
            WHERE Producer_Contract__r.Account__c IN :accountIds
            AND Producer_Contract__c != null
        ];

        System.debug('Sharing ' + obligations.size() + ' Producer_Obligation__c records');

        if (!obligations.isEmpty()) {
            ProducerSharingHelper.shareObligations(obligations);
        }
    }

    /**
     * @description Share Producer_Placed_on_Market__c records for given Accounts
     * @param accountIds Set of Account IDs
     */
    private static void sharePlacedOnMarkets(Set<Id> accountIds) {
        List<Producer_Placed_on_Market__c> poms = [
            SELECT Id, Account__c
            FROM Producer_Placed_on_Market__c
            WHERE Account__c IN :accountIds
        ];

        System.debug('Sharing ' + poms.size() + ' Producer_Placed_on_Market__c records');

        if (!poms.isEmpty()) {
            ProducerSharingHelper.sharePlacedOnMarkets(poms);
        }
    }
}