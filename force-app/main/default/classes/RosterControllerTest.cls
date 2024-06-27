@isTest
public class RosterControllerTest {
    public static testmethod void RosterControllerTestMethod(){
        TriggerConfig__c customEmailSetting =  new TriggerConfig__c();
        customEmailSetting.Name = 'Defaulttrigger';
        customEmailSetting.ContactTriggersendEmailForNewContact__c = true;
        customEmailSetting.ContactTriCommunityReimCreate__c = true;
        insert customEmailSetting;
         TrueDialog_Keys__c tdKeys = TestDataFactory.createTrueDialog(true);
         List<Address__c> objAddress = TestDataFactory.createAddress(true, 2,30304);  
         List<IRS_Mileage_Rate__c> obj_IRS_Mileage_Rate =  RecordUtilityClass.insertIrsRate();
         
        RecordUtilityClass.sendEmailforCompliance();
        RecordUtilityClass.enableMappingGasPriceTrigger();
        RecordUtilityClass.vehicleUrlMapping();
        RecordUtilityClass.exceptionEmail();
        
        Vehicle_URL_Mapping__c veh2 = new Vehicle_URL_Mapping__c();
        veh2.URL__c = 'https://cdn3.hubspot.net/hubfs/2511299/iStock-494093356.jpg';
        veh2.vehicle__c = 'Dodge Charger';
        veh2.Year__c = '2020';
        insert veh2;
        
        UserRole userRole_1 = [SELECT Id FROM UserRole WHERE DeveloperName = 'EMD' LIMIT 1];
        Profile profile_1 = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];
        User admin = [SELECT Id, Username, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' AND UserRoleId = :userRole_1.Id LIMIT 1];
        User user_1;
        User user_2;
        Account obj_Account;
        Contact obj_admincontact;
        List<Contact> obj_Manager_list;
        List<Contact> obj_Driver_list;
        Contact obj_Contact2;
        List<Contact> obj_Driver_list1;
        Contact obj_Manager_list1;
        System.runAs(admin) {
            obj_Account = RecordUtilityClass.buildAccount();
            obj_Account.Vehicle_Types__c ='2020 Dodge Charger';
            insert obj_Account;
            Contact contact_1 = new Contact(AccountId = obj_Account.Id, LastName = 'xgeek',External_Email__c='abc@gmail.com',Cell_Phone__c='Company Provide',Reimbursement_Frequency__c='Monthly Reimbursement',Activation_Date__c=system.today());
            insert contact_1;
            obj_admincontact = RecordUtilityClass.buildAdminContact(obj_Account);
            insert obj_admincontact;

            obj_Manager_list = RecordUtilityClass.buildManagerContact(obj_Account,obj_admincontact);
            insert obj_Manager_list;

            obj_Driver_list = RecordUtilityClass.buildDriverContact(obj_Account,obj_Manager_list[0]);
            obj_Contact2 = obj_Driver_list[0];
            obj_Driver_list1 = new List<Contact>();

            for(Integer i=1;i<obj_Driver_list.size();i++)
            {
            obj_Driver_list1.add(obj_Driver_list[i]);
            }
            insert obj_Driver_list1;

            obj_Manager_list1 = new Contact();
            obj_Manager_list1 = RecordUtilityClass.getManagerContact();
       
            user_1 = new User( 
                Email = 'yourusername@gmail.com',
                ProfileId = profile_1.Id, 
                UserName = 'yourusername@gmail.com', 
                Alias = 'Test',
                TimeZoneSidKey = 'America/New_York',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = 'en_US', 
                LanguageLocaleKey = 'en_US',
                ContactId = contact_1.Id,
                PortalRole = 'Manager',
                FirstName = 'Firstname',
                LastName = 'Lastname'
                );
            insert user_1;
            
             
        }
        	List<Id> conListID =new List<Id>();
        	conListID.add(obj_Driver_list[0].Id);
        	String JsonString=JSON.serialize(conListID);
         
        EmployeeDetails empDetail = WrapperUtils.getEmployeeDetails(obj_Driver_list1[0],120.34,230.43);
        EmployeeDetails empDetail1 = WrapperUtils.getEmployeeDetails(obj_Driver_list1[0],120.34,230.43);
         String str = '[{\"Role\":\"Driver\",\"FirstName\":\"wo\",\"LastName\":\"pas\",\"EmailAddress\":\"wopas601856@yubua.com\",\"CellPhone\":1234565432,\"City\":\"Villa Rica\",\"State\":\"GA\",\"ZipCode\":30180,\"Department\":\"ENV\",\"JobTitle\":\"Inspector/Consultant\",\"ManagersFirstName\":\"ceni\",\"ManagersLastName\":\"pi\",\"ManagersEmail\":\"cenipi2424@zfobo.com\",\"InsuranceRate\":3134,\"LicenseandRegistration\":102,\"PersonalPropertyTax\":733,\"Depreciation\":4435,\"AnnualFixedCost\":8404,\"FixedAmount\":500.04,\"FCA\":1,\"TotalFixedAmount\":500.04,\"Meeting\":\"Attended\",\"Packet\":\"Sent\",\"DateAdded\":\"2021-10-19T18:30:00.000Z\",\"ActivationDate\":\"2022-01-31T18:30:00.000Z\",\"MPG\":25.5,\"Maint\":0.0738,\"Tires\":0.0689,\"MaintTires\":0.1427,\"StandardVehicle\":\"2022 Volkswagen Atlas\",\"ComplianceMileage\":5000,\"VehicleURL\":\"https://f.hubspotusercontent40.net/hubfs/2511299/2022-Chevy-Silverado.jpeg\"},{\"Role\":\"Driver\",\"FirstName\":\"yu\",\"LastName\":\"bua\",\"EmailAddress\":\"wopas60185@yubua.com\",\"CellPhone\":1334565432,\"City\":\"Wilmington\",\"State\":\"NC\",\"ZipCode\":28412,\"Department\":\"ENV\",\"JobTitle\":\"Inspector/Consultant\",\"ManagersFirstName\":\"ceni\",\"ManagersLastName\":\"pi\",\"ManagersEmail\":\"cenipi2424@zfobo.com\",\"InsuranceRate\":2122,\"LicenseandRegistration\":177,\"PersonalPropertyTax\":262,\"Depreciation\":3844,\"AnnualFixedCost\":6405,\"FixedAmount\":381.1,\"FCA\":2,\"TotalFixedAmount\":381.1,\"Meeting\":\"Attended\",\"Packet\":\"Sent\",\"DateAdded\":\"2021-06-14T18:30:00.000Z\",\"ActivationDate\":\"2022-05-18T18:30:00.000Z\",\"MPG\":26,\"Maint\":0.0495,\"Tires\":0.0408,\"MaintTires\":0.0903,\"StandardVehicle\":\"2022 Ford F-150\",\"ComplianceMileage\":5000,\"VehicleURL\":\"https://f.hubspotusercontent40.net/hubfs/2511299/2022-Chevy-Silverado.jpeg\"}]';
            Blob csvFileBody = Blob.valueOf(str);
            String csvAsString = csvFileBody.toString();

        empDetail.FirstName = 'test';
        empDetail.activationDate = '12/12/2018';
        List<EmployeeDetails> obj_list_EmployeeDetails = new List<EmployeeDetails>();
        obj_list_EmployeeDetails.add(empDetail);
        Test.startTest();
       
        System.runAs(user_1) {
            Test.setCurrentPage(Page.roster);
            String conId = ApexPages.currentPage().getParameters().put('id',obj_admincontact.Id);
            String accId = ApexPages.currentPage().getParameters().put('accid',obj_Account.Id);
            RosterController ros = new RosterController();
            RosterController.getAccountid();
            RosterController.getContactid();
            RosterController.getRedirected();
            RosterController.editInlineNewEmployee(JSON.serialize(obj_list_EmployeeDetails),String.valueOf(obj_Account.Id),String.valueOf(obj_admincontact.Id));
            RosterController.getAllManagers(String.valueOf(obj_Account.id));
            RosterController.getlistAllEmployees(obj_Account.Id,obj_admincontact.Id);
            RosterController.getRoles();
            RosterController.getDriverType();
            RosterController.getJobTitle();
            RosterController.getDepartment();
            RosterController.getDrivingStates();
            RosterController.resetPassword(obj_admincontact.Id);
            RosterController.getUser(obj_admincontact.Id);
            RosterController.sendExceptionMails('Insert Failed','1');
            RosterController.getCustomExceptionMessage('1');
            String batchId = RosterController.readFromFile(csvAsString,accId,obj_admincontact.Id);
            RosterController.CheckStatus(batchId);
            RosterController.editEmployeeDetails(obj_Manager_list[0].Id);
            RosterController.getContactByEmailAddress(obj_Manager_list[0].External_Email__c);
            RosterController.manageEmployee(JSON.serialize(obj_list_EmployeeDetails),String.valueOf(obj_Account.id),String.valueOf(obj_admincontact.Id));
            RosterController.getCountryStateCity('36310');
            RosterController.getCity('Abbeville','36310');
            RosterController.getCompany();
            RosterController.getPickListValuesIntoList(String.valueOf(obj_Account.id));
            RosterController.getCustomEmployeeTableSettings();
            RosterController.getCustomAddEmployeeSettings();
            List<String> conIdList = new List<String>();
            for(contact cont:obj_Manager_list){
                conIdList.add(cont.Id);
            } 
            
            List<Employee_Reimbursement__c> er = TestDataFactory.createPendingReimbursement(true, obj_Driver_list1, 3, obj_IRS_Mileage_Rate[0].Id);
            List<Bi_Weekly_Reimbursement__c> br = TestDataFactory.createBiweeklyReim (true, obj_Driver_list1, Date.valueof('2021-12-09'),Date.valueof('2021-12-20'), 1, obj_IRS_Mileage_Rate[0].Id);
          
            List<Employee_Mileage__c> emp2 = TestDataFactory.getEmpMileage (true, 1, er, br);
            
            RosterController.LOAWrapper empW = new RosterController.LOAWrapper();
             empW.BiweekId = string.valueOf(br[0].Id);
             empW.ContactEmail = 'rghgfhgf21212@gmail.com';  
             empW.LOAStartDate = '2021-12-22'; 
             empW.LOAEndDate  = '2021-12-29';
             empW.HalfFixedAmount  = 234.43;
             empW.ContactName = 'Test Name';
            
            RosterController.massFreeze(JSON.serialize(conIdList),true);
            RosterController.editInlineNewEmployee(NULL,'','');
            empDetail.lastname='sdhshdgsag21212';
            empDetail1.userid =NULL;
            empDetail.email ='rghgfhgf21212@gmail.com';
            List<EmployeeDetails> obj_list_EmployeeDetails1 = new List<EmployeeDetails>();
            obj_list_EmployeeDetails1.add(empDetail1);
            RosterController.manageEmployee(JSON.serialize(obj_list_EmployeeDetails1),String.valueOf(obj_Account.id),String.valueOf(obj_admincontact.Id));
            List<id> insertedContactIDList = new List<id>();
            for(Contact currentcontact:obj_Driver_list1)
            {
                insertedContactIDList.add(currentcontact.id);
            }        
            RosterController.postHTTPCreateNewUserTriplog(insertedContactIDList);
            RosterController.getExcetionTypes('System.DmlException','[UPDATE FAILED]',12);
            RosterController.getExcetionTypes('TypeException','Invalid decimal: .',12);
            RosterController.getExcetionTypes('QueryException','List has no rows',12);
            RosterController.getExcetionTypes('QueryException','LIST HAS NO ROWS',12);
            RosterController.getExcetionTypes('NullPointerException','Attempt to de-reference',12);
            RosterController.putHTTP(String.valueOf(obj_Account.id),'test1932434230@testing.com');
            RosterController.massEnableUser(JSON.serialize(insertedContactIDList));
            //RosterController.massResetPassword(JSON.serialize(insertedContactIDList));
            RosterController.updateLockDate(String.valueOf(obj_Account.id),'12/21/2023','06-2023');
            RosterController.putHTTPConcurConnect(obj_Account.Id,'yourusername@gmail.com');
            RosterController.putHTTPConcurConnect(String.valueOf(obj_Account.id),'test1932434230@testing.com');
            RosterController.deleteTrips(obj_Account.Id,'06-2023');
            RosterController.getLoginAsData(obj_Account.Id);
            RosterController.BiweekReimRecord('2021-12-09','2021-12-20',String.valueOf(obj_Account.id));
            RosterController.SaveLOA(string.valueOf( JSON.serialize(obj_list_EmployeeDetails)));
            RosterController.deleteMonthlyReim(obj_Driver_list1[0].Id, system.today().addMonths(-2));
             RosterController.getPicklistValues();
            RosterController.putHTTPMassWlcmMail(String.valueOf(obj_Account.id), '["jiyush@goc.com","vipin@kiwiqa.com","priyapatel@gmail.com"]');
        	RosterController.ChangingOwnerInBulk(JsonString,obj_admincontact.Id);
            RosterController.sendSignatureRequestForDriver(JsonString,obj_admincontact.Id);
        }
        
        Test.stopTest();
    }
    public static testmethod void RosterControllerTestMethod1(){
        TriggerConfig__c customEmailSetting =  new TriggerConfig__c();
        customEmailSetting.Name = 'Defaulttrigger';
        customEmailSetting.ContactTriggersendEmailForNewContact__c = true;
        customEmailSetting.ContactTriCommunityReimCreate__c = true;
        insert customEmailSetting;
        TrueDialog_Keys__c tdKeys = TestDataFactory.createTrueDialog(true);
        List<Address__c> objAddress = TestDataFactory.createAddress(true, 2,30304);
        SendEmail__c customSetting =  new SendEmail__c();
        customSetting.Name = 'Send Email For Compliance';
        customSetting.Send_email_from_code__c= true;
        insert customSetting;

        List<IRS_Mileage_Rate__c> obj_IRS_Mileage_Rate =  RecordUtilityClass.insertIrsRate();
        Test.startTest();
            RosterController ros = new RosterController();
            RosterController.getAccountid();
            RosterController.getContactid();
            RosterController.getRedirected();    
        Test.stopTest();
    }
}