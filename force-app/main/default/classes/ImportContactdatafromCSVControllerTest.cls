@isTest
public class ImportContactdatafromCSVControllerTest {
    @isTest 
    public static void test() {
        TriggerConfig__c triggerCustomSetting = TestDataFactory.triggerConfigCustomSetting(true);
        SendEmail__c sendEmailCustomSetting1 = TestDataFactory.sendEmailCustomSetting(true,'Send Email For Compliance');
        TrueDialog_Keys__c tdKeys = TestDataFactory.createTrueDialog(true);
        Vehicle_URL_Mapping__c vehicleObj = TestDataFactory.createVehicleData(true,1);
        IRS_Mileage_Rate__c irsRateObj = TestDataFactory.createIRSRate(true,0);
        
        Account acc = new Account();     
        List<Contact> conList = new List<Contact>();
        List<Contact> adminConList = new List<Contact>();
        
        UserRole userRole = TestDataFactory.getUserRole();
        Profile profileObj = TestDataFactory.getUserProfile();
        User admin = TestDataFactory.getSystemAdminUser(userRole.Id);
        User userObj;
        System.runAs(admin) {
            acc = TestDataFactory.createAccount(false,'Test',true);
            acc.Vehicle_Types__c=vehicleObj.name;
            acc.True_Dialog__c = true;
            acc.Vehicle_Types__c = vehicleObj.Name;
            Insert acc;
            Contact contactObj = TestDataFactory.createCICDContact(true,acc.Id);
            adminConList = TestDataFactory.createDriverContact(true, acc.Id, 'Admin', vehicleObj.Name, 'test1.email', 1);
            conList = TestDataFactory.createDriverContact(true, acc.Id, 'Driver', vehicleObj.Name, 'test.email', 1);
            userObj = TestDataFactory.createUser(true, profileObj.Id, conList[0].Id);
        }

        Attachment attach = TestDataFactory.createAttachment(true, conList[0].id);
        List<Attachment> attachments = [select id, name from Attachment where parent.id =: conList[0].id];        
        String strOriginal ='[{\"Role\":\"Driver\",\"FirstName\":\"wo\",\"LastName\":\"pas\",\"EmailAddress\":\"wopas601856@yubua.com\",\"CellPhone\":1234565432,\"City\":\"Villa Rica\",\"State\":\"GA\",\"ZipCode\":30180,\"Department\":\"ENV\",\"JobTitle\":\"Inspector/Consultant\",\"ManagersFirstName\":\"ceni\",\"ManagersLastName\":\"pi\",\"ManagersEmail\":\"cenipi2424@zfobo.com\",\"InsuranceRate\":3134,\"LicenseandRegistration\":102,\"PersonalPropertyTax\":733,\"Depreciation\":4435,\"AnnualFixedCost\":8404,\"FixedAmount\":500.04,\"FCA\":1,\"TotalFixedAmount\":500.04,\"Meeting\":\"Attended\",\"Packet\":\"Sent\",\"DateAdded\":\"2021-10-19T18:30:00.000Z\",\"ActivationDate\":\"2022-01-31T18:30:00.000Z\",\"MPG\":25.5,\"Maint\":0.0738,\"Tires\":0.0689,\"MaintTires\":0.1427,\"StandardVehicle\":\"2022 Volkswagen Atlas\",\"ComplianceMileage\":5000,\"VehicleURL\":\"https://f.hubspotusercontent40.net/hubfs/2511299/2022-Chevy-Silverado.jpeg\"},{\"Role\":\"Driver\",\"FirstName\":\"yu\",\"LastName\":\"bua\",\"EmailAddress\":\"wopas60185@yubua.com\",\"CellPhone\":1334565432,\"City\":\"Wilmington\",\"State\":\"NC\",\"ZipCode\":28412,\"Department\":\"ENV\",\"JobTitle\":\"Inspector/Consultant\",\"ManagersFirstName\":\"ceni\",\"ManagersLastName\":\"pi\",\"ManagersEmail\":\"cenipi2424@zfobo.com\",\"InsuranceRate\":2122,\"LicenseandRegistration\":177,\"PersonalPropertyTax\":262,\"Depreciation\":3844,\"AnnualFixedCost\":6405,\"FixedAmount\":381.1,\"FCA\":2,\"TotalFixedAmount\":381.1,\"Meeting\":\"Attended\",\"Packet\":\"Sent\",\"DateAdded\":\"2021-06-14T18:30:00.000Z\",\"ActivationDate\":\"2022-05-18T18:30:00.000Z\",\"MPG\":26,\"Maint\":0.0495,\"Tires\":0.0408,\"MaintTires\":0.0903,\"StandardVehicle\":\"2022 Ford F-150\",\"ComplianceMileage\":5000,\"VehicleURL\":\"https://f.hubspotusercontent40.net/hubfs/2511299/2022-Chevy-Silverado.jpeg\"}]'; 
        System.debug('strOriginal==' + strOriginal);
        final Blob dataDocuments ;
        string accId;
        Test.startTest();
            ImportContactdatafromCSVController i = new ImportContactdatafromCSVController(strOriginal,  acc.Id, adminConList[0].id);
            Database.executeBatch(I);
            dataDocuments = Blob.valueOf('strOriginal');
            accId = acc.Id;
           // Date cvtDate = ImportContactdatafromCSVController.convertDateFormat('20/12/2022');
        Test.stopTest();
   }

   @isTest 
    public static void test1() {
        TriggerConfig__c triggerCustomSetting = TestDataFactory.triggerConfigCustomSetting(true);
        SendEmail__c sendEmailCustomSetting1 = TestDataFactory.sendEmailCustomSetting(true,'Send Email For Compliance');
        TrueDialog_Keys__c tdKeys = TestDataFactory.createTrueDialog(true);
        Vehicle_URL_Mapping__c vehicleObj = TestDataFactory.createVehicleData(true,1);
        IRS_Mileage_Rate__c irsRateObj = TestDataFactory.createIRSRate(true,0);
        
        Account acc = new Account();     
        List<Contact> conList = new List<Contact>();
        List<Contact> adminConList = new List<Contact>();
        
        UserRole userRole = TestDataFactory.getUserRole();
        Profile profileObj = TestDataFactory.getUserProfile();
        User admin = TestDataFactory.getSystemAdminUser(userRole.Id);
        User userObj;
        System.runAs(admin) {
            
            acc = TestDataFactory.createAccount(false,'Test',true);
            acc.True_Dialog__c = true;
            acc.Vehicle_Types__c = vehicleObj.Name;
            Insert acc;
            Contact contactObj = TestDataFactory.createCICDContact(true,acc.Id);
            conList = TestDataFactory.createDriverContact(true, acc.Id, 'Driver', vehicleObj.Name, 'test.email', 1);
            adminConList = TestDataFactory.createDriverContact(true, acc.Id, 'Admin', vehicleObj.Name, 'test1.email', 1);
            userObj = TestDataFactory.createUser(true, profileObj.Id, conList[0].Id);
            //insert userObj;
        }
        
        Attachment attach = TestDataFactory.createAttachment(true, conList[0].id);
        List<Attachment> attachments = [select id, name from Attachment where parent.id =: conList[0].id];
        String strOriginal ='[{\"Role\":\"Driver\",\"FirstName\":\"wo\",\"LastName\":\"pas\",\"EmailAddress\":\"wopas601856@yubua.com\",\"CellPhone\":1234565432,\"City\":\"Villa Rica\",\"State\":\"GA\",\"ZipCode\":30180,\"Department\":\"ENV\",\"JobTitle\":\"Inspector/Consultant\",\"ManagersFirstName\":\"ceni\",\"ManagersLastName\":\"pi\",\"ManagersEmail\":\"cenipi2424@zfobo.com\",\"InsuranceRate\":3134,\"LicenseandRegistration\":102,\"PersonalPropertyTax\":733,\"Depreciation\":4435,\"AnnualFixedCost\":8404,\"FixedAmount\":500.04,\"FCA\":1,\"TotalFixedAmount\":500.04,\"Meeting\":\"Attended\",\"Packet\":\"Sent\",\"DateAdded\":\"2021-10-19T18:30:00.000Z\",\"ActivationDate\":\"2022-01-31T18:30:00.000Z\",\"MPG\":25.5,\"Maint\":0.0738,\"Tires\":0.0689,\"MaintTires\":0.1427,\"StandardVehicle\":\"2022 Volkswagen Atlas\",\"ComplianceMileage\":5000,\"VehicleURL\":\"https://f.hubspotusercontent40.net/hubfs/2511299/2022-Chevy-Silverado.jpeg\"},{\"Role\":\"Driver\",\"FirstName\":\"yu\",\"LastName\":\"bua\",\"EmailAddress\":\"wopas60185@yubua.com\",\"CellPhone\":1334565432,\"City\":\"Wilmington\",\"State\":\"NC\",\"ZipCode\":28412,\"Department\":\"ENV\",\"JobTitle\":\"Inspector/Consultant\",\"ManagersFirstName\":\"ceni\",\"ManagersLastName\":\"pi\",\"ManagersEmail\":\"cenipi2424@zfobo.com\",\"InsuranceRate\":2122,\"LicenseandRegistration\":177,\"PersonalPropertyTax\":262,\"Depreciation\":3844,\"AnnualFixedCost\":6405,\"FixedAmount\":381.1,\"FCA\":2,\"TotalFixedAmount\":381.1,\"Meeting\":\"Attended\",\"Packet\":\"Sent\",\"DateAdded\":\"2021-06-14T18:30:00.000Z\",\"ActivationDate\":\"2022-05-18T18:30:00.000Z\",\"MPG\":26,\"Maint\":0.0495,\"Tires\":0.0408,\"MaintTires\":0.0903,\"StandardVehicle\":\"2022 Ford F-150\",\"ComplianceMileage\":5000,\"VehicleURL\":\"https://f.hubspotusercontent40.net/hubfs/2511299/2022-Chevy-Silverado.jpeg\"}]'; 
        System.debug('strOriginal==' + strOriginal);
        final Blob dataDocuments ;
        string accId;
        Test.startTest();        
            ImportContactdatafromCSVController i = new ImportContactdatafromCSVController(strOriginal,  acc.Id, adminConList[0].id);
            Database.executeBatch(I);
            dataDocuments = Blob.valueOf('strOriginal');
            accId = acc.Id;
        Test.stopTest();
}
    
 @isTest 
    public static void test2() {
        TriggerConfig__c triggerCustomSetting = TestDataFactory.triggerConfigCustomSetting(true);
        SendEmail__c sendEmailCustomSetting1 = TestDataFactory.sendEmailCustomSetting(true,'Send Email For Compliance');
        TrueDialog_Keys__c tdKeys = TestDataFactory.createTrueDialog(true);
        Vehicle_URL_Mapping__c vehicleObj = TestDataFactory.createVehicleData(true,1);
        IRS_Mileage_Rate__c irsRateObj = TestDataFactory.createIRSRate(true,0);
        
        Account acc = new Account();     
        List<Contact> conList = new List<Contact>();
        List<Contact> adminConList = new List<Contact>();
        
        UserRole userRole = TestDataFactory.getUserRole();
        Profile profileObj = TestDataFactory.getUserProfile();
        User admin = TestDataFactory.getSystemAdminUser(userRole.Id);
        User userObj;
        System.runAs(admin) {
           
            acc = TestDataFactory.createAccount(false,'Test',true);
            acc.True_Dialog__c = true;
            acc.Vehicle_Types__c = vehicleObj.Name;
            Insert acc;
            Contact contactObj = TestDataFactory.createCICDContact(true,acc.Id);
            conList = TestDataFactory.createDriverContact(true, acc.Id, 'Driver', vehicleObj.Name, 'test.email', 1);
            adminConList = TestDataFactory.createDriverContact(true, acc.Id, 'Admin', vehicleObj.Name, 'test1.email', 1);
            userObj = TestDataFactory.createUser(true, profileObj.Id, conList[0].Id);
        }
        
        Attachment attach = TestDataFactory.createAttachment(true, conList[0].id);
        List<Attachment> attachments = [select id, name from Attachment where parent.id =: conList[0].id];
        String strOriginal ='[{\"Role\":\"Driver\",\"FirstName\":\"wo\",\"LastName\":\"pas\",\"EmailAddress\":\"wopas601856@yubua.com\",\"CellPhone\":1234565432,\"City\":\"Villa Rica\",\"State\":\"GA\",\"ZipCode\":30180,\"Department\":\"ENV\",\"JobTitle\":\"Inspector/Consultant\",\"ManagersFirstName\":\"ceni\",\"ManagersLastName\":\"pi\",\"ManagersEmail\":\"cenipi2424@zfobo.com\",\"InsuranceRate\":3134,\"LicenseandRegistration\":102,\"PersonalPropertyTax\":733,\"Depreciation\":4435,\"AnnualFixedCost\":8404,\"FixedAmount\":500.04,\"FCA\":1,\"TotalFixedAmount\":500.04,\"Meeting\":\"Attended\",\"Packet\":\"Sent\",\"DateAdded\":\"2021-10-19T18:30:00.000Z\",\"ActivationDate\":\"2022-01-31T18:30:00.000Z\",\"MPG\":25.5,\"Maint\":0.0738,\"Tires\":0.0689,\"MaintTires\":0.1427,\"StandardVehicle\":\"2022 Volkswagen Atlas\",\"ComplianceMileage\":5000,\"VehicleURL\":\"https://f.hubspotusercontent40.net/hubfs/2511299/2022-Chevy-Silverado.jpeg\"},{\"Role\":\"Driver\",\"FirstName\":\"yu\",\"LastName\":\"bua\",\"EmailAddress\":\"wopas60185@yubua.com\",\"CellPhone\":1334565432,\"City\":\"Wilmington\",\"State\":\"NC\",\"ZipCode\":28412,\"Department\":\"ENV\",\"JobTitle\":\"Inspector/Consultant\",\"ManagersFirstName\":\"ceni\",\"ManagersLastName\":\"pi\",\"ManagersEmail\":\"cenipi2424@zfobo.com\",\"InsuranceRate\":2122,\"LicenseandRegistration\":177,\"PersonalPropertyTax\":262,\"Depreciation\":3844,\"AnnualFixedCost\":6405,\"FixedAmount\":381.1,\"FCA\":2,\"TotalFixedAmount\":381.1,\"Meeting\":\"Attended\",\"Packet\":\"Sent\",\"DateAdded\":\"2021-06-14T18:30:00.000Z\",\"ActivationDate\":\"2022-05-18T18:30:00.000Z\",\"MPG\":26,\"Maint\":0.0495,\"Tires\":0.0408,\"MaintTires\":0.0903,\"StandardVehicle\":\"2022 Ford F-150\",\"ComplianceMileage\":5000,\"VehicleURL\":\"https://f.hubspotusercontent40.net/hubfs/2511299/2022-Chevy-Silverado.jpeg\"}]'; 
        System.debug('strOriginal==' + strOriginal);
        final Blob dataDocuments ;
        string accId;
        Test.startTest();        
            ImportContactdatafromCSVController i = new ImportContactdatafromCSVController(strOriginal,  acc.Id, adminConList[0].id);
            Database.executeBatch(I);
            dataDocuments = Blob.valueOf('strOriginal');
            accId = acc.Id;
        Test.stopTest();
    }
    
}