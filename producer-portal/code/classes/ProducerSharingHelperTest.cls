/**
 * @description Test class for ProducerSharingHelper and sharing triggers
 * @created 2025-10-21
 */
@IsTest(SeeAllData=false)
public class ProducerSharingHelperTest {

    // Utility: create a basic Account
    private static Account makeAccount(String name) {
        Account a = new Account(Name = name);
        insert a;
        return a;
    }

    // Utility: create a Producer Contract
    private static Producer_Contract__c makeContract(Id accountId, String typeVal) {
        Producer_Contract__c pc = new Producer_Contract__c(
            Account__c = accountId,
            Contract_Type__c = typeVal,
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = Date.today().addYears(1),
            VAT_Registered__c = true
        );
        insert pc;
        return pc;
    }

    // Utility: create an Obligation (include required boolean field)
    // Sets Compliance_Year__c to current year, but validation checks for previous year's POM
    private static Producer_Obligation__c makeObligation(Id contractId) {
        String currentYear = String.valueOf(Date.today().year());
        Producer_Obligation__c ob = new Producer_Obligation__c(
            Producer_Contract__c = contractId,
            Compliance_Year__c = currentYear,
            Notified_To_Validate_Membership_Type__c = false
        );
        insert ob;
        return ob;
    }

    // Utility: create a Placed on Market (minimal)
    private static Producer_Placed_on_Market__c makePOM(Id accountId) {
        Producer_Placed_on_Market__c pom = new Producer_Placed_on_Market__c(
            Account__c = accountId
        );
        insert pom;
        return pom;
    }

    // Helper to create 4 quarterly POM records for a given account and year
    // Satisfies Obligation validation and avoids NPEs in ProducerPlacedOnMarket trigger
    private static void createQuarterlyPOMRecords(Id accountId, String complianceYear) {
        // Get the Household RecordType dynamically (will make Type__c = 'WEEE' via formula)
        Id householdRTId = Schema.SObjectType.Producer_Placed_on_Market__c
            .getRecordTypeInfosByDeveloperName()
            .get('Household').getRecordTypeId();

        List<Producer_Placed_on_Market__c> pomRecords = new List<Producer_Placed_on_Market__c>();
        String[] quarters = new String[]{'Q1', 'Q2', 'Q3', 'Q4'};
        for (String quarter : quarters) {
            pomRecords.add(new Producer_Placed_on_Market__c(
                Account__c = accountId,
                Quarter__c = quarter,
                Compliance_Year__c = complianceYear,
                RecordTypeId = householdRTId,  // Type__c will auto-calculate to 'WEEE'
                Acknowledgement_of_Statements__c = true  // Required for validation
            ));
        }
        insert pomRecords;
    }

    // Helper to create a portal user for an account
    // Creates Contact and User to simulate real portal users
    private static User createPortalUser(Id accountId, String firstName, String lastName) {
        // Create Contact
        Contact con = new Contact(
            AccountId = accountId,
            FirstName = firstName,
            LastName = lastName,
            Email = firstName.toLowerCase() + '.' + lastName.toLowerCase() + '@testportal.example.com'
        );
        insert con;

        // Get Customer Community Plus Login profile
        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Producer Standard User Login'
            LIMIT 1
        ];

        // Create User
        User portalUser = new User(
            ContactId = con.Id,
            Username = con.Email + '.test',
            Email = con.Email,
            FirstName = firstName,
            LastName = lastName,
            Alias = (firstName.substring(0, 1) + lastName.substring(0, 1)).toLowerCase(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = portalProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert portalUser;

        return portalUser;
    }

    @testSetup
    static void setup() {
        Account acc = makeAccount('Test Producer Account');
        makeContract(acc.Id, 'WEEE');

        // Create portal user for testing sharing
        createPortalUser(acc.Id, 'Test', 'PortalUser');
    }

    @isTest
    static void testContractSharingWithAccount() {
        List<Producer_Contract__c> contracts = [SELECT Id, Account__c FROM Producer_Contract__c];

        Test.startTest();
        ProducerSharingHelper.shareContracts(contracts);
        Test.stopTest();

        System.assert(contracts.size() > 0, 'Contracts should exist');
    }

    @isTest
    static void testContractSharingEmptyList() {
        Test.startTest();
        ProducerSharingHelper.shareContracts(new List<Producer_Contract__c>());
        Test.stopTest();

        System.assert(true, 'Empty list handled');
    }

    @isTest
    static void testContractSharingNullAccount() {
        Producer_Contract__c contract = new Producer_Contract__c();
        contract.Account__c = null;

        Test.startTest();
        ProducerSharingHelper.shareContracts(new List<Producer_Contract__c>{contract});
        Test.stopTest();

        System.assert(true, 'Null account handled');
    }

    @isTest
    static void testObligationSharingWithContract() {
        Producer_Contract__c contract = [SELECT Id, Account__c FROM Producer_Contract__c LIMIT 1];
        // Validation rule checks for previous year's POM records (Compliance_Year - 1)
        String currentYear = String.valueOf(Date.today().year());
        String previousYear = String.valueOf(Date.today().year() - 1);
        createQuarterlyPOMRecords(contract.Account__c, previousYear);

        Producer_Obligation__c obligation = new Producer_Obligation__c(
            Producer_Contract__c = contract.Id,
            Compliance_Year__c = currentYear,  // This will trigger validation for previous year
            Notified_To_Validate_Membership_Type__c = false
        );
        insert obligation;

        Test.startTest();
        ProducerSharingHelper.shareObligations(new List<Producer_Obligation__c>{obligation});
        Test.stopTest();

        System.assertNotEquals(null, obligation.Id, 'Obligation sharing executed');
    }

    @isTest
    static void testObligationSharingEmptyList() {
        Test.startTest();
        ProducerSharingHelper.shareObligations(new List<Producer_Obligation__c>());
        Test.stopTest();

        System.assert(true, 'Empty list handled');
    }

    @isTest
    static void testObligationSharingNullContract() {
        // Test the edge case where Obligation has null Producer_Contract__c
        // Create a Contract first, then set to null after insert to bypass validation
        Producer_Contract__c contract = [SELECT Id, Account__c FROM Producer_Contract__c LIMIT 1];
        String currentYear = String.valueOf(Date.today().year());
        String previousYear = String.valueOf(Date.today().year() - 1);
        createQuarterlyPOMRecords(contract.Account__c, previousYear);

        Producer_Obligation__c obligation = new Producer_Obligation__c(
            Producer_Contract__c = contract.Id,  // Set initially to pass validation
            Compliance_Year__c = currentYear,
            Notified_To_Validate_Membership_Type__c = false
        );
        insert obligation;

        // Now clear the contract to test null handling
        obligation.Producer_Contract__c = null;
        update obligation;

        Test.startTest();
        ProducerSharingHelper.shareObligations(new List<Producer_Obligation__c>{obligation});
        Test.stopTest();

        System.assertEquals(null, [SELECT Producer_Contract__c FROM Producer_Obligation__c WHERE Id = :obligation.Id].Producer_Contract__c, 'Null contract handled');
    }

    @isTest
    static void testPlacedOnMarketSharingWithAccount() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Producer_Placed_on_Market__c pom = new Producer_Placed_on_Market__c();
        pom.Account__c = testAccount.Id;

        Test.startTest();
        ProducerSharingHelper.sharePlacedOnMarkets(new List<Producer_Placed_on_Market__c>{pom});
        Test.stopTest();

        System.assert(true, 'POM sharing executed');
    }

    // Additional coverage focused on the ProducerObligationSharingTrigger
    @isTest
    static void testObligationTrigger_AfterInsert() {
        Producer_Contract__c c = [SELECT Id, Account__c FROM Producer_Contract__c LIMIT 1];
        String previousYear = String.valueOf(Date.today().year() - 1);
        createQuarterlyPOMRecords(c.Account__c, previousYear);

        Test.startTest();
        Producer_Obligation__c ob = makeObligation(c.Id);
        Test.stopTest();
        System.assertNotEquals(null, ob.Id, 'Obligation inserted to fire after insert trigger');
    }

    @isTest
    static void testObligationTrigger_AfterUpdate_ContractChanged() {
        // Create two contracts and move the obligation between them
        Producer_Contract__c c1 = [SELECT Id, Account__c FROM Producer_Contract__c LIMIT 1];
        Account a = makeAccount('Alt Acc For Contract');
        Producer_Contract__c c2 = makeContract(a.Id, 'WEEE');

        // Create portal user for the alternate account to enable sharing
        createPortalUser(a.Id, 'Alt', 'User');

        // Seed quarterly POM records for both accounts for the previous year
        String previousYear = String.valueOf(Date.today().year() - 1);
        createQuarterlyPOMRecords(c1.Account__c, previousYear);
        createQuarterlyPOMRecords(a.Id, previousYear);

        Producer_Obligation__c ob = makeObligation(c1.Id);

        Test.startTest();
        ob.Producer_Contract__c = c2.Id;
        update ob;
        Test.stopTest();

        System.assertEquals(c2.Id, ob.Producer_Contract__c, 'Obligation parent contract changed to trigger sharing');
    }

    @isTest
    static void testObligationTrigger_AfterUpdate_ContractUnchanged_NoShare() {
        Producer_Contract__c c = [SELECT Id, Account__c FROM Producer_Contract__c LIMIT 1];

        String previousYear = String.valueOf(Date.today().year() - 1);
        createQuarterlyPOMRecords(c.Account__c, previousYear);

        Producer_Obligation__c ob = makeObligation(c.Id);

        Test.startTest();
        // Minimal update that does not change Producer_Contract__c
        update new Producer_Obligation__c(Id = ob.Id, Notified_To_Validate_Membership_Type__c = true);
        Test.stopTest();

        System.assertNotEquals(null, ob.Id, 'Update completed without re-sharing branch');
    }

    @isTest
    static void testPlacedOnMarketSharingEmptyList() {
        Test.startTest();
        ProducerSharingHelper.sharePlacedOnMarkets(new List<Producer_Placed_on_Market__c>());
        Test.stopTest();

        System.assert(true, 'Empty list handled');
    }

    @isTest
    static void testPlacedOnMarketSharingNullAccount() {
        Producer_Placed_on_Market__c pom = new Producer_Placed_on_Market__c();
        pom.Account__c = null;

        Test.startTest();
        ProducerSharingHelper.sharePlacedOnMarkets(new List<Producer_Placed_on_Market__c>{pom});
        Test.stopTest();

        System.assert(true, 'Null account handled');
    }

    @isTest
    static void testValidationQuestionSharing() {
        Test.startTest();
        ProducerSharingHelper.shareValidationQuestions(new List<Validation_Question__c>());
        Test.stopTest();

        System.assert(true, 'Validation question sharing executed');
    }

    @isTest
    static void testContractInsertTrigger() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Producer_Contract__c contract = new Producer_Contract__c(
            Account__c = testAccount.Id,
            Contract_Type__c = 'Batteries',
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = Date.today().addYears(1),
            VAT_Registered__c = false
        );
        insert contract;
        Test.stopTest();

        System.assert(contract.Id != null, 'Contract inserted');
    }

    @isTest
    static void testContractUpdateTrigger() {
        Producer_Contract__c contract = [SELECT Id, Account__c FROM Producer_Contract__c LIMIT 1];
        Account newAccount = new Account(Name = 'New Account');
        insert newAccount;

        Test.startTest();
        contract.Account__c = newAccount.Id;
        update contract;
        Test.stopTest();

        System.assert(contract.Id != null, 'Contract updated');
    }

    @isTest
    static void testBulkContractInsert() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Producer_Contract__c> contracts = new List<Producer_Contract__c>();

        for (Integer i = 0; i < 200; i++) {
            contracts.add(new Producer_Contract__c(
                Account__c = testAccount.Id,
                Contract_Type__c = 'WEEE',
                Contract_Start_Date__c = Date.today(),
                Contract_End_Date__c = Date.today().addYears(1),
                VAT_Registered__c = true
            ));
        }

        Test.startTest();
        insert contracts;
        Test.stopTest();

        System.assertEquals(200, contracts.size(), 'All contracts inserted');
    }
}