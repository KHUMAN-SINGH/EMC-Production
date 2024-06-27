public with sharing class sendingBulkDriverPacket implements Queueable , Database.AllowsCallouts {
    public String ConIdLst ;
    Public String AdminID;
    public sendingBulkDriverPacket(String JsonString,String AdminId){
        this.ConIdLst = JsonString ;
        this.AdminID=AdminId;
    }
    public void execute(QueueableContext context) {
        try{
            // List<Contact> conList = [SELECT id FROM Contact WHERE Hello_Sign_Request_Id__c = null AND AccountId =: accountID AND  Deactivated_Date__c = null AND Role__c != 'Admin' AND Role__c != 'Manager'];
            List<String> contactIds = new List<String>();
            contactIds = (List<String>) System.JSON.deserialize(ConIdLst, List<String>.class);
            System.debug('listo of ids-->'+contactIds);
            // System.debug(ConIdLst);
            //List<Id> conListID =new List<Id>{'003E1000008EG1tIAG'};
            List<Contact> conList = [SELECT id,Name,email,Hello_Sign_Request_Id__c, Admin__c,Admin__r.Name,Admin__r.Email,Account.Admin_Contact__r.Name,Birthdate, Account.Admin_Contact__r.External_Email__c,Account.Admin_Contact__c,Account.Hello_Sign_Admin_Sign__c FROM Contact WHERE Id IN:contactIds ];
            System.debug('conList'+conList);
            for(contact Con :conList){
                if(con.Hello_Sign_Request_Id__c!=null ){
                   
                        voidEnvelope(con.Hello_Sign_Request_Id__c);
                    
                }
                SendEnvelopeFromTriggerController.sendEnvelope(Con.Id);
                System.debug('inside loopd');
            }
        }catch(Exception e){
            System.debug('Exception:- '+e.getmessage()+' - Line:-'+e.getLineNumber());
        }
    }
    @future(callout=true)
    public static void voidEnvelope(final String DDocuSignId){
        System.debug('ID'+DDocuSignId);
        List<Boolean> voidResult= new List<Boolean>();
        
        String voidReason ='Sent New Package';
        if(!Test.isRunningTest()){
        dfsle.UUID docuSignId = dfsle.UUID.parse(DDocuSignId) ;
        Boolean isVoided = dfsle.StatusService.voidEnvelope(docuSignId, voidReason);
        System.debug('voiding result'+voidResult);
         }     
    }
}