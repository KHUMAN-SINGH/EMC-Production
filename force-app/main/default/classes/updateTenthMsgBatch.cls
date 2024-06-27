// @Date : 20/05/2024 || Vatsal Bhalani
// Need to Run manully => On the 4th of each month after the batch has been run.
// hello
public class updateTenthMsgBatch implements Database.Batchable<sObject>{
    public List<Contact> start(Database.BatchableContext bc){
        List<Contact> conList = [SELECT Id, name, Role__c, Activation_Date__c, Deactivated_Date__c, Account.isUsingTriplog__c
                                    FROM contact
                                    WHERE Deactivated_Date__c = NULL
                                        AND Account.isUsingTriplog__c = true
                                        AND Activation_Date__c != null
                                        AND (Role__c = 'Manager' OR Role__c = 'Admin' OR Role__c = 'Driver/Manager' OR Role__c = 'Driver/Admin')];
        return conList; 
    }
    public void execute(Database.BatchableContext bc, List<Contact> conList) {
        System.debug('conList: '+conList);
        List<String> lstContactId = new List<String>();
        List<Message__c> lstMsgToInsert = new List<Message__c>();
        for(Contact objContact: conList){
            lstContactId.add(objContact.Id);
        }
        
        for(Id objContactId : lstContactId){
                Message__c objMsg = new Message__c(
                    Unread__c = true,
                    Notification_Message__c = 'Your team’s mileage is ready to be approved.',
                    Contacts__c = objContactId
                ); 
                lstMsgToInsert.add(objMsg);
        }
        if(!lstMsgToInsert.isEmpty()){
            try {
                Database.insert(lstMsgToInsert, false);
            } catch (Exception e) {
                System.debug('Insertion Error : '+ e.getMessage());
            } 
            
        }
    }
    public void finish(Database.BatchableContext bc){
        return;
    }
}