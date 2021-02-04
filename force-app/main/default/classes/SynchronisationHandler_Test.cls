@IsTest(SeeAllData = false)
public class SynchronisationHandler_Test {
    
    @IsTest
    public static void doTest1(){
        Account a  = new Account(Name = 'Test Acc',BillingStreet = 'Rue du test');
        insert a;

        Contact c = New Contact(LastName =  'Test Contact', AccountId = a.Id, MailingStreet = 'N/A');
        insert c;

        Test.startTest();
        SynchronisationHandler.doSync(new List<Account>{a},new List<Contact>{c});
        Test.stopTest();

        System.assertEquals(a.BillingStreet, c.MailingStreet);
    }
}
