@isTest
public class ManagerDashboardController_test {
    public static testmethod void ManagerDashboardControllerTestMethod() {
      
        IRS_Mileage_Rate__c irsRateObj = TestDataFactory.createIRSRate(true,0);
        RecordUtilityClass.createRecordsforManagerDashboard(); // inserting the records for ManagerDashboardController class
        Account currentAccount = RecordUtilityClass.getAccount(); // retriving the Accounts 
        Contact currentAdmin = RecordUtilityClass.getManagerContact(); // Retriving the Manager with limit 1
        currentAdmin.FirstName='Test';
        currentAdmin.LastName='lastname';
        update currentAdmin;
        
        List<Employee_Reimbursement__c> empReimbursementList = RecordUtilityClass.getEmployee_Reimbursement(currentAccount.id);
        List<EmployeeReimbursementDetailsAdmin> selectedReimList =new List<EmployeeReimbursementDetailsAdmin>();
        for(Employee_Reimbursement__c obj:empReimbursementList)
        {
            selectedReimList.add(RecordUtilityClass.getEmployeeReimbursementDetails(obj));
        }
        String reimbursement = RecordUtilityClass.getUnapprovedReimbursements(currentAdmin.id,currentAccount.id,false,'Manager');        
        List<EmployeeMileagesForCalculation> employeereimbursementList = new List<EmployeeMileagesForCalculation>();
        employeereimbursementList = (List<EmployeeMileagesForCalculation>)JSON.deserialize(reimbursement,List<EmployeeMileagesForCalculation>.Class);       
        List<String> reimbursementIdList = new List<String>();
        if(empReimbursementList.size() > 0){
        reimbursementIdList.add(empReimbursementList[0].id);
            }
        Test.setCurrentPage(Page.managerdashboard);
        ApexPages.currentPage().getParameters().put('id',currentAdmin.Id);
        ApexPages.currentPage().getParameters().put('accid',currentAccount.Id);                
        
        ManagerDashboardController managerDashboard = new ManagerDashboardController();
        ManagerDashboardController.getRedirected();
        ManagerDashboardController.DeleteMileages(JSON.serialize(reimbursementIdList));
        ManagerDashboardController.getAllDriversLastMonthReimbursements(currentAccount.Id,currentAdmin.Id,true, 'Admin');
        ManagerDashboardController.getVehicleValue(currentAccount.Id);
        ManagerDashboardController.getChartData(currentAdmin.Id,true,currentAccount.Id,'Admin');
        ManagerDashboardController.getAllDriversLastMonthUpdatedReimbursements(currentAdmin.Id, currentAccount.Id,true,'Admin');
        ManagerDashboardController.getAllDriversLastMonthUnapprovedReimbursementsclone(currentAccount.Id,currentAdmin.Id,true,'Admin');
        ManagerDashboardController.getAllDriversLastMonthUpdatedUnapprovedReimburseclone(currentAdmin.Id,currentAccount.Id,false,'Admin');
        ManagerDashboardController.getAllDriversLastMonthUpdatedUnapprovedReimburseClone1(currentAdmin.Id,currentAccount.Id,'false','Admin');
        ManagerDashboardController.getDriverDetails(currentAdmin.Id);
        ManagerDashboardController.totalNoofDriverforManager(currentAdmin.Id);
        ManagerDashboardController.onboardingStatus(currentAdmin.Id, currentAccount.Id,'Admin');
        ManagerDashboardController.onboardingStatus(currentAdmin.Id, currentAccount.Id,'Manager');
        ManagerDashboardController.insuranceReport(currentAdmin.Id, currentAccount.Id,'Admin');
        ManagerDashboardController.insuranceReport(currentAdmin.Id, currentAccount.Id,'Manager');
        ManagerDashboardController.myTeamDetails(currentAdmin.Id,currentAccount.Id,true,'Admin');
        ManagerDashboardController.myTeamDetails(currentAdmin.Id,currentAccount.Id,true,'Manager');
        ManagerDashboardController.highRiskDriversDetails(currentAdmin.Id,currentAccount.Id,true,true,'Admin');   
        ManagerDashboardController.highRiskDriversDetails(currentAdmin.Id,currentAccount.Id,false,false,'Admin');   
        List<Employee_Mileage__c> driverMileagesList =  RecordUtilityClass.getMileagesList();
        Contact selectedDriver =RecordUtilityClass.getDriverContact();
        if(employeereimbursementList.size() > 0)    {
            ManagerDashboardController.getUnapprovedMileages(JSON.serialize(employeereimbursementList[0]),currentAccount.Id);    
        }
        
        updateThresholdWrapper currentupdateThresholdWrapper = new updateThresholdWrapper();
        List<updateThresholdWrapper> updateThresholdWrapperList = new List<updateThresholdWrapper>();
        currentupdateThresholdWrapper.contactid = selectedDriver.id;
        currentupdateThresholdWrapper.threshold = '20';
        updateThresholdWrapperList.add(currentupdateThresholdWrapper);
       
        AsyncApexJob batch = ManagerDashboardController.approveReimbursements(JSON.serialize(reimbursementIdList),currentAdmin.Id,currentAccount.Id,'false',JSON.serialize(updateThresholdWrapperList));
        ManagerDashboardController.getUnapprovedReim(JSON.serialize(reimbursementIdList));
       // ManagerDashboardController.MassSyncTripsForReimbursements(JSON.serialize(reimbursementIdList));
       // ManagerDashboardController.DeleteMileages(JSON.serialize(reimbursementIdList));
        ManagerDashboardController.approveMileagesClone(JSON.serialize(reimbursementIdList),currentAdmin.Id,currentAccount.Id,'true',true);
        ManagerDashboardController.CheckBatchStatus(batch.id);
        ManagerDashboardController.UpdatedReimList(currentAdmin.Id,currentAccount.Id, 'true','Admin');
        ManagerDashboardController.getNotificationMessageList(currentAdmin.Id,2023,'June');
        ManagerDashboardController.managerContactData(string.valueof(currentAdmin.Id),currentAccount.Id,'Admin');
        ManagerDashboardController.managerContactData(string.valueof(currentAdmin.Id),currentAccount.Id,'Manager');
        ManagerDashboardController.accountMonthList(string.valueof(currentAccount.Id));
        ManagerDashboardController.reimbursementForHighMileageOrRisk(currentAdmin.Id,currentAccount.Id,'05-2023',true,true,'Manager');
        ManagerDashboardController.contactReimMonthList(currentAdmin.Id);
        ManagerDashboardController.getLastMonthReimbursements(currentAccount.Id,currentAdmin.Id,true,'05-2023','Admin');
        ManagerDashboardController.setEmployeeName();
        ManagerDashboardController.onboardRptDownloadtData(currentAdmin.id,currentAccount.id,'Manager');
    }
    public static testmethod void ManagerDashboardControllerTestMethod1() {
      
        IRS_Mileage_Rate__c irsRateObj = TestDataFactory.createIRSRate(true,0);
        RecordUtilityClass.createRecordsforManagerDashboard(); // inserting the records for ManagerDashboardController class
        Account currentAccount = RecordUtilityClass.getAccount(); // retriving the Accounts 
        Contact currentAdmin = RecordUtilityClass.getManagerContact(); // Retriving the Manager with limit 1
        currentAdmin.FirstName='Test';
        currentAdmin.LastName='lastname';

        update currentAdmin;
        List<Employee_Reimbursement__c> empReimbursementList = RecordUtilityClass.getEmployee_Reimbursement(currentAccount.id);
        List<Contact> con1List;
        Vehicle_URL_Mapping__c vehicleType = TestDataFactory.createVehicleData(false, 3);
        vehicleType.Name = '2020 Full-Size Sedan';
        vehicleType.vehicle__c = 'Full-Size Sedan';
        Insert vehicleType;
        List<EmployeeReimbursementDetailsAdmin> selectedReimList =new List<EmployeeReimbursementDetailsAdmin>();
        for(Employee_Reimbursement__c obj:empReimbursementList)
        {
            selectedReimList.add(RecordUtilityClass.getEmployeeReimbursementDetails(obj));
        }
        String reimbursement = RecordUtilityClass.getUnapprovedReimbursements(currentAdmin.id,currentAccount.id,false,'Manager');  
        con1List = TestDataFactory.createDriverContact(true, currentAccount.Id, 'Manager', vehicleType.Name, 'paras.patel',  1);
        list<Employee_Reimbursement__c>reim = TestDataFactory.createPendingReimbursement(true,con1List,1,irsRateObj.id);      
        List<EmployeeMileagesForCalculation> employeereimbursementList = new List<EmployeeMileagesForCalculation>();
        employeereimbursementList = (List<EmployeeMileagesForCalculation>)JSON.deserialize(reimbursement,List<EmployeeMileagesForCalculation>.Class);       
        List<String> reimbursementIdList = new List<String>();
        if(empReimbursementList.size() > 0){
        reimbursementIdList.add(empReimbursementList[0].id);
            }
        Test.setCurrentPage(Page.managerdashboard);
        ApexPages.currentPage().getParameters().put('id',currentAdmin.Id);
        ApexPages.currentPage().getParameters().put('accid',currentAccount.Id);                
        ManagerDashboardController.TripCallout(con1List[0].id,'January','2024','5.00','50',reim[0].id,'50','Not Approved Yet');
        
        ManagerDashboardController.loginRedirection(currentAdmin.Id);
        ManagerDashboardController.complRptDownloadtData(con1List[0].id,currentAccount.id,'Manager');
        
    }
}