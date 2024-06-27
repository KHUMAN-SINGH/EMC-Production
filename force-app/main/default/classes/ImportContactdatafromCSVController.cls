public class ImportContactdatafromCSVController implements Database.Batchable<CSVToContact>, Database.Stateful, Database.AllowsCallouts {
    public String exceptionMessage = '';
    public final String  JsonString;
    public list<CSVToContact> LstCon ;
    public string accId;
    public string adminMailId;
    public Map<Integer,String> errorMap = new Map<Integer,String>();
    public List<Contact> allContactList = new List<Contact>();
    public String vehicleName;
    
    public ImportContactdatafromCSVController (String data,String accountId, String adminId){
        System.debug('file:: '+data );
        System.debug('accountId:: '+accountId );
        System.debug('AdminId:: '+adminId );      
        this.JsonString = data;
                // this.LstCon = CSVToContact.parse(JsonString);
        // System.debug('lstcon   :: '+LstCon );

        

        accId  = accountId;
        for(Contact con : [SELECT id,External_Email__c FROM contact WHERE id =: adminId]) {
            adminMailId = con.External_Email__c;           
        }
    }
    
    public Iterable<CSVToContact> start(Database.BatchableContext bc){    
        system.debug('inside start method');
        this.lstCon=CSVToContact.parse(JsonString);
        return new CSVIterator(lstCon);
            }
    
    public void execute(Database.BatchableContext info, List<CSVToContact> scope){
        boolean flag =false;
        checkRecursive.setting_SetLatLondAddressFlag(flag);

        Savepoint spMain = Database.setSavepoint();
        System.debug('checking scope'+scope);
        Boolean checkValue;
        system.debug('inside execute  method 1 ');

        Map<String, String> vehicleNameUrlMap = new Map<String, String>();
        Set<String> existingVehiclelist = new Set<String>();
        List<Vehicle_URL_Mapping__c> allVehiclelist = new List<Vehicle_URL_Mapping__c>();
        try {
        system.debug('inside execute  method 2 ');

                 TrueDialog_Keys__c tdKeys =TrueDialog_Keys__c.getInstance('TrueDialogKeys');
                 tdKeys.Contact_Insert_From_File__c = true;
        system.debug('inside execute  method 3 ');

                 update tdKeys;
                //Getting all vehicle details
                for (Vehicle_URL_Mapping__c veh : [SELECT Name FROM Vehicle_URL_Mapping__c limit 50000]) {
                    existingVehiclelist.add(veh.Name);
                }
            
        system.debug('inside execute  method 4 ');
                for( CSVToContact con : scope){
                    if(checkValue != true && String.isNotBlank(con.StandardVehicle)){
                    	vehicleName = con.StandardVehicle;
                        System.debug('vehicleName'+vehicleName);
                        checkValue = true;
                    }
                    if(con.StandardVehicle != '' && con.VehicleURL != '' && existingVehiclelist.contains(con.StandardVehicle) == false){
                        VehicleNameUrlMap.put(con.StandardVehicle.trim(), con.VehicleURL );
                    }
                }
        system.debug('inside execute  method 5');

            
            //Insert Vehicles
            for(String vName : VehicleNameUrlMap.keySet()) {
                Vehicle_URL_Mapping__c vehicleObj = new Vehicle_URL_Mapping__c();
                vehicleObj.Name = vName;
                vehicleObj.Year__c = vName.substringBefore(' ');
                vehicleObj.vehicle__c = vName.substringAfter(' ');
                vehicleObj.URL__c = VehicleNameUrlMap.get(vName);
                allVehiclelist.add(vehicleObj);
            }
           // System.debug('Vehicle name in parent first : '+allVehiclelist);
            Database.UpsertResult[] urVehicleList = Database.upsert(allVehiclelist, Vehicle_URL_Mapping__c.Name );
            
            System.debug('vehicle name: '+vehicleName);
            //System.debug('Vehicle name in parent : '+allVehiclelist);
            string accVehicles ;
            for (account acc : [select id,Vehicle_Types__c from Account where id =: accId and Vehicle_Types__c != null ]){
            accVehicles = acc.Vehicle_Types__c;
             }
        system.debug('inside execute  method 6 ');


            for(CSVToContact con : scope){
                System.debug('row=== '+con );
                System.debug('preparecontactList==='+preparecontactList(con, accId,vehicleName,accVehicles));
                System.debug('Vehicle name in parent : '+vehicleName);
                allContactList.add(preparecontactList(con, accId, vehicleName,accVehicles));
            }

            system.debug('allContactList=='  + allContactList);
            if(!allContactList.isEmpty()){
               
                System.debug('All Contact List: '+allContactList);
                Database.saveResult[] insertDriverList = Database.insert(allContactList, false);
                system.debug('insertDriverList=='  + insertDriverList);
                Integer erroFlagCount = 0;

                for (Database.saveResult sr : insertDriverList) {
                    system.debug('sr=='  + sr);
                    System.debug('sr sucess: '+ sr.isSuccess());
                    if (sr.isSuccess() == false) {
                        for(Database.Error objErr : sr.getErrors()) {
                            String errorlog = json.serialize(objErr);
                            system.debug('error list: '+errorlog);
                            //errorMap.put(erroFlagCount, errorlog);
                            errorMap.put(erroFlagCount, objErr.getMessage());
                            System.debug('Error in insert Contact ' + errorMap);
                        }
                    }
                    erroFlagCount ++;
                }
            
               
            }
            system.debug('errorMap=='  + errorMap);
            Map<String, Contact> contactMap = new Map<String, Contact>();
            Id adminId;
            system.debug('');
            for(Contact conObj : allContactList){
                if(conObj.id != null){
                    contactMap.put(conObj.Email, conObj);
                    if(conObj.Role__c != null && conObj.Role__c != '' && conObj.Role__c != 'Driver' /*&& (conObj.Manager_External_Email__c == null || conObj.Manager_External_Email__c == '')*/){
                        adminId = conObj.id;
                    }
                }
            }
            Map<String, Contact> oldContactMap = new Map<String, Contact>();
            if(accId != null && accId != ''){
                Account accountContactList = [Select id,(Select id,Email,Admin__c,Manager__c,Manager_External_Email__c from contacts) from account where id =: accId];
                
                for(Contact conListObj : accountContactList.contacts){
                    if(conListObj.Id != null){
                        oldContactMap.put(conListObj.Email, conListObj);
                        if((conListObj.Manager__c == null) && conListObj.Manager_External_Email__c != null && !contactMap.containskey(conListObj.Email)){
                            System.debug('11-->');
                            contactMap.put(conListObj.Email, conListObj);
                        }                        
                        if(adminId != null) {
                            adminId = conListObj.Admin__c;
                        }
                            
                    }
                }
            }
            for(contact conObj : contactMap.values()){
                if((conObj.Manager__c == null) && conObj.Manager_External_Email__c != null){
                    contactMap.get(conObj.Email).Manager__c = contactMap.containsKey(conObj.Manager_External_Email__c) ? contactMap.get(conObj.Manager_External_Email__c)?.Id : oldContactMap.containsKey(conObj.Manager_External_Email__c) ? oldContactMap.get(conObj.Manager_External_Email__c)?.Id : null;
                    if(conObj.Manager_External_Email__c != null && conObj.Manager_External_Email__c != '') {
                        contactMap.get(conObj.Email).Admin__c = adminId;
                    }
                        
                }
            }
            Database.saveResult[] insertDriverList = Database.update(contactMap.values(), false);
            System.debug('insertdriverlis '+insertDriverList);

            
        }   catch(Exception e){
            exceptionMessage = 'Exception:-'+e.getMessage()+' '+e.getLineNumber();
            System.debug('Exception error Messagae'+e.getMessage());
            Database.rollback(spMain);
        }
        
    }
   public static Contact preparecontactList(CSVtoContact csvRecordData, string accId, String vehicleName,String accVehicles){
        System.debug('csv record data'+csvRecordData);
        System.debug('vehicleName'+vehicleName);
        
            
        //myString1.contains(myString2);
        system.debug('Insert into accVehicles if condition');
        string[] vehicleSplit;
            if(accVehicles.contains(';')){
                system.debug('Insert into accVehicles if condition');
               vehicleSplit =  accVehicles.split(';');
            } 
      
      String invalidNumbers = '[^0-9]';

      system.debug('Insert into accVehicles if condition');

        Contact conObj = new Contact();
        conObj.Role__c = csvRecordData.Role ;
        if (accId != null) { 
            conObj.AccountId = accId;
        }             
        conObj.FirstName = csvRecordData.FirstName;

        //below two field added to not activate community user when contact is created.
        conObj.isCommunityUser__c = false;
        conObj.IsCreatedFromCommunity__c = false;
    
        conObj.LastName = csvRecordData.LastName;
        conObj.Email = csvRecordData.EmailAddress;
        conObj.External_Email__c = csvRecordData.EmailAddress;  
        conObj.MobilePhone =String.valueOf(csvRecordData.CellPhone);
        conObj.Phone = String.valueOf(csvRecordData.CellPhone);
        conObj.MailingCity = csvRecordData.City;
        conObj.MailingState = csvRecordData.State;
        conObj.MailingPostalCode = String.valueOf(csvRecordData.ZipCode);
        conObj.Department = csvRecordData.Department;   
        conObj.Job_Title__c = csvRecordData.JobTitle;
        conObj.Manager_First_Name__c = csvRecordData.ManagersFirstName;
        conObj.Manager_Last_Name__c = csvRecordData.ManagersLastName;
        string managerExtEmail = csvRecordData.ManagersEmail;
        if (managerExtEmail != '') {
            conObj.Manager_External_Email__c = managerExtEmail;
        }
        system.debug('con obj'+conObj);

        // String.valueOf(csvRecordData.ComplianceMileage)    ;
        if(csvRecordData.StandardVehicle != ''){conObj.Vehicle_Type__c = csvRecordData.StandardVehicle; }  
        if(String.valueOf(csvRecordData.InsuranceRate) != '' && csvRecordData.InsuranceRate != null && String.valueOf(csvRecordData.InsuranceRate) != 'null'){conObj.Insurance_Rate__c = Decimal.valueOf(csvRecordData.InsuranceRate);}
        if(String.valueOf(csvRecordData.LicenseandRegistration) != '' && csvRecordData.LicenseandRegistration != null && String.valueOf(csvRecordData.LicenseandRegistration) != 'null'){conObj.License_Ragistration__c = Decimal.valueOf(csvRecordData.LicenseandRegistration);}
        if(String.valueOf(csvRecordData.PersonalPropertyTax) != '' && csvRecordData.PersonalPropertyTax != null && String.valueOf(csvRecordData.PersonalPropertyTax) != 'null'){conObj.Taxes__c = Decimal.valueOf(csvRecordData.PersonalPropertyTax);}
        if(String.valueOf(csvRecordData.Depreciation) != '' && csvRecordData.Depreciation != null && String.valueOf(csvRecordData.Depreciation) != 'null'){conObj.Depreciation__c = Decimal.valueOf(csvRecordData.Depreciation);}
        if(String.valueOf(csvRecordData.AnnualFixedCost) != '' && csvRecordData.AnnualFixedCost != null && String.valueOf(csvRecordData.AnnualFixedCost) != 'null'){conObj.Annual_Fixed_Cost__c = Decimal.valueOf(csvRecordData.AnnualFixedCost);}
        if(String.valueOf(csvRecordData.FixedAmount) != '' && csvRecordData.FixedAmount != null && String.valueOf(csvRecordData.FixedAmount) != 'null'){conObj.Fixed_Amount__c = Decimal.valueOf(csvRecordData.FixedAmount) ; }
        if(String.valueOf(csvRecordData.FCA) != '' && csvRecordData.FCA != null && String.valueOf(csvRecordData.FCA) != 'null'){conObj.Fixed_Cost_Adjustment__c = Decimal.valueOf(csvRecordData.FCA);}
        if(String.valueOf(csvRecordData.TotalFixedAmount) != '' && csvRecordData.TotalFixedAmount != null && String.valueOf(csvRecordData.TotalFixedAmount) != 'null'){conObj.Total_Fixed_Costs__c = Decimal.valueOf(csvRecordData.TotalFixedAmount);}
        if(csvRecordData.Meeting != '') {conObj.Meeting__c = csvRecordData.Meeting;}
        system.debug('con obj'+conObj);

        //conObj.Packet__c = csvRecordData[26];
        if(csvRecordData.DateAdded != '') {
            Date dt=Date.valueof(csvRecordData.DateAdded.split('T')[0]);
            Date myDateIN=Date.newinstance(dt.year(), dt.MONTH(), dt.day());
        
            system.debug('***'+myDateIN);
                        
            conObj.Added_Date__c = myDateIN;
            System.debug('added date '+conObj.Added_Date__c);    
        }

        if(csvRecordData.ActivationDate != ''){
            Date dt1= Date.valueof(csvRecordData.ActivationDate.split('T')[0]);
            Date myDate1=Date.newinstance(dt1.year(), dt1.MONTH(), dt1.day());
            system.debug('***'+myDate1);
            conObj.Activation_Date__c =myDate1;
            System.debug('added date '+conObj.Activation_Date__c);
        } else {
            conObj.Activation_Date__c = system.today();
        }
        if(String.valueOf(csvRecordData.MPG) != '' && String.valueOf(csvRecordData.MPG) != 'null' && csvRecordData.MPG != null){conObj.MPG__c = Decimal.valueOf(csvRecordData.MPG);}   
        if(String.valueOf(csvRecordData.Maint) != '' && String.valueOf(csvRecordData.Maint) != 'null' && csvRecordData.Maint != null){conObj.Maintenance__c = Decimal.valueOf(csvRecordData.Maint);}   
        if(String.valueOf(csvRecordData.Tires) != '' && String.valueOf(csvRecordData.Tires) != 'null' && csvRecordData.Tires != null){conObj.Tires__c = Decimal.valueOf(csvRecordData.Tires);}
        if(String.valueOf(csvRecordData.MaintTires) != '' && String.valueOf(csvRecordData.MaintTires) != 'null' && csvRecordData.MaintTires != null){conObj.Maintenance_and_Tires__c = Decimal.valueOf(csvRecordData.MaintTires) ; }            

        if(csvRecordData.StandardVehicle == ''){
            conObj.Vehicle_Type__c = vehicleSplit.get(vehicleSplit.size()-1);
        } else if(csvRecordData.StandardVehicle != ''){
            conObj.Vehicle_Type__c = csvRecordData.StandardVehicle;
        }/* else {
                System.debug('Vehicle name in else: '+ vehicleSplit[0]);
                conObj.Vehicle_Type__c = vehicleName;
        } */
        if(String.valueOf(csvRecordData.ComplianceMileage) != '' && String.valueOf(csvRecordData.ComplianceMileage) != 'null' && csvRecordData.ComplianceMileage != null){conObj.Compliance_Mileage__c = Decimal.valueOf(csvRecordData.ComplianceMileage);}
        if(csvRecordData.VehicleURL != ''){conObj.Car_Image__c = csvRecordData.VehicleURL;}
        System.debug('conObj :::' +conObj);
        return conObj;
    }
    
    public void finish(Database.BatchableContext info){
        for(Contact con : allContactList){
            if(con.id != null) {
                try {                 
                    contactTriggerHelper.putHTTPCallout(con.AccountId,con.External_Email__c);
                } catch(Exception e){
                      system.debug('Catch=');
                }
            }
           
        }       
       
        Set<String> tmpConIdSet = new Set<String>();
        for(contact con : allContactList){
            tmpConIdSet.add(con.Id);     
        }
        Map<Id,Contact> contactIdMap =  new Map<Id, Contact>([select id, MobilePhone,
                                        Email,Account.True_Dialog__c FROM Contact 
                                        WHERE id IN: tmpConIdSet AND Account.True_Dialog__c=true ]);
        system.debug('contactIdMap=='+ contactIdMap);
        Set<Id> contactIdSet=contactIdMap.keyset();      
     
        TrueDialog_Keys__c tdKeys =TrueDialog_Keys__c.getInstance('TrueDialogKeys');

        if(contactIdSet.size() > 0  ){
            tdKeys.Contact_Insert_From_File__c = true;
            update tdKeys;            
            TrueDialog_Keys__c tdKeys1 =TrueDialog_Keys__c.getValues('TrueDialogKeys');        
            TrueDialogContactAPI tdContactApi = new TrueDialogContactAPI(contactIdSet);
            Database.executeBatch(tdContactApi,5);
        }        
        
        String errorSubject;
        String htmlbody;
        Boolean emailFalg = false;
        System.debug('exception message: '+exceptionMessage);
        System.debug('error map is empty: '+errorMap.isEmpty());
        System.debug('error map is empty: '+errorMap );
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        OrgWideEmailAddress[] owea = [SELECT Id,Address from OrgWideEmailAddress where Address = 'driverservices@mburse.com'];
        
        if((exceptionMessage == null || exceptionMessage == '') && !errorMap.isEmpty()) {           
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            System.debug('inside attachment construction if block: ');
            String csv = 'Index,Error Message\n';
            for (Integer key : errorMap.keySet()) {
                String errorMessage = errorMap.get(key).replaceAll(',', ';');
                csv += key + ',' + errorMessage + '\n';
            }   
            System.debug('CSV---> '+csv);
            
            attach.setBody(blob.valueOf(csv));
            attach.setFileName('Contact Error File .Csv');
            errorSubject = 'Error Result Of Contact Csv File';
            htmlbody = 'Your job is not completed due to some record has error, so please see the last column in attached csv file for error';
            email.setFileAttachments(new Messaging.EmailFileAttachment[] {attach});
            
        }else if((exceptionMessage == null || exceptionMessage == '') && errorMap.isEmpty()) {
            System.debug('no error in the contact list if block ');
            emailFalg = true;          
        }else if(exceptionMessage != null && exceptionMessage != ''){
            System.debug('exception occured ');
            errorSubject = 'Your job is rollback';
            htmlbody = 'Your job is rollback due to the error '+exceptionMessage + ',  please upload again or connect administrator';
        }
        if (owea.size() > 0) {
            email.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        String errorEmail = adminMailId;
        String[] toAddresses = new String[] {errorEmail};
        email.setToAddresses(toAddresses);

        email.setSubject(errorSubject);
        System.debug('out side the attachment creation blockx');
        email.setHTMLBody(htmlbody);
        if(emailFalg == false) {
            System.debug('error flag is still false');
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
            system.debug('email result '+r)  ;
        }

       
    }     
    }