/* This Method is used to send notification on email when the externa email id of contact is changed
        and also update new email id in mlog/triplog and send mlog link to the driver 
*/

public class EmailChangeNotification {
    
    @InvocableMethod(label='Email Change Notification' description='Send Email change notification to the Driver' category='Contact')
    public static void changedEmailNotification(List<String> ids){
    	System.debug('Call Method from Flow');

        contact con = [SELECT Id,Name,Email,Account.Id from Contact where Id =: ids[0]];
        System.debug('accId: '+con.Account.Id);
        System.debug('email: '+con.Email);
        welcomemLogEmail(con.Account.Id,con.Email);

        ContactTriggerHelper.putHTTPEnableUserTriplog(ids[0],false);
        // String str = RosterController.putHTTP(con.Account.Id,con.Email);
        // System.debug('str'+str);
    }
    @Future(callout=true)
    public static void welcomemLogEmail(String accId,String email){
        RosterController.putHTTP(accId,email);
    }
}