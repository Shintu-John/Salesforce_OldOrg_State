global class ExportVendorInvoiceSageBatch implements Database.Batchable<SObject>,Database.Stateful,Database.AllowsCallouts {
    global Set<Id> vendorInvoiceIds {get;set;}
    List<String> resultLogLines {get;set;}
    Integer successfullJobCount {get;set;}
    Integer failedJobCount {get;set;}
    public string uemail {get;set;}
    // Pass in the invoice IDs you want to process, e.g. from a button or another controller.
    global ExportVendorInvoiceSageBatch(Set<Id> invoiceIds) {
        this.vendorInvoiceIds = invoiceIds;
        this.resultLogLines=new List<String>();
        this.successfullJobCount=0;
        this.failedJobCount=0;
        this.uemail = UserInfo.getUserEmail();
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Transaction_Type_2__c, Sage_Ref__c, Nominal_Code__c, Sage_Dept_Code__c, Sage_Invoice_Date__c,
                   Sage_Details__c, Total_Net__c, Sage_Tax_Code__c, VAT_Amount__c, Total__c, VAT__c, Credit_Total__c,SageId_Ref__c,
                   Vendor_Invoice_URN__c, Invoice_Date__c, Sage_URN__c, Sage_TransactionId__c,IsRLCS__c,
                   RLCS_Nominal_Code__c, RLCS_Cost_Centre__c
            FROM Vendor_Invoice__c
            WHERE Id IN :vendorInvoiceIds
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Vendor_Invoice__c> scope) {
        string log='<tr>';// Invoice Name</td><td>Invoice Date</td><td>Invoice Amount</td><td>Invoice Status</td><td>Invoice URN</td><td>Invoice Transaction Id</td></tr>';
        // Query related Vendor_Invoice_Credit__c records for this chunk of vendor invoices
        Set<Id> invoiceIds = new Set<Id>();
        try {
            
        
            for (Vendor_Invoice__c vi : scope) {
                invoiceIds.add(vi.Id);
                log+= '<td><a href="'+System.Url.getOrgDomainUrl().toExternalForm()+'/'+vi.Id+'">'+vi.Name+'</a></td><td>';
                System.debug('log: '+log);
            }
            

            List<Vendor_Invoice_Credit__c> vendorInvoiceCreditRecs = [
                SELECT Id, Name, Sage_Transaction_Type__c, Sage_Credit_Date__c, Credit_Reference__c,
                    Sage_Details__c, Amount_NET__c, VAT_Amount__c, Vendor_Invoice__c,
                    Sage_URN__c, Sage_TransactionId__c,Credit_Date__c
                FROM Vendor_Invoice_Credit__c
                WHERE Vendor_Invoice__c IN :invoiceIds
            ];

            // Build the credit note map
            Map<Id, List<Vendor_Invoice_Credit__c>> vendorInvoiceCreditMap = new Map<Id,List<Vendor_Invoice_Credit__c>>();
            for (Vendor_Invoice_Credit__c vic : vendorInvoiceCreditRecs) {
                if (!vendorInvoiceCreditMap.containsKey(vic.Vendor_Invoice__c)) {
                    vendorInvoiceCreditMap.put(vic.Vendor_Invoice__c, new List<Vendor_Invoice_Credit__c>());
                }
                vendorInvoiceCreditMap.get(vic.Vendor_Invoice__c).add(vic);
            }

            // First, send each invoice and its credit notes to Sage
            for (Vendor_Invoice__c vendorInvoiceRec : scope) {

                SageAPIClient.isRLCS=vendorInvoiceRec.IsRLCS__c;
                if(vendorInvoiceRec.Transaction_Type_2__c  =='PC')
                    {
                        
                        SageAPIClient.SendPurhcaseCreditNoteInvoice(vendorInvoiceRec, true);
                    }
                    else {
    
                        // Send the purchase invoice
                        SageAPIClient.SendPurhcaseInvoice(vendorInvoiceRec, true);

                        // Send the credit notes
                        if (vendorInvoiceCreditMap.containsKey(vendorInvoiceRec.Id)) {
                            for (Vendor_Invoice_Credit__c vendorInvoiceCreditRec : vendorInvoiceCreditMap.get(vendorInvoiceRec.Id)) {
                                SageAPIClient.SendPurhcaseCreditNoteInvoice(vendorInvoiceRec, vendorInvoiceCreditRec, true);
                            }
                        }
                }
            }

            // After sending invoices and credits, gather and send notes
            List<SageModels.SupplierTransactionNote> notes = new List<SageModels.SupplierTransactionNote>();
            for (Vendor_Invoice__c vendorInvoiceRec : scope) {
                // Files for the invoice
               List<String> pfiles=Test.isRunningTest()? ReadRelatedFilesWithPublicLink(vendorInvoiceRec.Id): SageAPIHelper.ReadRelatedFilesWithPublicLink(vendorInvoiceRec.Id);
                if (!pfiles.isEmpty() && vendorInvoiceRec.Sage_URN__c != null && vendorInvoiceRec.Sage_TransactionId__c != 0) {
                    SageModels.SupplierTransactionNote note = new SageModels.SupplierTransactionNote();
                    note.posted_supplier_transaction_id = Integer.valueOf(vendorInvoiceRec.Sage_TransactionId__c);
                    note.note = '';
                    note.isRLCS=vendorInvoiceRec.IsRLCS__c;
                    for (String s : pfiles) {
                        note.note += s + '\r\n';
                    }
                    note.is_active = true;
                    notes.add(note);
                }

                // Files for the related credit notes
                if (vendorInvoiceCreditMap.containsKey(vendorInvoiceRec.Id)) {
                    for (Vendor_Invoice_Credit__c vendorInvoiceCreditRec : vendorInvoiceCreditMap.get(vendorInvoiceRec.Id)) {
                         List<String> files=Test.isRunningTest()? ReadRelatedFilesWithPublicLink(vendorInvoiceCreditRec.Id): SageAPIHelper.ReadRelatedFilesWithPublicLink(vendorInvoiceCreditRec.Id);
                        if (!files.isEmpty() && vendorInvoiceCreditRec.Sage_URN__c != null && vendorInvoiceCreditRec.Sage_TransactionId__c != 0) {
                            SageModels.SupplierTransactionNote creditNote = new SageModels.SupplierTransactionNote();
                            creditNote.posted_supplier_transaction_id = Integer.valueOf(vendorInvoiceCreditRec.Sage_TransactionId__c);
                            creditNote.note = '';
                             creditNote.isRLCS=vendorInvoiceRec.IsRLCS__c;
                            for (String s : files) {
                                creditNote.note += s + '\r\n';
                            }
                            creditNote.is_active = true;
                            notes.add(creditNote);
                        }
                    }
                }
            }

            // Update the invoices
            update scope;

            // Send notes to Sage if any
            if (!notes.isEmpty()) {
                for (SageModels.SupplierTransactionNote n : notes) {
                    if(!Test.isRunningTest()) { System.enqueueJob(new SageTransactionNoteQueueable(n.note, n.posted_supplier_transaction_id,true,n.isRLCS));}
                    //SageAPIClient.SendSupplierTransactionMemo(n.note, n.posted_supplier_transaction_id);
                }
            }
            log+=scope[0].Sage_URN__c +'</td></tr>';
            successfullJobCount++;
        } catch (Exception ex) {
            log+=ex.getMessage()+' '+ex.getStackTraceString()+'</td></tr>';
            failedjobCount++;
        }
        System.debug('log: '+log);
        resultLogLines.add(log);
    }

    global void finish(Database.BatchableContext bc) {
       
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.toAddresses = new String[] {this.uemail};
            mail.setSenderDisplayName('Salesforce Support');
            mail.setUseSignature(false);
            mail.setBccSender(false);
            mail.setSaveAsActivity(false);
            mail.setSubject('Sage Vendor Invoice Batch Send Log');
            String mailBody = '<html><body>Sage Vendor Invoice Batch Result Log</p></br>';
            mailBody += '<p>Successfull Invoice Count: '+successfullJobCount+'</p></br>';
            mailBody += '<p>Failed Invoice Count: '+failedJobCount+'</p></br>';
            mailBody += '<p><table border="1"><tr><td>Invoice Name</td><td>Invoice URN</td></tr>';
            mailBody += String.join(resultLogLines, '');
            mailBody += '</table></p>';
            mailBody += '</body></html>';
            mail.setHtmlBody(mailBody);
            System.debug('Sending email');
            System.debug('resultLogLines: '+resultLogLines);
             if (Test.isRunningTest() == false){ Messaging.SendEmailResult [] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });}
        }
    
     private List<String> ReadRelatedFilesWithPublicLink(Id invoiceId) {
        return new List<String>{'https://fakefile1.com', 'https://fakefile2.com'};
    }
    
 
}