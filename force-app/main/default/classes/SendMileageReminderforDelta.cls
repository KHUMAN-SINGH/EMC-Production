global class SendMileageReminderforDelta implements Database.batchable<sObject>,Database.Stateful {

    public List<String> listAccount {get;set;}
    public Map<String,List<String>> accountidEmails {get;set;}
    Global  List<EmailTemplate> emailTemplate;
    public SendMileageReminderforDelta()
    {
        accountidEmails = new Map<String,List<String>>();
        String accountName = Label.Delta_Account_Name;
        listAccount = new List<String>();
        if(accountName != null) {
            listAccount = accountName.split(',');
        }
        System.debug('account name '+listAccount);
    }
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        System.debug('account name '+listAccount);
        String  query = 'select Id, FirstName, External_Email__c,Role__c,AccountId FROM Contact WHERE Account.Name IN: listAccount AND (Role__c = \'Driver\' OR Role__c = \'Driver/Manager\' OR Role__c = \''+StaticValues.roleAdminDriver+'\' OR Role__c = \'Admin\') AND (Deactivated_Date__c = NULL OR Deactivated_Date__c >= LAST_N_DAYS:30)';
        //String  query = 'select Id, FirstName, External_Email__c,Role__c,AccountId FROM Contact WHERE Id=\'003Nt000003FpIW\'';
        
        System.debug('account name '+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
    
    emailTemplate = new List<EmailTemplate>([SELECT Id, Subject, body, HTMLValue  
                                                                    FROM EmailTemplate 
                                                                        WHERE developerName = 'Monthly_mileage_reminder_New']);
    OrgWideEmailAddress[] owea = [select Id ,address from OrgWideEmailAddress where Address = 'driverservices@mburse.com'];
    List<Messaging.SingleEmailMessage> singleEmailMessageList = new List<Messaging.SingleEmailMessage>();
    SendEmailonDeactivation__c customSettings = SendEmailonDeactivation__c.getValues('SendMileageReminderforDelta');  
        for(Contact currentContact : (List<Contact>)scope) 
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> myEmail = new List<String>();
            List<String> bccEmailaddress = new List<String>(); 
            string htmlbody = ''; 
            
            if(customSettings!=null && customSettings.Send_to_Driver__c == true && currentContact.External_Email__c != null){
            myEmail.add(currentContact.External_Email__c);
            mail.setToAddresses(myEmail);
            system.debug('myEmail==' + myEmail);
            
            if(customSettings.BCCEmailaddresses__c!=null && customSettings.BCCEmailaddresses__c.contains(',')){
                bccEmailaddress.addAll(customSettings.BCCEmailaddresses__c.split(','));
            }
            else if(customSettings.BCCEmailaddresses__c!=null) {
                bccEmailaddress.add(customSettings.BCCEmailaddresses__c);
            }
            }
            else {
                if(customSettings.BCCEmailaddresses__c!=null && customSettings.BCCEmailaddresses__c.contains(',')){
                    myEmail.addAll(customSettings.BCCEmailaddresses__c.split(','));
                    mail.setToAddresses(myEmail);
                }
                else if(customSettings.BCCEmailaddresses__c!=null) {
                    myEmail.add(customSettings.BCCEmailaddresses__c);
                    mail.setToAddresses(myEmail);
                }
            }

            mail.setSubject(emailTemplate[0].Subject);
            htmlbody = emailTemplate[0].HTMLValue;
            DateTime currentDate = DateTime.now();
            string monthString = currentDate.format('MMMM');
            String YearString =String.valueOf(Currentdate.year());
            System.debug('month'+monthString);
            System.debug('year'+YearString);

            htmlbody = htmlbody.replace('{!CurrentMonth}', monthString);
            htmlbody = htmlbody.replace('{!CurrentYear}', YearString);
            
            if(currentContact.FirstName != null){
                htmlbody = htmlbody.replace('{!Contact.FirstName}', currentContact.FirstName);
            } else {
                htmlbody = htmlbody.replace('{!Contact.FirstName}', '');
            }
            mail.setPlainTextBody(htmlbody);
            mail.setHtmlBody(htmlbody);
            system.debug('htmlbody ==' + htmlbody );
            
            if(bccEmailaddress.size()>0)
            {
                mail.setBccAddresses(bccEmailaddress);     
            }     
            if (owea.size() > 0 ) 
            {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
             if(myEmail.size()>0)
            {
                singleEmailMessageList.add(mail);
            }
        }  
        SendEmail__c  sendEmailObj = SendEmail__c.getValues('SendMileageReminderforDelta');
        if((sendEmailObj!=null) && sendEmailObj.Send_email_from_code__c==true && singleEmailMessageList.size()>0 && !Test.isRunningTest())
        {
            Messaging.sendEmail(singleEmailMessageList);  
        }     
          
    }
   
    global void finish(Database.BatchableContext BC) {
        
    }
   
}