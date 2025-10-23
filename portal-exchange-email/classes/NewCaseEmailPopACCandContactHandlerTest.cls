@IsTest
private class NewCaseEmailPopACCandContactHandlerTest {

    // Utility: create Case + related EmailMessage
    // IMPORTANT: Uses ParentId to link to Case (required for UpdateEmailCountOnCase trigger)
    private static EmailMessage createEmailForCase(Case c, String fromAddr, String toAddr, String subject, String body) {
        EmailMessage em = new EmailMessage();
        em.ParentId = c.Id;        // Links email to Case - triggers UpdateEmailCountOnCase
        em.RelatedToId = c.Id;     // Also set for handler query compatibility
        em.FromAddress = fromAddr;
        em.ToAddress = toAddr;
        em.Subject = subject;
        em.TextBody = body;
        em.Status = '3'; // Set a valid status to allow insert (e.g., '3' = Sent per platform enum)
        insert em;
        return em;
    }

    @IsTest
    static void testPortalExchangesEmailSetsContactAndAccount() {
        // Arrange
        Account acc = new Account(Name = 'Portal Co');
        insert acc;

        Contact con = new Contact(FirstName = 'John', LastName = 'Smith', Email = 'john.smith@amey.co.uk', AccountId = acc.Id);
        insert con;

        Case c = new Case(Origin = 'Email', Status = 'New', Subject = 'Initial', Total_Emails_Against_Case__c = 0);
        insert c;

        // Insert related EmailMessage from portal-exchanges with body containing (email)
        String body = 'This message was sent by John Smith (john.smith@amey.co.uk) via the portal.';

        // Act: Insert EmailMessage - this triggers UpdateEmailCountOnCase which updates Case
        // which then triggers NewCaseEmailPopACCandContact handler (0→1 transition)
        Test.startTest();
        createEmailForCase(c, 'portal-exchanges@recyclinglives-services.com', '', 'Portal Subject', body);
        Test.stopTest();

        // Requery to assert changes made by automatic trigger chain
        Case cAfter = [SELECT Id, ContactId, AccountId, Subject, Most_Recent_Message__c, Total_Emails_Against_Case__c FROM Case WHERE Id = :c.Id];

        // Assert - handler should have run automatically when count went 0→1
        System.assertEquals(1, cAfter.Total_Emails_Against_Case__c, 'Email count should be auto-updated to 1 by UpdateEmailCountOnCase trigger.');
        System.assertEquals(con.Id, cAfter.ContactId, 'Contact should be set from parsed email in body.');
        System.assertEquals(acc.Id, cAfter.AccountId, 'Account should be set from the contact.');
        System.assertEquals('Portal Subject', cAfter.Subject, 'Subject should be copied from EmailMessage.');
        System.assertNotEquals(null, cAfter.Most_Recent_Message__c, 'Most_Recent_Message__c should be set when first email detected.');
    }

    @IsTest
    static void testInternalEmailSetsContactAndAccountFromToAddressFirst() {
        // Arrange
        Account acc = new Account(Name = 'Internal Co');
        insert acc;

        // The handler splits ToAddress by semicolon and takes the first email
        Contact conFirst = new Contact(FirstName = 'Alice', LastName = 'First', Email = 'first@example.com', AccountId = acc.Id);
        insert conFirst;

        // A second contact to ensure only first one is taken if multiple addresses are present
        Contact conSecond = new Contact(FirstName = 'Bob', LastName = 'Second', Email = 'second@example.com', AccountId = acc.Id);
        insert conSecond;

        Case c = new Case(Origin = 'Email', Status = 'New', Subject = 'Initial', Total_Emails_Against_Case__c = 0);
        insert c;

        // Insert internal EmailMessage (from @recyclinglives-services.com) with multiple To addresses
        String toAddrs = 'first@example.com;second@example.com';

        // Act: Insert EmailMessage - triggers automatic Case update
        Test.startTest();
        createEmailForCase(c, 'agent@recyclinglives-services.com', toAddrs, 'Internal Subject', 'Internal body');
        Test.stopTest();

        // Assert
        Case cAfter = [SELECT Id, ContactId, AccountId, Subject, Total_Emails_Against_Case__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(1, cAfter.Total_Emails_Against_Case__c, 'Email count should be 1.');
        System.assertEquals(conFirst.Id, cAfter.ContactId, 'Should select contact by first ToAddress before semicolon.');
        System.assertEquals(acc.Id, cAfter.AccountId, 'Account should be set from the contact.');
        System.assertEquals('Internal Subject', cAfter.Subject, 'Subject should be taken from EmailMessage.');
    }

    @IsTest
    static void testNoChangeWhenEmailCountChangesFrom1To2() {
        // Arrange
        Account acc1 = new Account(Name = 'First Co');
        insert acc1;

        Account acc2 = new Account(Name = 'Second Co');
        insert acc2;

        Contact con1 = new Contact(FirstName = 'First', LastName = 'User', Email = 'first@example.com', AccountId = acc1.Id);
        insert con1;

        Contact con2 = new Contact(FirstName = 'Second', LastName = 'User', Email = 'second@example.com', AccountId = acc2.Id);
        insert con2;

        // Insert case with 0 emails initially
        Case c = new Case(Origin = 'Email', Status = 'New', Subject = 'Initial', Total_Emails_Against_Case__c = 0);
        insert c;

        // Act: Insert first email (0→1, handler WILL run and set contact/subject)
        createEmailForCase(c, 'portal-exchanges@recyclinglives-services.com', '', 'First Email', 'Body (first@example.com)');

        // Then insert second email (1→2, handler will NOT run)
        Test.startTest();
        createEmailForCase(c, 'portal-exchanges@recyclinglives-services.com', '', 'Second Email', 'Body (second@example.com)');
        Test.stopTest();

        // Assert: Contact/Account from FIRST email should remain (not updated by second email)
        Case cAfter = [SELECT Id, ContactId, AccountId, Subject, Total_Emails_Against_Case__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(2, cAfter.Total_Emails_Against_Case__c, 'Email count should be 2.');
        System.assertEquals(con1.Id, cAfter.ContactId, 'Contact should remain as first email contact (not updated by second email).');
        System.assertEquals(acc1.Id, cAfter.AccountId, 'Account should remain as first email account.');
        System.assertEquals('First Email', cAfter.Subject, 'Subject should remain as first email subject (not changed by second email).');
    }

    @IsTest
    static void testGuardWhenNoRelatedEmailPresent() {
        // Arrange
        Case c = new Case(Origin = 'Email', Status = 'New', Subject = 'Initial', Total_Emails_Against_Case__c = 0);
        insert c;

        // No EmailMessage inserted for this case

        // Act: Update to 1 to attempt trigger
        update new Case(Id = c.Id, Total_Emails_Against_Case__c = 1);

        // Assert: No exception and subject unchanged
        Case cAfter = [SELECT Id, ContactId, AccountId, Subject FROM Case WHERE Id = :c.Id];
        System.assertEquals('Initial', cAfter.Subject, 'Without a related email, subject should not change.');
        System.assertEquals(null, cAfter.ContactId, 'Without a related email, contact should not be set.');
        System.assertEquals(null, cAfter.AccountId, 'Without a related email, account should not be set.');
    }
}