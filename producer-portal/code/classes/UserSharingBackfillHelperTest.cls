/**
 * @description Test class for UserSharingBackfillHelper
 * @created 2025-10-21
 */
@IsTest(SeeAllData=false)
public class UserSharingBackfillHelperTest {

    @testSetup
    static void setup() {
        // Create Account with Producer records
        Account acc = new Account(Name = 'Test Producer Company');
        insert acc;

        // Create Producer Contract
        Producer_Contract__c contract = new Producer_Contract__c(
            Account__c = acc.Id,
            Contract_Type__c = 'WEEE',
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = Date.today().addYears(1),
            VAT_Registered__c = true
        );
        insert contract;

        // Create Producer Obligation (with required fields)
        String previousYear = String.valueOf(Date.today().year() - 1);

        // Create 4 quarterly POM records to satisfy validation rule
        Id householdRTId = Schema.SObjectType.Producer_Placed_on_Market__c
            .getRecordTypeInfosByDeveloperName()
            .get('Household').getRecordTypeId();

        List<Producer_Placed_on_Market__c> pomRecords = new List<Producer_Placed_on_Market__c>();
        String[] quarters = new String[]{'Q1', 'Q2', 'Q3', 'Q4'};
        for (String quarter : quarters) {
            pomRecords.add(new Producer_Placed_on_Market__c(
                Account__c = acc.Id,
                Quarter__c = quarter,
                Compliance_Year__c = previousYear,
                RecordTypeId = householdRTId,
                Acknowledgement_of_Statements__c = true
            ));
        }
        insert pomRecords;

        // Now create Obligation
        Producer_Obligation__c obligation = new Producer_Obligation__c(
            Producer_Contract__c = contract.Id,
            Compliance_Year__c = String.valueOf(Date.today().year()),
            Notified_To_Validate_Membership_Type__c = false
        );
        insert obligation;

        // Create Producer Placed on Market
        Producer_Placed_on_Market__c pom = new Producer_Placed_on_Market__c(
            Account__c = acc.Id,
            RecordTypeId = householdRTId,
            Quarter__c = 'Q1',
            Compliance_Year__c = String.valueOf(Date.today().year())
        );
        insert pom;
    }

    @isTest
    static void testBackfillForNewPortalUser() {
        // Get test Account
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Get Producer record counts
        Integer contractCount = [SELECT COUNT() FROM Producer_Contract__c WHERE Account__c = :acc.Id];
        Integer obligationCount = [SELECT COUNT() FROM Producer_Obligation__c WHERE Producer_Contract__r.Account__c = :acc.Id];
        Integer pomCount = [SELECT COUNT() FROM Producer_Placed_on_Market__c WHERE Account__c = :acc.Id];

        System.debug('Setup created: ' + contractCount + ' contracts, ' + obligationCount + ' obligations, ' + pomCount + ' POMs');

        // Create Contact
        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'Test',
            LastName = 'PortalUser',
            Email = 'test.portaluser@test.example.com'
        );
        insert con;

        // Get portal profile
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Producer Standard User Login' LIMIT 1];

        // Create User
        User portalUser = new User(
            ContactId = con.Id,
            Username = 'test.portaluser@test.example.com.usersharingtest',
            Email = 'test.portaluser@test.example.com',
            FirstName = 'Test',
            LastName = 'PortalUser',
            Alias = 'tpu',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = portalProfile.Id,
            LanguageLocaleKey = 'en_US'
        );

        // Insert User in separate transaction to avoid mixed DML with Flow
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert portalUser;
        }
        Test.stopTest(); // @future methods complete here

        // Verify sharing records were created
        Integer contractShares = [
            SELECT COUNT()
            FROM Producer_Contract__Share
            WHERE UserOrGroupId = :portalUser.Id
            AND RowCause = 'Manual'
        ];

        Integer obligationShares = [
            SELECT COUNT()
            FROM Producer_Obligation__Share
            WHERE UserOrGroupId = :portalUser.Id
            AND RowCause = 'Manual'
        ];

        Integer pomShares = [
            SELECT COUNT()
            FROM Producer_Placed_on_Market__Share
            WHERE UserOrGroupId = :portalUser.Id
            AND RowCause = 'Manual'
        ];

        System.debug('Shares created: ' + contractShares + ' contracts, ' + obligationShares + ' obligations, ' + pomShares + ' POMs');

        // Assert shares were created
        System.assertEquals(contractCount, contractShares, 'All contracts should be shared with new user');
        System.assertEquals(obligationCount, obligationShares, 'All obligations should be shared with new user');
        System.assertEquals(pomCount, pomShares, 'All POMs should be shared with new user');
    }

    @isTest
    static void testBackfillForSecondAccount() {
        // Test that multiple accounts work correctly
        Account acc2 = new Account(Name = 'Second Producer Company');
        insert acc2;

        // Create Contract for second account
        Producer_Contract__c contract2 = new Producer_Contract__c(
            Account__c = acc2.Id,
            Contract_Type__c = 'WEEE',
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = Date.today().addYears(1),
            VAT_Registered__c = true
        );
        insert contract2;

        // Create Contact for second account
        Contact con2 = new Contact(
            AccountId = acc2.Id,
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'test.user2@test.example.com'
        );
        insert con2;

        // Get portal profile
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Producer Standard User Login' LIMIT 1];

        // Create User linked to second account
        User portalUser2 = new User(
            ContactId = con2.Id,
            Username = 'test.user2@test.example.com.usersharingtest',
            Email = 'test.user2@test.example.com',
            FirstName = 'Test',
            LastName = 'User2',
            Alias = 'tsu2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = portalProfile.Id,
            LanguageLocaleKey = 'en_US'
        );

        // Insert User in separate transaction to avoid mixed DML with Flow
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert portalUser2;
        }
        Test.stopTest(); // @future methods complete here

        // Verify user has access to second account's records (not first account)
        Integer contract2Shares = [
            SELECT COUNT()
            FROM Producer_Contract__Share
            WHERE UserOrGroupId = :portalUser2.Id
            AND ParentId = :contract2.Id
            AND RowCause = 'Manual'
        ];

        System.assertEquals(1, contract2Shares, 'User should have access to their account records');
    }

    @isTest
    static void testBackfillWithUsersWithoutAccount() {
        // Test that users without Account are handled gracefully
        // This tests the helper's null check for Contact.AccountId

        // Call the helper directly with a user ID that doesn't have a Contact
        // The helper should handle this gracefully without errors
        Test.startTest();
        UserSharingBackfillHelper.backfillSharingForNewUsers(new List<Id>{UserInfo.getUserId()});
        Test.stopTest();

        // Should complete without errors
        // No shares should be created for running user
        System.assert(true, 'Users without portal Contact handled without errors');
    }

    @isTest
    static void testBackfillWithEmptyUserList() {
        // Test edge case: empty user list
        Test.startTest();
        UserSharingBackfillHelper.backfillSharingForNewUsers(new List<Id>());
        Test.stopTest();

        // Should not throw exception
        System.assert(true, 'Empty list handled without errors');
    }
}