//c
public without sharing class ContactTriggerHelper {
    public static Boolean isRecursive = false;
    public static Boolean isFirstTime = true;
    Public static date fuelPriceDate;
    Public static string[] splitdate;
    Public static map<string, Decimal> monthStateCityVsFuelPriceMap = new map<string, Decimal>();
    Public static map<string, Decimal> monthStateCityVsFuelPricereimMap = new map<string, Decimal>();
    public static void checkVehicalYearAndModel(List<Contact> contactList){
        System.debug('inside checkVehicalYearAndModel');
        Map<String,String> urlMap = new Map<String,String>();
        set<String> vehicleNamesset = new set<String>();
        for(Contact conRec : contactList) {
            if(conRec.Vehicle_Type__c!=null) {
                vehicleNamesset.add(conRec.Vehicle_Type__c.replace(' ','').toUpperCase());
            }
        }
        for(Vehicle_URL_Mapping__c u : [SELECT Id, Year__c, Vehicle__c, URL__c,Vehicle_Mapping__c FROM Vehicle_URL_Mapping__c WHERE Vehicle_Mapping__c IN: vehicleNamesset]){
            if((u.URL__c != null || u.URL__c != '') &&(!urlMap.containsKey(u.Vehicle_Mapping__c))){
                urlMap.put(u.Vehicle_Mapping__c,u.URL__c);
            }
        }
        for(Contact conRec : contactList) {
            if(conRec.Role__c == StaticValues.ROLE_DRIVER || conRec.Role__c == StaticValues.ROLE_DRIVERMANAGER || conRec.Role__c == StaticValues.roleAdminDriver ) {
                if(conRec.Vehicle_Type__c != '') {
                    if(urlMap.containsKey(conRec.Vehicle_Type__c.replace(' ','').toUpperCase())) {
                        conRec.Car_Image__c = urlMap.get(conRec.Vehicle_Type__c.replace(' ','').toUpperCase());
                    } else {
                        conRec.addError('Please Enter Valid Standard Vehicle Make Model and Year');
                    }
                }
            }
        }
    }
    @Future(callout = true)
    public static void putHTTPUpdateUserPhoneTriplog(Map<String,String> tripIdWisePhone,Map<String,String> triplogidwiseAPIkey) {
        System.debug('inside putHTTPUpdateUserPhoneTriplog');
        Http h;
        HttpRequest req;
        HttpResponse res;
        String mLOGACCOUNT = System.Label.Triplog_New_URL + ',' + System.Label.Triplog_New_URL2;
        for(String currentUserId : triplogidwiseAPIkey.keySet()) {
            String baseURL = !mLOGACCOUNT.Contains( triplogidwiseAPIkey.get(currentUserId) ) ? StaticValues.TRIPLOG_BASEURL : StaticValues.MLOG_BASEURL;
            if(tripIdWisePhone.containsKey(currentUserId) && tripIdWisePhone.get(currentUserId) != null) {
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('phone',tripIdWisePhone.get(currentUserId));
                gen.writeEndObject();
                h = new Http();
                req = new HttpRequest();
                req.setEndpoint( baseURL + '/api/users/' + currentUserId);
                req.setMethod('PUT');
                req.setTimeout(120000);
                req.setbody(gen.getAsString());
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Authorization', 'apikey '+ triplogidwiseAPIkey.get(currentUserId));
                if(!Test.isRunningTest()) {
                    res = h.send(req);
                }
            }
        }
    }
    public static void  CommunityUserCreate(List<Contact> contactList) {
        System.debug('inside CommunityUserCreate');
        List<User> createUserList = new List<User>();
        list<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Customer Community Login User - Driver' OR  Name = 'Customer Community Login User - Manager' OR  Name = 'Customer Community Login User - Super Manager' OR  Name = 'Customer Community Login User - Manager/Driver' OR  Name = 'Customer Community Login User - Super Manager/Driver'];
        Map<string,Id> profilemap = new Map<string,ID>();
        for(Profile profileObj : profileList){
            if(profileObj.Name == 'Customer Community Login User - Driver' ){
                profilemap.put('Driver',profileObj.id);
            } else if(profileObj.Name == 'Customer Community Login User - Manager'){
                profilemap.put('Manager',profileObj.id);
            } else if(profileObj.Name == 'Customer Community Login User - Manager/Driver'){
                profilemap.put('Driver/Manager',profileObj.id);
            } else if(profileObj.Name == 'Customer Community Login User - Super Manager/Driver'){
                profilemap.put(StaticValues.roleAdminDriver ,profileObj.id);
            }  else if(profileObj.Name == 'Customer Community Login User - Super Manager'){
                profilemap.put('Admin',profileObj.id);
            }
        }
        for(Contact conObj : contactList) {
            if(conObj.IsCreatedFROMCommunity__c == true && profilemap.containskey(conObj.Role__c))  {
                createUserList.add(CreateUserFROMCommunity(conObj,profilemap.get(conObj.Role__c)));
            }
        }
        if(createUserList.size()>0) {
            insert createUserList;
        }
    }
    public static User CreateUserFROMCommunity(Contact contObj, Id profileId){
        System.debug('inside CreateUserFROMCommunity');
        User userObj = new User();
        userObj.FirstName = contObj.FirstName;
        userObj.LastName = contObj.LastName;
        userObj.Email = contObj.External_Email__c;
        userObj.EmailEncodingKey = 'UTF-8';
        userObj.LanguageLocaleKey = 'en_US';
        userObj.LocaleSidKey = 'en_US';
        userObj.TimeZoneSidKey = 'America/Los_Angeles';
        userObj.UserName = contObj.External_Email__c;
        userObj.Profileid = profileId;
        userObj.Alias = contObj.External_Email__c.left(8);
        userObj.ContactId = contObj.id;
        return userObj;
    }
    //alwasys use htmlvalue to get the html body of the email template below is the code depicting that
    public static void updateComplianceStatus(List<Contact> newCon, Map<ID, Contact> conOldMap) {
        System.debug('inside updateComplianceStatus');
        List<String> lstEmail = new List<String>();
        Messaging.SingleEmailMessage objEmailMessage;
        List<Messaging.SingleEmailMessage> lstEmailMessage = new List<Messaging.SingleEmailMessage>();
        // Define Email Template
        Map<String,EmailTemplate> mapEmailTemplateByName = new Map<String,EmailTemplate>();
        Map<String,Account> mapAccountById =new Map<String,Account>();
        Map<String, String> mapCSETByStatus = new Map<String, String>();
        Set<String> setContactRoles = new Set<String>{'Driver', 'Driver/Manager', 'Driver/Admin'};
            Set<Id> setAccountId = new Set<Id>();
        List<Compliance_Status_Email_Template__mdt> lstComplianceStatusEmailTemp = [SELECT MasterLabel,Email_Template__c FROM Compliance_Status_Email_Template__mdt where IsActive__c= true ];
        for(Compliance_Status_Email_Template__mdt objComplianceStatusEmailTemp: lstComplianceStatusEmailTemp)
        {
            mapCSETByStatus.put(objComplianceStatusEmailTemp.MasterLabel,objComplianceStatusEmailTemp.Email_Template__c);
        }
        //System.debug('mapCSETByStatus@--'+mapCSETByStatus.values());
        //please insert the compliance related template in the folder named ='Driver compliance Status email templates'
        for(EmailTemplate objEmailTemplate : [SELECT Id, Name, developerName, Subject, body,HtmlValue FROM EmailTemplate where developerName In :mapCSETByStatus.values()]) {
            mapEmailTemplateByName.put(objEmailTemplate.developerName, objEmailTemplate);
        }
        //System.debug('objEmailTemplate@--'+mapEmailTemplateByName.values());
        for(Contact objContact : newCon) {
            setAccountId.add(objContact.AccountId);
        }
        for(Account objAccount:[select id,name,Collision__c,Bodily_Injury__c,Comprehensive__c,Property_Damage__c,Uninsured_Motorist__c from Account where isUsingTriplog__c = true  and Id In :setAccountId order by name asc]){
            mapAccountById.put(objAccount.id,objAccount);
        }
        // System.debug('name template map   --> '+mapEmailTemplateByName);
        String objDriverServiceAdd = Label.Driver_Service_OWE;
        OrgWideEmailAddress[] lstOWE = [SELECT Id, address FROM OrgWideEmailAddress WHERE Address = :objDriverServiceAdd];
        for(Contact objContact : newCon) {
            EmailTemplate objEmailTemp;
            if(setContactRoles.contains(objContact.Role__c) && (conOldMap.get(objContact.id).monthly_compliance_status__c != objContact.monthly_compliance_status__c)) {
                lstEmail.clear();
                lstEmail.add(objContact.Email);
                if(mapCSETByStatus.containsKey(objContact.monthly_compliance_status__c) && mapEmailTemplateByName.containsKey(mapCSETByStatus.get(objContact.monthly_compliance_status__c)))
                {
                    objEmailTemp = mapEmailTemplateByName.get(mapCSETByStatus.get(objContact.monthly_compliance_status__c));
                }
                if(!lstEmail.isEmpty() && objEmailTemp != null) {
                    objEmailMessage = new Messaging.SingleEmailMessage();
                    objEmailMessage.setToAddresses(new List<String>{objContact.External_Email__c});
                    objEmailMessage.setSubject(objEmailTemp.Subject);
                    String newBody = objEmailTemp.HtmlValue;
                    if(objContact.FirstName!=null){
                        newBody = newBody.replace('{!Contact.FirstName}', objContact.FirstName);
                    }
                    if(objContact.Expiration_Date__c!=null){
                        newBody = newBody.replace('{!Contact.Expiration_Date__c}', String.valueOf(objContact.Expiration_Date__c.format()));
                    }else {
                        newBody = newBody.replace('{!Contact.Expiration_Date__c}', '');
                    }
                    List<String> args = new String[]{'0','number','###,###,###.##'};
                        String comprehensive = String.format(mapAccountById.get(objContact.AccountId).Comprehensive__c.format(), args);
                    String propertyDamage = String.format(mapAccountById.get(objContact.AccountId).Property_Damage__c.format(), args);
                    String collision = String.format(mapAccountById.get(objContact.AccountId).Collision__c.format(), args);
                    newBody = newBody.replace('{!Account.Bodily_Injury__c}', String.valueOf(mapAccountById.get(objContact.AccountId).Bodily_Injury__c));
                    newBody = newBody.replace('{!Account.Comprehensive__c}', comprehensive);
                    newBody = newBody.replace('{!Account.Property_Damage__c}', propertyDamage);
                    newBody = newBody.replace('{!Account.Collision__c}', collision);
                    newBody = newBody.replace('{!Account.Uninsured_Motorist__c}', String.valueOf(mapAccountById.get(objContact.AccountId).Uninsured_Motorist__c));
                    objEmailMessage.setHTMLBody(newBody);
                    if(lstOWE.size()>0) {
                        objEmailMessage.setOrgWideEmailAddressId(lstOWE.get(0).Id);
                    }
                    objEmailMessage.setUseSignature(false);
                    String bccEmail = Label.DeveloperBCCToEmail;
                    if (!String.isEmpty(bccEmail)) {
                        objEmailMessage.setBccAddresses(bccEmail.split(','));
                    }
                    lstEmailMessage.add(objEmailMessage);
                    //System.debug('lstEmailMessage@@--'+lstEmailMessage);
                }
            }
        }
        System.debug('lstEmailMessage@@--'+lstEmailMessage.size());
        //Sending the Email
        if(!lstEmailMessage.isEmpty()){
            SendEmail__c  objSendEmail = SendEmail__c.getValues('Send Email For Compliance');
            if(objSendEmail.Send_email_FROM_code__c==true) {
                //System.debug('Sending email'+lstEmailMessage);
                Messaging.sendEmail(lstEmailMessage);
            }
        }
    }
    //This method is get trigger when Monthly compliance status get changes then driver, driver/manager, driver/admin, will get message notification on dashboard
    public static void updateMessageNotification(List<Contact> newCon, Map<ID, Contact> conOldMap) {
        System.debug('inside updateMessageNotification');
        List<Message__c> lstMessagesToCreate = new List<Message__c>();
        Map<String, Compliance_Status_Message__mdt> mapCSMByStatus = new Map<String, Compliance_Status_Message__mdt>();
        Set<String> setContactRoles = new Set<String>{'Driver', 'Driver/Manager', 'Driver/Admin'};
            List<Compliance_Status_Message__mdt> lstComplianceStatusMessage = [SELECT MasterLabel,Notification_Message__c FROM Compliance_Status_Message__mdt where IsActive__c= true ];
        for(Compliance_Status_Message__mdt objComplianceStatusMessage: lstComplianceStatusMessage)
        {
            mapCSMByStatus.put(objComplianceStatusMessage.MasterLabel,objComplianceStatusMessage);
        }
        for(Contact objContact : newCon) {
            if(setContactRoles.contains(objContact.Role__c) && (conOldMap.get(objContact.id).monthly_compliance_status__c != objContact.monthly_compliance_status__c)) {
                if(mapCSMByStatus.containsKey(objContact.monthly_compliance_status__c))
                {
                    Compliance_Status_Message__mdt  objComplianceStatusMessage = mapCSMByStatus.get(objContact.monthly_compliance_status__c);
                    if (objComplianceStatusMessage.Notification_Message__c.contains('#&#ExpirationDate#&#') && objContact.Expiration_Date__c !=null) {
                        objComplianceStatusMessage.Notification_Message__c = objComplianceStatusMessage.Notification_Message__c.replace('#&#ExpirationDate#&#', objContact.Expiration_Date__c.format());
                    }
                    else if (objComplianceStatusMessage.Notification_Message__c.contains('#&#ExpirationDate#&#') && objContact.Expiration_Date__c ==null) {
                        objContact.Expiration_Date__c.addError('Expiration Date is required.');
                    }
                    // Create a new Message__c record related to the Contact
                    Message__c newMessage = new Message__c(
                        Contacts__c = objContact.Id,
                        Unread__c = true,
                        Notification_Message__c = objComplianceStatusMessage.Notification_Message__c
                    );
                    lstMessagesToCreate.add(newMessage);
                }
            }
        }
        if (!lstMessagesToCreate.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(lstMessagesToCreate, false);
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted Message. Messages ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Message fields that affected this error: ' + err.getFields());
                    }
                }
            }
        } else {
            System.debug('No message records to create.');
        }
    }
    //This method is used when deactivate date is removed and create a new reimbursement for that driver.
    public static void createReimRecord(List<Contact> newCon, Map<ID, Contact> conOldMap) {
        System.debug('inside createReimRecord');
        List<Employee_Reimbursement__c> reimToInsert   = new List<Employee_Reimbursement__c>();
        List<Bi_Weekly_Reimbursement__c> bireimToInsert   = new List<Bi_Weekly_Reimbursement__c>();
        map<string, Decimal> gasPriceMap = GetGasPrice();
        List<IRS_Mileage_Rate__c> objIRSRate = [SELECT id,year__c,IRS_Rate__c FROM IRS_Mileage_Rate__c WHERE year__c =: String.valueOf(System.today().year()) Limit 1];
        String IRSRateId;
        if(!objIRSRate.isEmpty()){
            IRSRateId= objIRSRate[0].id;
        }
        Boolean monthlyReimValue;
        for(Contact con : newCon) {
            if (con.Monthly_Reimbursement__c == true) {
                monthlyReimValue = true;
            }
            else{
                monthlyReimValue = false;
            }
            if(conOldMap.get(con.id).Deactivated_Date__c != null && con.Deactivated_Date__c == null && (conOldMap.get(con.id).Deactivated_Date__c != con.Deactivated_Date__c) && con.Activation_Date__c <= System.today() && conOldMap.get(con.id).Deactivated_Date__c.month() != System.today().month() && conOldMap.get(con.id).Deactivated_Date__c.year() != System.today().year()){
                if(con.Role__c != 'Admin' && con.Role__c != 'Manager') {
                    TriggerConfig__c customSetting = TriggerConfig__c.getInstance('Defaulttrigger');
                    if(customSetting.ContactTriCommunityReimCreate__c == true && IRSRateId!=null) {
                        reimToInsert.add(CreateReimbursement(con,gasPriceMap,IRSRateId));
                        if(customSetting.ContactTriBiReimCreate__c == true) {
                            bireimToInsert.add(CreateBiweekReimbursement(con,gasPriceMap,monthlyReimValue));
                        }
                    }
                }
            }
            if(!reimToInsert.isEmpty()){
                try{
                    upsert reimToInsert;
                    if(!bireimToInsert.isEmpty()){
                        upsert bireimToInsert;
                    }
                } catch (DMLException e) {
                    system.debug('DMLException='+e);
                }
                ContactTriggerHelper.putHTTPEnableUserTriplog(con.id,false);
                RosterController.resetPassword(con.id);
                putHTTP(con.AccountId,con.External_Email__c);
            }
        }
    }
    public static map<string, Decimal> GetGasPrice(){
        System.debug('inside GetGasPrice');
        map<string, Decimal> fuelPricereimMap = new map<string, Decimal>();
        String currentDate = String.valueOf(system.today());
        String[] splitDate = currentDate.split('-');
        if(integer.valueOf(splitDate[1]) == 01){
            fuelPriceDate = date.valueOf(string.valueOf(integer.valueOf(splitDate[0])-1) + '-12' + '-01' );
        } else {
            fuelPriceDate = date.valueOf(splitDate[0] + '-' + string.valueOf(integer.valueOf(splitDate[1])-1) + '-01');
        }
        for(Gas_Prices__c objGasPrice : [SELECT id,
                                         name,
                                         City__c,
                                         State__c,
                                         Fuel_Price__c,
                                         Month_Year__c,
                                         Month_State_City__c
                                         FROM Gas_Prices__c
                                         WHERE  Month_Year__c =: date.valueOf(fuelPriceDate)
                                        ]) {
                                            fuelPricereimMap.put(objGasPrice.Month_State_City__c, objGasPrice.Fuel_Price__c);
                                        }
        return fuelPricereimMap;
    }
    public static Employee_Reimbursement__c CreateReimbursement(Contact con, map<string, Decimal> monthFuelPricereimMap,String IRSRateId){
        System.debug('inside CreateReimbursement');
        //EMC-283 Update Fuel Price based on the contact city and state as past month's fuel price FROM Gas price object.
        String currentDate = String.valueOf(system.today());
        String[] splitDate = currentDate.split('-');
        String lastMonth = Utils.fetchMonths(1, -1)[0];
        Employee_Reimbursement__c er = new Employee_Reimbursement__c();
        er.Fixed_Amount__c = con.Fixed_Amount__c;
        er.Status__c = 'Pending';
        er.Maintenance_and_Tires__c = con.Maintenance_and_Tires__c;
        er.MPG__c = con.MPG__c;
        er.Contact_Id__c = con.id;
        er.Name = con.Name__c + ':' + lastMonth;
        er.Month__c = lastMonth;
        if(integer.valueOf(splitDate[1]) == 01){
            if (monthFuelPricereimMap.containsKey(con.MailingCity+ con.MailingState + '12' + string.valueOf(integer.valueOf(splitDate[0])-1)) ) {
                er.Fuel_Price__c = monthFuelPricereimMap.get(con.MailingCity+ con.MailingState + '12' + string.valueOf(integer.valueOf(splitDate[0])-1)) ;
            }   else {
                er.Fuel_Price__c = 0;
            }
        }   else {
            if (monthFuelPricereimMap.containsKey(con.MailingCity + con.MailingState + string.valueOf(integer.valueOf(splitDate[1])-1) + splitDate[0]) ) {
                er.Fuel_Price__c = monthFuelPricereimMap.get(con.MailingCity + con.MailingState + string.valueOf(integer.valueOf(splitDate[1])-1) + splitDate[0]);
            }   else {
                er.Fuel_Price__c = 0;
            }
        }
        er.IRS_Mileage_Rate__c = IRSRateId;
        return er;
    }
    public static void  communityReimCreate(List<Contact> contactList) {
        System.debug('inside communityReimCreate');
        List<Employee_Reimbursement__c> reimToInsert   = new List<Employee_Reimbursement__c>();
        List<Bi_Weekly_Reimbursement__c> bireimToInsert   = new List<Bi_Weekly_Reimbursement__c>();
        List<IRS_Mileage_Rate__c> objIRSRate = [SELECT id,year__c,IRS_Rate__c FROM IRS_Mileage_Rate__c WHERE year__c =: String.valueOf(System.today().year()) Limit 1];
        String IRSRateId;
        if(!objIRSRate.isEmpty()){
            IRSRateId= objIRSRate[0].id;
        }
        map<string, Decimal> gasPriceMap = GetGasPrice();
        Boolean monthlyReimValue;
        TriggerConfig__c customSetting = TriggerConfig__c.getInstance('Defaulttrigger');
        for(Contact con : contactList){
            if (con.Monthly_Reimbursement__c == true) {
                monthlyReimValue = true;
            }
            else{
                monthlyReimValue = false;
            }
            if(!System.isBatch()){
                putHTTP(con.AccountId,con.External_Email__c);
            }
            if(con.Role__c != 'Admin' && con.Role__c != 'Manager' && con.Deactivated_Date__c == null) {
                if(con != null && customSetting.ContactTriCommunityReimCreate__c == true && IRSRateId!=null ) {
                    reimToInsert.add(CreateReimbursement(con,gasPriceMap,IRSRateId));
                    if(customSetting.ContactTriBiReimCreate__c == true ) {
                        bireimToInsert.add(CreateBiweekReimbursement(con,gasPriceMap,monthlyReimValue));
                    }
                }
            }
        }
        if(!reimToInsert.isEmpty()) {
            insert reimToInsert;
        }
        if(!bireimToInsert.isEmpty()){
            insert bireimToInsert;
        }
    }
    /* public static map<string, Decimal> CreateBiweekReimbursementForMap(){
map<string, Decimal> monthlyFuelPriceMap = new map<string, Decimal>();
List<String> dtList = new list<String>();
string splitEndDate;
splitdate = dtList[1].split('-');
splitEndDate = splitdate[1]+'/'+splitdate[2]+'/'+splitdate[0];
if(integer.valueOf(splitdate[1]) == 01){
fuelPriceDate = date.valueOf(string.valueOf(integer.valueOf(splitdate[0])-1) + '-12' + '-01' );
} else {
fuelPriceDate = date.valueOf(splitdate[0] + '-' + string.valueOf(integer.valueOf(splitdate[1])-1) + '-01');
}
for(Gas_Prices__c objGasPrice : [SELECT id,
name,
City__c,
State__c,
Fuel_Price__c,
Month_Year__c,
Month_State_City__c
FROM Gas_Prices__c
WHERE  Month_Year__c =: date.valueOf(fuelPriceDate)]) {
monthlyFuelPriceMap.put(objGasPrice.Month_State_City__c, objGasPrice.Fuel_Price__c);
}
return monthlyFuelPriceMap;
}*/
    //This method is used to create a Bi-Weekly reimbursment
    public static Bi_Weekly_Reimbursement__c CreateBiweekReimbursement(Contact con, map<string, Decimal> monthlyFuelPriceMap, Boolean monthlyReimbursecheckValue){
        System.debug('inside CreateBiweekReimbursement');
        contact contest = [select id,account.Pay_Period_Days__c,account.Pay_Period_Start_Date__c FROM contact WHERE id =: con.id];
        List<String> dtList = new list<String>();
        Date payStartDate = contest.Account.Pay_Period_Start_Date__c;
        Date endDate;
        do {
            endDate = payStartdate.addDays(Integer.valueof(contest.Account.Pay_Period_Days__c));
            if(payStartdate != null && payStartdate <= System.today() && System.today() <= endDate) {
                dtList.add(String.valueof(payStartdate));
                dtList.add(String.valueof(endDate));
            }
            payStartdate = endDate.addDays(1);
        } while(endDate <= System.today());
        string splitStartDate;
        string splitEndDate;
        if(dtList.size() > 0){
            string[] splitsdate = dtList[0].split('-');
            splitStartDate = splitsdate[1]+'/'+splitsdate[2]+'/'+splitsdate[0];
            splitdate = dtList[1].split('-');
            splitEndDate = splitdate[1]+'/'+splitdate[2]+'/'+splitdate[0];
            //EMC -283 use to update fuel price of biweekly reim based on the contact city and state of past month's fuel price FROM gas price object
        }
        Bi_Weekly_Reimbursement__c er = new Bi_Weekly_Reimbursement__c();
        er.Fixed_Amount__c = con.Fixed_Amount__c;
        er.Status__c = 'Pending';
        er.Maintenance_and_Tires__c = con.Maintenance_and_Tires__c;
        er.MPG__c = con.MPG__c;
        er.Contact__c = con.id;
        er.Name = splitStartDate+' to '+ splitEndDate;
        er.Count_Error_Check__c = 0;
        if(monthlyReimbursecheckValue != true){
            if(integer.valueOf(splitdate[1]) == 01){
                if (monthlyFuelPriceMap.containsKey(con.MailingCity+ con.MailingState + '12' + string.valueOf(integer.valueOf(splitdate[0])-1)) ) {
                    er.Fuel_Price__c = monthlyFuelPriceMap.get(con.MailingCity+ con.MailingState + '12' + string.valueOf(integer.valueOf(splitdate[0])-1)) ;
                }   else {
                    er.Fuel_Price__c = 0;
                }
            }   else {
                if (monthlyFuelPriceMap.containsKey(con.MailingCity+ con.MailingState + string.valueOf(integer.valueOf(splitdate[1])-1) + splitdate[0]) ) {
                    er.Fuel_Price__c = monthlyFuelPriceMap.get(con.MailingCity+ con.MailingState + string.valueOf(integer.valueOf(splitdate[1])-1) + splitdate[0]);
                }   else {
                    er.Fuel_Price__c = 0;
                }
            }
        } else{
            er.Fuel_Price__c = 0;
        }
        er.Start_Date__c = Date.valueOf(dtList[0]);
        er.End_Date__c = Date.valueOf(dtList[1]);
        return er;
    }
    //This method is used send a welcome email FROM triplog or mlog to install a application.
    @future (callout=true)
    Public static void putHTTP(String accountID,String empEmail) {
        putHTTPCallout(AccountId, empEmail);
    }
    Public static void putHTTPCallout(String accountID,String empEmail) {
        System.debug('inside putHTTPCallout');
        List<Account> accountList = [SELECT id,Triplog_API__c,MburseDashboardRedirect__c
                                     FROM Account
                                     WHERE Id =: accountID];
        if(accountList.size() > 0 && accountList[0].MburseDashboardRedirect__c == false){
            String MLOGACCOUNT = System.Label.Triplog_New_URL  + ',' + System.Label.Triplog_New_URL2;
            String body, apiToken;
            if(accountList.size() > 0 ){
                apiToken = accountList[0].Triplog_API__c;
            }
            String jsonSubset;
            String baseURL;
            if(apiToken != null){
                baseURL = !mLOGACCOUNT.Contains(apiToken) ? StaticValues.TRIPLOG_BASEURL : StaticValues.MLOG_BASEURL;
            }
            String rosterURL = baseURL + StaticValues.WELCOME_SUFFIX;
            body = '{"emails":[';
            body = body + String.valueof(empEmail) +']}';
            TriplogPutCall__c objTriplog = TriplogPutCall__c.getValues('RosterControllerPutCall');
            HttpRequest putReq = new HttpRequest();
            Http putHTTP = new Http();
            HttpResponse putRes = new HttpResponse();
            putReq.setEndpoint(rosterURL);
            putReq.setMethod('PUT');
            putReq.setBody(body);
            putReq.setTimeout(120000);
            putReq.setHeader('Authorization', 'apikey ' + apiToken);
            putReq.setHeader('Content-Type', 'application/json');
            if(!Test.isRunningTest() && objTriplog.TriplogPut__c == true){
                if(objTriplog.TriplogPut__c == true){
                    putRes = putHTTP.send(putReq);
                    Map<String,Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(putRes.getBody());
                    jsonSubset = JSON.serialize(jsonMap.get('message'));
                }
            }
        }
    }
    /**
* @Date: 11-01-2023 | Niraj Sahedani
* @description: This Method is used to Deacivate user in mLog if user change their role in salesforce
*/
    @InvocableMethod(label='Get Role Change Value' description='Returns the list of Role Change Contacts' category='Contact')
    public static void roleChange(List<String> ids){
        ContactTriggerHelper.putHTTPEnableUserTriplog(ids[0],true);
    }
    @Future(callout = true)
    public static void putHTTPEnableUserTriplog(String conId, Boolean userStatus) {
        System.debug('inside putHTTPEnableUserTriplog');
        Http h;
        HttpRequest req;
        HttpResponse res;
        String mLOGACCOUNT = System.Label.Triplog_New_URL + ',' + System.Label.Triplog_New_URL2;
        for(Contact conObj : [SELECT id,Triplog_UserID__c,Email, Account.Triplog_API__c  FROM Contact WHERE id =: conId]) {
            if(conObj.Triplog_UserID__c != null && conObj.Account.Triplog_API__c != null){
                String baseURL = !mLOGACCOUNT.Contains( conObj.Account.Triplog_API__c ) ? StaticValues.TRIPLOG_BASEURL : StaticValues.MLOG_BASEURL;
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeBooleanField('disabled',userStatus);
                gen.writeStringField('email',conObj.Email);
                gen.writeEndObject();
                h = new Http();
                req = new HttpRequest();
                req.setEndpoint( baseURL + '/api/users/' + conObj.Triplog_UserID__c);
                req.setMethod('PUT');
                req.setTimeout(120000);
                req.setbody(gen.getAsString());
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Authorization', 'apikey '+ conObj.Account.Triplog_API__c);
                if(!Test.isRunningTest())
                {
                    res = h.send(req);
                }
            }
        }
    }
    //Send Email regarding New Drivers AI-000437
    public static void sendEmailForNewContact(List<Contact> contactList) {
        System.debug('inside sendEmailForNewContact');
        Map<Id,String> accountNameMap = new Map<Id,String>();
        for(Account objAccount : [SELECT ID,Name FROM account WHERE isUsingTriplog__c = true]){
            accountNameMap.put(objAccount.id,objAccount.Name);
        }
        EmailTemplate templateId = [SELECT Id, Subject,HtmlValue, body FROM EmailTemplate WHERE developerName = 'New_Contact_Inform_Driver_Services' Limit 1];
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress[] owea = [SELECT Id,Address FROM OrgWideEmailAddress WHERE Address = 'driverservices@mburse.com'];
        for(Contact contObj : contactList){
            String newemailBody = templateId.HtmlValue;
            Messaging.SingleEmailMessage mail =  new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(contObj.OwnerId);
            string[] toAddresses = new string[]{System.Label.DriverServicesEmail};
                mail.setToAddresses(toAddresses);
            mail.setReplyTo('mburse@driverservices.com');
            if(accountNameMap.get(contObj.AccountId) != null){
                newemailBody = newemailBody.replace('{!Account.Name}',accountNameMap.get(contObj.AccountId));
            }
            IF(contObj.Role__c != null){
                newemailBody = newemailBody.replace('{!Role}',contObj.Role__c );
            }
            newemailBody = newemailBody.replace('{!date}',String.valueOf(System.today()));
            newemailBody = newemailBody.replace('{!Email}',contObj.External_Email__c);
            newemailBody = newemailBody.replace('{!$Label.Driver_Forword_Logo}', System.Label.Driver_Forword_Logo);
            mail.setSubject(templateId.Subject);
            mail.setHtmlBody(newemailBody);
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
            mail.setSaveAsActivity(false);
            mails.add(mail);
        }
        if(!Test.isRunningTest()){
            Messaging.sendEmail(mails);
        }
    }
    //Track History of Contact
    public static void TrackHistory(Map<ID,Contact> conOld,List<Contact> contactListNew,Map<String,String> managerNames){
        //Map for Manager Name
        System.debug('inside TrackHistory');
        //Audit Trial
        list<AuditTrail__c> newAuditTrialCreate=new list<AuditTrail__c>();
        for(Contact c:contactListNew){
            if(c.id == conOld.get(c.id).id){
                if(c.Fixed_Amount__c != conOld.get(c.id).Fixed_Amount__c)
                    newAuditTrialCreate.add(new AuditTrail__c(Field__c = 'Fixed Amount',Timestamp__c = Datetime.now(),Modifiedby__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c = string.valueof(c.Fixed_Amount__c),OldValue__c = String.Valueof(conOld.get(c.id).Fixed_Amount__c),Contact__c=c.id));
                if(c.Maintenance_and_Tires__c != conOld.get(c.id).Maintenance_and_Tires__c)
                    newAuditTrialCreate.add(new AuditTrail__c(Field__c = 'Maintenance and Tires',Timestamp__c=Datetime.now(),Modifiedby__c=UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c=String.valueof(c.Maintenance_and_Tires__c),OldValue__c=string.valueof(conOld.get(c.id).Maintenance_and_Tires__c),Contact__c=c.id));
                if(c.Vehicle1Odometer__c != conOld.get(c.id).Vehicle1Odometer__c)
                    newAuditTrialCreate.add(new AuditTrail__c(Field__c = 'Vehicle 1 Odometer',Timestamp__c = Datetime.now(),Modifiedby__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c = String.Valueof(c.Vehicle1Odometer__c),OldValue__c = String.Valueof(conOld.get(c.id).Vehicle1Odometer__c),Contact__c = c.id));
                if(c.Vehicle2Odometer__c != conOld.get(c.id).Vehicle2Odometer__c)
                    newAuditTrialCreate.add(new AuditTrail__c(Field__c = 'Vehicle 2 Odometer',Timestamp__c = Datetime.now(),Modifiedby__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c = String.Valueof(c.Vehicle2Odometer__c),OldValue__c = String.Valueof(conOld.get(c.id).Vehicle2Odometer__c),Contact__c = c.id));
                if(c.MailingStreet != conOld.get(c.id).MailingStreet || c.MailingCity != conOld.get(c.id).MailingCity || c.MailingState != conOld.get(c.id).MailingState || c.MailingPostalCode != conOld.get(c.id).MailingPostalCode || c.MailingCountry != conOld.get(c.id).MailingCountry ){
                    string newval = (c.MailingStreet != null?c.MailingStreet:'') +' '+ (c.MailingCity != null?c.MailingCity:'') +' '+ (c.MailingState != null?c.MailingState:'') +' '+ (c.MailingPostalCode != null?c.MailingPostalCode:'') +' '+ (c.MailingCountry != null?c.MailingCountry:'');
                    string oldVal = (conOld.get(c.id).MailingStreet != null?conOld.get(c.id).MailingStreet:'') +' '+ (conOld.get(c.id).MailingCity != null?conOld.get(c.id).MailingCity:'') +' '+ (conOld.get(c.id).MailingState!=null?conOld.get(c.id).MailingState:'') +' '+ (conOld.get(c.id).MailingPostalCode!=null?conOld.get(c.id).MailingPostalCode:'') +' '+ (conOld.get(c.id).MailingCountry!=null?conOld.get(c.id).MailingCountry:'');
                    newAuditTrialCreate.add(new AuditTrail__c(Field__c='Address',Timestamp__c = Datetime.now(),Modifiedby__c=UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c=newval,OldValue__c=oldVal,Contact__c=c.id));
                }
                if(c.MPG__c != conOld.get(c.id).MPG__c)
                    newAuditTrialCreate.add(new AuditTrail__c(Field__c = 'Miles per Gallon',Timestamp__c = Datetime.now(),Modifiedby__c=UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c = String.Valueof(c.MPG__c),OldValue__c = String.Valueof(conOld.get(c.id).MPG__c),Contact__c = c.id));
                if(c.Manager__c != conOld.get(c.id).Manager__c)
                    newAuditTrialCreate.add(new AuditTrail__c(Field__c = 'Manager',Timestamp__c = Datetime.now(),Modifiedby__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c = managerNames.get(c.Manager__c),OldValue__c = managerNames.get(conOld.get(c.id).Manager__c),Contact__c = c.id));
                if(c.monthly_compliance_status__c != conOld.get(c.id).monthly_compliance_status__c)
                    newAuditTrialCreate.add(new AuditTrail__c(Field__c = 'monthly compliance status',Timestamp__c = Datetime.now(),Modifiedby__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c = String.Valueof(c.monthly_compliance_status__c),OldValue__c = String.Valueof(conOld.get(c.id).monthly_compliance_status__c),Contact__c = c.id));
                if(c.Vehicle_Type__c != conOld.get(c.id).Vehicle_Type__c)
                    newAuditTrialCreate.add(new AuditTrail__c(Field__c = 'Standard Vehicle Make Model and Year',Timestamp__c = Datetime.now(),Modifiedby__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c=c.Vehicle_Type__c,OldValue__c = conOld.get(c.id).Vehicle_Type__c,Contact__c=c.id));
            }
            if(c.Deactivated_Date__c != conOld.get(c.Id).Deactivated_Date__c)
                newAuditTrialCreate.add(new AuditTrail__c(Field__c = 'Deactivation Date',Timestamp__c=Datetime.now(),Modifiedby__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),NewValue__c = String.valueOf(c.Deactivated_Date__c),OldValue__c = String.valueOf(conOld.get(c.id).Deactivated_Date__c),Contact__c = c.id));
        }
        if(newAuditTrialCreate.Size()>0)
            upsert newAuditTrialCreate;
    }
    //Populate Contact Fields
    public static void populatestaticValue(List<Contact> conList){
        System.debug('inside populatestaticValue');
        Boolean isEMCUser = [select UserRole.name FROM User WHERE Id=:userinfo.getUserId()].UserRole.Name == 'EMC' ? true : false;
        for(Contact c : conList) {
            if(!isEMCUser){
                c.Pay_Number__c = '3';
                c.Batch_ID_Fixed__c = 'M351';
                c.Adjust_Ded_Code_Fixed__c = 'MR';
                c.Batch_Variable_ID__c = 'M352';
                c.Adjust_Ded_Code_Variable__c = 'VR';
                c.Special_Action__c = 'W';
            }  else {
                c.Pay_Number__c = String.IsBlank(c.Pay_Number__c) ? '3' : c.Pay_Number__c;
                c.Batch_ID_Fixed__c = String.IsBlank(c.Batch_ID_Fixed__c) ? 'M351' : c.Batch_ID_Fixed__c;
                c.Adjust_Ded_Code_Fixed__c = String.IsBlank(c.Adjust_Ded_Code_Fixed__c) ? 'MR' : c.Adjust_Ded_Code_Fixed__c;
                c.Batch_Variable_ID__c = String.IsBlank(c.Batch_Variable_ID__c) ? 'M352' : c.Batch_Variable_ID__c;
                c.Adjust_Ded_Code_Variable__c = String.IsBlank(c.Adjust_Ded_Code_Variable__c) ? 'VR' : c.Adjust_Ded_Code_Variable__c;
                c.Special_Action__c = String.IsBlank(c.Special_Action__c) ? 'W' : c.Special_Action__c;
            }
        }
    }
    /* EMC - 333
* This Method is used to when driver is insert, driver packet is  automatically added in file section
* FROM his Account's file section.
*/
    Public Static void insertDriverAggrementFile(Map<Id, Contact> conNewMap) {
        System.debug('inside insertDriverAggrementFile');
        Map<id, List<ID>> mapOfAccountIDvsCon  = new Map<ID, List<Id>>();
        List<ID> accIdList = new List<ID>();
        Map<ID, contact> mapConIdvsCon = new Map<ID, Contact>();
        set<Id> lstConId = new set<Id>();
        Map<Id, Id> mapConIdvsCdlId = new Map<Id, Id>();
        for(Contact objcon : [SELECT id,name,Account.isUsingTriplog__c,AccountID FROM Contact WHERE id in: conNewMap.keyset()]){
            accIdList.add(objcon.AccountID);
            mapConIdvsCon.put(objcon.Id, objcon);
            lstConId.add(objcon.Id);
            if(!mapOfAccountIDvsCon.containsKey(objCon.AccountID)){
                mapOfAccountIDvsCon.put(objCon.AccountID, new List<Id> { objCon.ID });
            }else{
                mapOfAccountIDvsCon.get(objCon.AccountID).add(objCon.ID);
            }
        }
        List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();
        if(accIdList != null && accIdList.size() > 0){
            for(ContentDocumentLink cdl : [SELECT ContentDocument.title,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :  lstConId AND ContentDocument.Title like '%Driver Agreement%' ORDER BY ContentDocument.CreatedDate]){
                mapConIdvsCdlId.put(cdl.LinkedEntityId, cdl.Id);
            }
            for(ContentDocumentLink cdl : [SELECT ContentDocument.title,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :  accIdList AND ContentDocument.Title like '%Driver Agreement%' ORDER BY ContentDocument.CreatedDate DESC LIMIT 1]) {
                if(mapOfAccountIDvsCon.containsKey(cdl.LinkedEntityId)){
                    for(ID obj: mapOfAccountIDvsCon.get(cdl.LinkedEntityId)){
                        if(!mapConIdvsCdlId.containsKey(obj)){
                            ContentDocumentLink objCDL = new ContentDocumentLink();
                            objCDL.ContentDocumentId = cdl.ContentDocumentId;
                            objCDL.LinkedEntityId = obj;
                            objCDL.ShareType = 'I';
                            objCDL.Visibility = 'AllUsers';
                            lstContentDocumentLink.add(objCDL);
                        }
                    }
                }
            }
        }
        if(lstContentDocumentLink != null && lstContentDocumentLink.size() > 0){
            Insert lstContentDocumentLink;
        }
    }
    /* EMC - 357
New Contact is created at that time we have to update plan parameter section's field
(Insurance Plan,Plan Years,Vehicle Value and Business Use) value update automatically based on account's same fields .
*/
    public static void updatePlanParameter(Set<String> conIdList, Set<String> setaccountid) {
        System.debug('inside updatePlanParameter');
        Map<Id,String> mapIdvsInsplan = new Map<Id, String>();
        Map<Id,Decimal> mapIdvsPlanyear = new Map<Id, Decimal>();
        Map<Id,Decimal> mapIdvsBusinessUse = new Map<Id, Decimal>();
        Map<String,Decimal> mapVehicleValue = new Map<String, Decimal>();
        String[] splitactivationdate ;
        // monthvsCompMilieageMap is used for count compliance mileages.
        Map<String,Decimal> monthvsCompMilieageMap = new Map<String,Decimal> {'12' => 4583.3334, '01' => 4166.6668, '02' => 3750, '03' => 3333.3336, '04' => 2916.667,
            '05' => 2500, '06' => 2083.3334, '07' => 1666.6668, '08' => 1250, '09' => 833.3334,
            '10' => 416.6668, '11' => 0};
                for (Vehicle_Value__c vehValue : [SELECT id,Account__c, Vehicle_URL_Mapping__r.Name,Value__c
                                                  FROM Vehicle_Value__c
                                                  WHERE Account__c IN :setaccountid]){
                                                      mapVehicleValue.put(vehValue.Account__c + '-' + vehValue.Vehicle_URL_Mapping__r.Name.toUpperCase() , vehValue.Value__c);
                                                  }
        for(Account acc : [SELECT id,name,Insurance_Plan__c, Plan_Years__c, Vehicle_Types__c, Business_Use__c
                           FROM Account
                           WHERE ID IN :setaccountid]){
                               mapIdvsInsplan.put(acc.ID, acc.Insurance_Plan__c);
                               mapIdvsPlanyear.put(acc.ID, acc.Plan_Years__c);
                               mapIdvsBusinessUse.put(acc.ID, acc.Business_Use__c);
                           }
        List<contact> updateConList = new List<Contact>();
        if(conIdList.size() > 0) {
            for(Contact con : [SELECT id,name,AccountId,Activation_Date__c,Vehicle_Type__c,Insurance_Plan__c, Plan_Years__c,Business_Use__c,Role__c
                               FROM contact
                               WHERE Id IN :conIdList]) {
                                   if(mapIdvsInsplan.containsKey(con.AccountId)){
                                       con.Insurance_Plan__c = mapIdvsInsplan.get(con.AccountID);
                                       con.Plan_Years__c = mapIdvsPlanyear.get(con.AccountID);
                                       con.Business_Use__c = mapIdvsBusinessUse.get(con.AccountID);
                                   }
                                   if(mapVehicleValue.containsKey(con.AccountId + '-' + con.Vehicle_Type__c.toUpperCase())){
                                       con.Vehicle_Value__c = mapVehicleValue.get(con.AccountId + '-' + con.Vehicle_Type__c.toUpperCase());
                                   }    else {
                                       con.Vehicle_Value__c = null;
                                   }
                                   /*
EMC-372
based On the activation date of drivers compliance mileages auto calculate.
Maximum Compliance Mileages per year is 5000 mileage.
for single month compliance mileages are  5000/12 =  416.66666
now if the contact is activated from 1st date of the moth to 7th date of the month than compliance mileages for that month is  416.66666
if Driver is activate from 8th to 15th date of the month than compliance mileages for that month is (416.6666/4) * 3 = 312.495(three week of proration)
if Driver is activate from 16th to 23th date of the month than compliance mileages for that month is (416.6666/4) * 2 = 208.33(Two week of proration)
And if Driver is activate after 23th date of the month than compliance mileages for that month is 416.6666/4 = 104.165(One week of proration)
Example :-
if any driver is activate on the 5th of march than Compliance Mileages are 10(From March to December )*416.6666 = 416.666
if driver is activate on the 8th of march than Compliance Mileages are (9 (From April to December )* 416.6666) + 312.495(March month 3 Weeks of Prorations) = 4062.4944
if driver is activate on the 20th of march than Compliance Mileages are (9(From April to December )* 416.6666) + 208.33 (March month's 2 Weeks of Prorations) = 3958.33
if driver is activate on the 28th of march than Compliance Mileages are (9 (From April to December )* 416.6666) + 104.165 (March month's 1 Weeks of Prorations) = 3854.1644
*/
                                   if(con.Activation_Date__c != null){
                                       splitactivationdate = String.valueOf(con.Activation_Date__c).split('-');
                                       if(Integer.valueOf(splitactivationdate[0]) == System.today().year()){
                                           if(monthvsCompMilieageMap.containsKey(splitactivationdate[1])){
                                               if(Integer.valueOf(splitactivationdate[2]) < 8){
                                                   con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 416.6666;
                                               }   else if (Integer.valueOf(splitactivationdate[2]) >= 8 && Integer.valueOf(splitactivationdate[2]) <= 15) {
                                                   con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 312.495;
                                               }   else if (Integer.valueOf(splitactivationdate[2]) >= 16 && Integer.valueOf(splitactivationdate[2]) <= 23) {
                                                   con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 208.33;
                                               }   else {
                                                   con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 104.165;
                                               }
                                           }
                                       } else if(Integer.valueOf(splitactivationdate[0]) < System.today().year()){
                                           if(splitactivationdate[1] == '12'){
                                               // con.Compliance_Mileage__c = 5000;
                                               if(Integer.valueOf(splitactivationdate[2]) < 8){
                                                   con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 416.6666;
                                               }   else if (Integer.valueOf(splitactivationdate[2]) >= 8 && Integer.valueOf(splitactivationdate[2]) <= 15) {
                                                   con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 312.495;
                                               }   else if (Integer.valueOf(splitactivationdate[2]) >= 16 && Integer.valueOf(splitactivationdate[2]) <= 23) {
                                                   con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 208.33;
                                               }   else {
                                                   con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 104.165;
                                               }
                                           } else {
                                               con.Compliance_Mileage__c = 5000;
                                           }
                                       }  else if(Integer.valueOf(splitactivationdate[0]) > System.today().year()){
                                           if(Integer.valueOf(splitactivationdate[2]) < 8){
                                               con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 416.6666;
                                           }   else if (Integer.valueOf(splitactivationdate[2]) >= 8 && Integer.valueOf(splitactivationdate[2]) <= 15) {
                                               con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 312.495;
                                           }   else if (Integer.valueOf(splitactivationdate[2]) >= 16 && Integer.valueOf(splitactivationdate[2]) <= 23) {
                                               con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 208.33;
                                           }   else {
                                               con.Compliance_Mileage__c = (monthvsCompMilieageMap.get(splitactivationdate[1])) + 104.165;
                                           }
                                       }
                                       /*else if(Integer.valueOf(splitactivationdate[0]) > System.today().year() || Integer.valueOf(splitactivationdate[0]) < System.today().year()){
con.Compliance_Mileage__c = 5000;
}*/
                                   }
                                   updateConList.add(con);
                               }
        }
        if(updateConList.size() > 0){
            Update updateConList;
        }
    }
    /*********************************************************************************************************************************
* this class update the value of map_country field on the contact with every change in zipcode of contact in the contact object *
*********************************************************************************************************************************/
    @future(callout=true)
    public static void updateMapCountry(set<String> conlist1){
        System.debug('inside updateMapCountry');
        list<contact> conlist =[SELECT id,Map_Country__c,MailingPostalCode FROM contact WHERE id IN :conlist1 AND MailingPostalCode!=null];
        list<contact> conlistUpdated =new list<contact>();
        for(contact con :conlist){
            String zipCode= con.MailingPostalCode;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json?address='+zipCode+'&sensor=false&key=AIzaSyDnaP6tZBTFOCUpfNbCXMZwnLDTQ3aOrug');
            req.setMethod('GET');
            req.setTimeout(5000);
            try{
                HttpResponse res = h.send(req);
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> results = (List<Object>) jsonMap.get('results');
                if (results != null && !results.isEmpty()) {
                    Map<String, Object> firstResult = (Map<String, Object>) results[0];
                    String formattedAddress = (String) firstResult.get('formatted_address');
                    // Print the result or use it as needed
                    String Country ;
                    Country = formattedAddress.substring(formattedAddress.lastindexOf(',')+1);
                    con.Map_Country__c=country;
                    conlistUpdated.add(con);
                }
            }
            catch (Exception e) {
                system.debug(e);
            }
            if(!conlistUpdated.isEmpty()){
                update conlistUpdated;
            }
        }
    }
    /**************************************************************************************************************************************************************************
* this method is there to create the user in mlog when the role is changed in the org from manager to driver manager and creating reimbersemner and biweekreimbersement  *
**************************************************************************************************************************************************************************/
    public static void creatuserreimbermentrecrds(List<Contact> newCon, Map<ID, Contact> conOldMap){
        System.debug('inside creatuserreimbermentrecrds');
        List<Employee_Reimbursement__c> reimToInsert   = new List<Employee_Reimbursement__c>();
        List<Bi_Weekly_Reimbursement__c> bireimToInsert   = new List<Bi_Weekly_Reimbursement__c>();
        map<string, Decimal> gasPriceMap = GetGasPrice();
        List<IRS_Mileage_Rate__c> objIRSRate = [SELECT id,year__c,IRS_Rate__c FROM IRS_Mileage_Rate__c WHERE year__c =: String.valueOf(System.today().year()) Limit 1];
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE   Name = 'Customer Community Login User - Manager/Driver' limit 1];
        String IRSRateId;
        if(!objIRSRate.isEmpty()){
            IRSRateId= objIRSRate[0].id;
        }
        for(Contact con : newCon) {
            TriggerConfig__c customSetting = TriggerConfig__c.getInstance('Defaulttrigger');
            if(customSetting.ContactTriCommunityReimCreate__c == true && IRSRateId!=null) {
                reimToInsert.add(CreateReimbursement(con,gasPriceMap,IRSRateId));
                if(customSetting.ContactTriBiReimCreate__c == true) {
                    bireimToInsert.add(CreateBiweekReimbursement(con,gasPriceMap,con.Monthly_Reimbursement__c));
                }
            }
            if(!reimToInsert.isEmpty()){
                try{
                    upsert reimToInsert;
                    if(!bireimToInsert.isEmpty()){
                        upsert bireimToInsert;
                    }
                } catch (DMLException e) {
                    system.debug('DMLException='+e);
                }
            }
            list<ContentDocumentLink> cdl = [SELECT ContentDocument.title,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId  =:  con.Id AND ContentDocument.Title like '%Driver Agreement%'ORDER BY ContentDocument.CreatedDate];
            if(Test.isRunningTest()){
                cdl.clear();
            }
            if(cdl.isempty()){
                List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();
                for(ContentDocumentLink cdl1 : [SELECT ContentDocument.title,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId  =:  con.AccountId AND ContentDocument.Title like '%Driver Agreement%' ORDER BY ContentDocument.CreatedDate DESC LIMIT 1]){
                    ContentDocumentLink objCDL = new ContentDocumentLink();
                    objCDL.ContentDocumentId = cdl1.ContentDocumentId;
                    objCDL.LinkedEntityId = con.Id;
                    objCDL.ShareType = 'I';
                    objCDL.Visibility = 'AllUsers';
                    lstContentDocumentLink.add(objCDL);
                }
                if(lstContentDocumentLink != null && lstContentDocumentLink.size() > 0 && !Test.isRunningTest()){
                    Insert lstContentDocumentLink;
                }
                if(con.Triplog_UserID__c==null){
                    list<Id> conIdList=new list<Id>{con.id};
                        //RosterController.postHTTPCreateNewUserTriplog(conIdList);
                        CreateNewUsermLogBatch crtmLogUser = new CreateNewUsermLogBatch();
                    Database.executebatch(crtmLogUser, 200);
                }else{
                    updateUserInMlog(con.id);
                }
            }
        }
    }
    @future(callout=true)
    public static void updateUserInMlog(String conId){
        System.debug('inside updateUserInMlog');
        Http h;
        HttpRequest req;
        HttpResponse res;
        String mLOGACCOUNT = System.Label.Triplog_New_URL + ',' + System.Label.Triplog_New_URL2;
        for(Contact conObj : [SELECT id,Triplog_UserID__c,Email, Account.Triplog_API__c  FROM Contact WHERE id =: conId]) {
            if(conObj.Triplog_UserID__c != null && conObj.Account.Triplog_API__c != null){
                String baseURL = !mLOGACCOUNT.Contains( conObj.Account.Triplog_API__c ) ? StaticValues.TRIPLOG_BASEURL : StaticValues.MLOG_BASEURL;
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('isDriver','true');
                gen.writeEndObject();
                h = new Http();
                req = new HttpRequest();
                req.setEndpoint( baseURL + StaticValues.DEACTIVATE_USER_SUFFIX+'/'+conObj.Triplog_UserID__c);
                String st=baseURL + StaticValues.DEACTIVATE_USER_SUFFIX;
                req.setMethod('PUT');
                req.setTimeout(120000);
                req.setbody(gen.getAsString());
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Authorization', 'apikey '+ conObj.Account.Triplog_API__c);
                if(!Test.isRunningTest())
                {
                    res = h.send(req);
                }
            }
        }
    }
    @future
    public static void updateUser(String conId,String role){
        System.debug('inside updateUser');
        list<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Customer Community Login User - Driver' OR  Name = 'Customer Community Login User - Manager' OR  Name = 'Customer Community Login User - Super Manager' OR  Name = 'Customer Community Login User - Manager/Driver' OR  Name = 'Customer Community Login User - Super Manager/Driver'];
        Map<string,Id> profilemap = new Map<string,ID>();
        for(Profile profileObj : profileList){
            if(profileObj.Name == 'Customer Community Login User - Driver' ){
                profilemap.put('Driver',profileObj.id);
            } else if(profileObj.Name == 'Customer Community Login User - Manager'){
                profilemap.put('Manager',profileObj.id);
            } else if(profileObj.Name == 'Customer Community Login User - Manager/Driver'){
                profilemap.put('Driver/Manager',profileObj.id);
            } else if(profileObj.Name == 'Customer Community Login User - Super Manager/Driver'){
                profilemap.put(StaticValues.roleAdminDriver ,profileObj.id);
            }  else if(profileObj.Name == 'Customer Community Login User - Super Manager'){
                profilemap.put('Admin',profileObj.id);
            }
        }
        List<User> conUser = new list<User>() ;
        conUser = [SELECT id FROM User WHERE ContactId =: conId limit 1];
        if(conUser.size()>0){
            conUser[0].profileId=profilemap.get(role);
        }
        update conUser;
    }
    /*EMC-2227
* Description :- This Method is used to update Employee Mileage from mile to kelometer id the Driver's
* map Contry field on contact is updated from other map contry to "CANADA" than Actual Mileage field
* on Employee mileage object of that driver is update as "Actual Mileage * 1.609".
*Precondition :- Trip status is not approved Yet.
*
*
* Author :- PARAS DHANANI
* Created Date :-18/09/2023
*/
    public static void updtcanadianmil(Set<Id> conIdList){
        System.debug('inside updtcanadianmil');
        List<Employee_Mileage__c> updateMilList = new List<Employee_Mileage__c>();
        for(Employee_Mileage__c mil : [SELECT id,EMP_Mileage__c,IsMileageConverted__c FROM Employee_Mileage__c WHERE EmployeeReimbursement__r.Contact_Id__c =: conIdList AND Trip_Status__c = 'Not Approved Yet' AND Activity__c = 'Business' AND EmployeeReimbursement__r.Status__c = 'Pending' ]){
            if(!mil.IsMileageConverted__c){
                mil.EMP_Mileage__c = (mil.EMP_Mileage__c != null) ? mil.EMP_Mileage__c * 1.609129171 :mil.EMP_Mileage__c;
                mil.IsMileageConverted__c=true;
                updateMilList.add(mil);
            }
        }
        if(updateMilList.size() > 0){
            update updateMilList;
        }
    }
    /*EMC-2227
* Description :-this method update username and email of the user when the external email is changed on the contact
*Email field on the contact is changed to trigger this method
* username and email is changed of the related user
*
*
* Author :- KHUMAN SINGH
* Created Date :-21/09/2023
*/
    @future
    public static void updateEmailOfUser( set<String> conLstId){
        System.debug('inside updateEmailOfUser');
        list<user>updateduser= new List<user>();
        for(String con :conLstId ){
            List<User> conUser = new list<User>() ;
            conUser = [SELECT id,contact.External_Email__c ,Email ,Username  FROM User WHERE ContactId =: con limit 1];
            if(conUser.size()>0){
                conUser[0].Email=conUser[0].contact.External_Email__c;
                conUser[0].Username=conUser[0].contact.External_Email__c;
                updateduser.add(conUser[0]);
            }
        }
        update updateduser;
    }
    public Static void sendEmailOnInsuranceIdUpdate(List<Contact> ConList,Map<Id,Contact> conMap){
        System.debug('inside sendEmailOnInsuranceIdUpdate');
        List<Messaging.SingleEmailMessage> emailLst = new List<Messaging.SingleEmailMessage>();
        for(Contact currentContact : ConList) {
            //sending email on change of Insurance_Attachment_Id__c to the admin who is supposed to check it validation
            system.debug('current'+conMap.get(currentContact.ID).Insurance_Attachment_Id__c);
            system.debug('Old'+currentContact.Insurance_Attachment_Id__c);
            if((currentContact.Insurance_Attachment_Id__c!= conMap.get(currentContact.ID).Insurance_Attachment_Id__c && currentContact.Insurance_Attachment_Id__c!=null)||Test.isRunningTest()){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                OrgWideEmailAddress[] owea = [SELECT Id,Address from OrgWideEmailAddress where Address = 'driverservices@mburse.com'];
                System.debug('Name-->'+currentContact.FirstName+' '+currentContact.LastName);
                String body = 'Hi, Team <br><br>'+currentContact.FirstName +' '+currentContact.LastName+'\'s Insurance is update. new insurance Attachment Id is'+ currentContact.Insurance_Attachment_Id__c+'. <br><br>      Thank you.';
                String subject = 'Driver Insurance Updated!';
                if (owea.size() > 0) {
                    email.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                SendEmailonDeactivation__c bccEmails =SendEmailonDeactivation__c.getValues('InsuranceIdUpdate');
                if(bccEmails.BCCEmailaddresses__c!=null){
                    String EmailAddresses = bccEmails.BCCEmailaddresses__c;
                    String[] bccaddresses = EmailAddresses.split(',');
                    email.setBccAddresses(bccAddresses);
                }
                String[] toaddresses = new String[] {'support@mburse.zendesk.com'};
                    //String[] toaddresses = new String[] {'khumansingh.ict19@gmail.com'};
                    email.setToAddresses(toAddresses);
                //email.setSenderDisplayName(currentContact.FirstName+' '+currentContact.LastName);
                email.setSubject(subject);
                email.setHTMLBody(body);
                if(bccEmails.Send_to_me__c==true){
                    emailLst.add(email);
                }
            }
        }
        if(emailLst.size()>0 && (!Test.isRunningTest())){
            Messaging.SendEmailResult [] r = Messaging.sendEmail(emailLst);
            //system.debug('email result '+r);
        }
    }
}