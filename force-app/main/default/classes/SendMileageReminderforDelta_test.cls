@isTest
Public class SendMileageReminderforDelta_test{
    public static testmethod void test1(){
        TriggerConfig__c triggerCustomSetting = TestDataFactory.triggerConfigCustomSetting(true);
        TrueDialog_Keys__c tdKeys = TestDataFactory.createTrueDialog(true);
        Vehicle_URL_Mapping__c veh = new Vehicle_URL_Mapping__c();
        veh.URL__c = 'https://cdn2.hubspot.net/hubfs/2511299/iStock-494093356.jpg';
        veh.vehicle__c = 'Full-Size Sedan';
        veh.Year__c = '2019';
        insert veh;

        SendEmail__c sendemail = new SendEmail__c();
        sendemail.Name = 'Send Email For Compliance';
        sendemail.Send_email_from_code__c = true;
        insert sendemail;
        
        SendEmail__c customSetting2 =  new SendEmail__c();
        customSetting2.Name = 'SendMileageReminderforDelta';
        customSetting2.Send_email_from_code__c= true;
        insert customSetting2;
        
        SendEmailonDeactivation__c customSetting3 = new SendEmailonDeactivation__c();
        customSetting3.Name = 'SendMileageReminderforDelta';
        customSetting3.Send_to_Driver__c = true;
        insert customSetting3 ;
        
        TriggerConfig__c customSetting =  new TriggerConfig__c();
        customSetting.Name = 'Defaulttrigger';
        customSetting.MappingGasPriceTrigger__c = true;
        insert customSetting;
        
        UserRole userRole = TestDataFactory.getUserRole();
        Profile profileObj = TestDataFactory.getUserProfile();
        User admin = TestDataFactory.getSystemAdminUser(userRole.Id);
        User userObj;
        
         //Insert Account data Using Utility class
         
         Account acc = new Account();
         List<Contact> conList = new List<Contact>(); 
         System.runAs(admin) {
            
            acc = TestDataFactory.createAccount(false,'Test Accounts',true);
            acc.Pay_Period_Start_Date__c = System.today().addDays(-100);
            acc.Pay_Period_Days__c = 6;
            insert acc;
           
            //Insert Contact data 
            conList = TestDataFactory.createDriverContact(false, acc.Id, 'Driver', veh.Name, 'Paras.Patel', 1);
            conList[0].Deactivated_Date__c = null;
            conList[0].Vehicle_Type__c  = '2019 Full-Size Sedan';
            Insert conList[0];
        }
        Test.startTest();

        SendMileageReminderforDelta objSendMileageReminderforDelta= new SendMileageReminderforDelta();
        Database.executeBatch(objSendMileageReminderforDelta,1);

        Test.stopTest();
    }   
           
}