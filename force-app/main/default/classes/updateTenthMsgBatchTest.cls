@isTest
public class updateTenthMsgBatchTest {

	@testSetup 
    static void setupData(){
        TriggerConfig__c triggerCustomSetting = TestDataFactory.triggerConfigCustomSetting(true);
        SendEmail__c sendEmailCustomSetting = TestDataFactory.sendEmailCustomSetting(true, 'Send Email For Compliance');
        TrueDialog_Keys__c tdKeys = TestDataFactory.createTrueDialog(true);
        IRS_Mileage_Rate__c irsRateObj = TestDataFactory.createIRSRate(true,0);
        List<Address__c> objAddress = TestDataFactory.createAddress(true, 10,12345);
        Vehicle_URL_Mapping__c vehicleType = TestDataFactory.createVehicleData(false, 0);
        vehicleType.Name = String.valueof(System.today().year())+ ' Full-Size Sedan';
        vehicleType.vehicle__c = 'Full-Size Sedan';
        Insert vehicleType;   
        
        UserRole uRole = TestDataFactory.getUserRole();
        Profile profileObj = TestDataFactory.getUserProfile();
        User admin = TestDataFactory.getSystemAdminUser(uRole.Id);
        User userObj;
        
        Account acc;
        List<Contact> conList1;
        List<Contact> conList2;
        List<Contact> conList3;
        List<Contact> conList4;
         
        System.runAs(admin) {
			acc = TestDataFactory.createAccount(true,'TestAccount',true);
            conList1 = TestDataFactory.createDriverContact(true,acc.Id,'Driver/Admin', vehicleType.Name, 'Test', 1);
            conList2 = TestDataFactory.createDriverContact(true,acc.Id,'Admin', vehicleType.Name, 'Test', 1);
            conList3 = TestDataFactory.createDriverContact(true,acc.Id,'Driver/Manager', vehicleType.Name, 'Test', 1);
            conList4 = TestDataFactory.createDriverContact(true,acc.Id,'Manager', vehicleType.Name, 'Test', 1);
		}
        
    }
    
    @isTest
    static void testBatch(){
		Test.startTest();
        List<Contact> lstContact = [SELECT Id FROM Contact WHERE role__c = 'Driver/Admin' LIMIT 1];
        updateTenthMsgBatch job = new updateTenthMsgBatch ( );
       	Database.executeBatch( job );
        System.assertEquals(1, lstContact.size(), 'Assert Error');
        Test.stopTest();
    }
    
}