public class NewCaseEmailPopACCandContactHandler {
    public static void handleCaseUpdates(List<Case> newCases, Map<Id, Case> oldMap) {
        for (Case newCase : newCases) {
            try{
                Case oldCase = oldMap.get(newCase.Id);
                if (newCase.Total_Emails_Against_Case__c == 1 && (oldCase == null || oldCase.Total_Emails_Against_Case__c != newCase.Total_Emails_Against_Case__c)) {
                    newCase.Most_Recent_Message__c = DateTime.now();

                    // Retrieve the latest email related to the case
                    List<EmailMessage> relatedEmails = [SELECT FromAddress, ToAddress, Subject, TextBody FROM EmailMessage WHERE RelatedToId = :newCase.Id LIMIT 1];
                    if (!relatedEmails.isEmpty() && relatedEmails[0].FromAddress != null) {

                        // Check if email is from portal exchanges
                        if (relatedEmails[0].FromAddress == 'portal-exchanges@recyclinglives-services.com') {
                            // Extract portal user email from body text
                            String portalUserEmail = extractEmailFromBody(relatedEmails[0].TextBody);

                            if (portalUserEmail != null) {
                                List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Email = :portalUserEmail LIMIT 1];
                                if (!contacts.isEmpty()) {
                                    newCase.ContactId = contacts[0].Id;
                                    newCase.AccountId = contacts[0].AccountId;
                                }
                            }
                            newCase.Subject = relatedEmails[0].Subject;
                        }
                        // Handle other internal emails (original logic)
                        else if (relatedEmails[0].FromAddress.contains('@recyclinglives-services.com')) {
                            String[] emailAddresses = relatedEmails[0].ToAddress.split(';', 2); // Splitting by semicolon
                            String firstEmail = emailAddresses[0]; // Take the first email address

                            // Check if there is a contact with this email address
                            List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Email = :firstEmail LIMIT 1];
                            if (!contacts.isEmpty()) {
                                newCase.ContactId = contacts[0].Id;
                                newCase.AccountId = contacts[0].AccountId;
                            }
                            newCase.Subject = relatedEmails[0].Subject;
                        }
                    }
                }
            }catch(Exception e){
                System.debug('e :: ' + e.getMessage());
            }
        }
    }

    // Helper method to extract portal user email from email body
    private static String extractEmailFromBody(String emailBody) {
        if (String.isBlank(emailBody)) {
            return null;
        }

        // Look for pattern like "sent by John Smith (john.smith@amey.co.uk)"
        // Extract email address within parentheses
        Pattern emailPattern = Pattern.compile('\\(([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})\\)');
        Matcher emailMatcher = emailPattern.matcher(emailBody);

        if (emailMatcher.find()) {
            return emailMatcher.group(1);
        }

        return null;
    }
}