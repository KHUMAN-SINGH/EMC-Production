public class ImportLocationController {
  
   @AuraEnabled
    Public Static String getLocation(String conId) {
        List<locationWrapper> locationWrapperList = new List<locationWrapper>(); 
        
        for(schema.Location loc : [SELECT id,Name,New_Location_Name__c,Driver__r.App__c,Latitude,Longitude,Activity__c,Driver__r.Triplog_UserID__c,Location_Address__c,Range__c
                                   FROM Location 
                                   WHERE Driver__c =: conId and Driver__r.App__c != null ]){
                                       locationWrapper wrapper = new locationWrapper();
                                       wrapper.userId = loc.Driver__r.Triplog_UserID__c;
                                       wrapper.name = loc.New_Location_Name__c  ;
                                       wrapper.id = loc.Id;
                                       wrapper.address = loc.Location_Address__c;
                                       wrapper.latitude = loc.Latitude;
                                       wrapper.longitude = loc.Longitude;
                                       wrapper.range = loc.Range__c;
                                       wrapper.activity = loc.Activity__c;
                                       locationWrapperList.add(wrapper);
                                   }
        String locationJSONString = JSON.serialize(locationWrapperList);
        return locationJSONString;
    } 
    
    // locationJSONString - for Save Location in Salesforce
    // localJSONString - for Save Location in mLog
    @AuraEnabled
    Public Static string updateLocation(String locationJSONString , String contactId, String localJSONString){

        try{
            List<Schema.Location> locationLstToUpdate = new List<Schema.Location>();
            locationLstToUpdate = jsonCollectionCommon(locationJSONString,contactId);

            if(locationLstToUpdate.size() > 0){
                update locationLstToUpdate;
            }
            List<Contact> conLst = [Select Id, name, App__c, AccountId from Contact where Id =: contactId ];
            if(conLst[0].App__c != null){
                ManageNotificationController.UploadLocation(localJSONString,conLst[0].AccountId);
            }
            return 'Success';
        }
        catch(Exception e){
            return 'Fail';
        }
    }
    
    // locationJSONString - for Save Location in Salesforce
    // localJSONString - for Save Location in mLog
    @AuraEnabled
    Public Static String updateLocationMlog(String locationJSONString , String contactId, String localJSONString){
        List<Schema.Location> locationLstToInsert = new List<Schema.Location>();
        try{
            locationLstToInsert = jsonCollectionCommon(locationJSONString,contactId);
            if(locationLstToInsert.size() > 0){
                insert locationLstToInsert;
            }
            List<Contact> conLst = [Select Id, name, App__c, AccountId from Contact where Id =: contactId ];
            if(conLst[0].App__c != null){
                ManageNotificationController.UploadLocation(localJSONString,conLst[0].AccountId);
            }  
            return 'Success';
        }
        catch(Exception e){
            return 'Fail';
        }
    }

    Public Static List<Schema.Location> jsonCollectionCommon (String locationJSONString, String conId){
        List<locationWrapper> locationResponse =  
            (List<locationWrapper>) System.JSON.deserialize(locationJSONString, List<locationWrapper>.class);
            List<Schema.Location> locationLstToUpdateOrInsert = new List<Schema.Location>();
        
        List<Contact> conLst = [Select Id,Name from Contact where Id=: conId];
        Integer tempNum = 0;
        for(locationWrapper wrapData : locationResponse){
            Schema.Location objLocation = new Schema.Location();
            if(wrapData.userId != null){
                if(wrapData.id != null){
                    objLocation.Id = wrapData.id;
                }
                
                objLocation.Name = String.valueOf(conLst[0].Id)+' '+tempNum;
                objLocation.Location_Address__c =  wrapData.address; 
                objLocation.Latitude = wrapData.latitude;
                objLocation.Longitude = wrapData.longitude;
                objLocation.Range__c =wrapData.range;
                objLocation.Activity__c = wrapData.activity;
                objLocation.Driver__c = conId;
                objLocation.New_Location_Name__c = wrapData.name;
                locationLstToUpdateOrInsert.add(objLocation);
                tempNum++;
            }
        }
        return locationLstToUpdateOrInsert;
    }

    public class locationWrapper{
        public String userId{get;set;} 
        public string id{get;set;} 
        public string name{get;set;}
        public Decimal latitude{get;set;}
        public Decimal longitude{get;set;}
        public string address{get;set;}
        public Decimal range{get;set;}
        public String activity{get;set;}
    }
}