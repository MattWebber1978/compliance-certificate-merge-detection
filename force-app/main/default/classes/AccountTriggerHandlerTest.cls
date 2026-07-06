@IsTest(
    testFor='ApexTrigger:AccountTrigger,ApexClass:AccountTriggerHandler,ApexClass:AccountMergeCertificateResolver,ApexClass:ComplianceCertificateMergeDeactivator')
private class AccountTriggerHandlerTest {

    @IsTest
    static void mergingAccountsDeactivatesReparentedCertificate() {
        Account winner = new Account(Name = 'Winning Account');
        Account loser = new Account(Name = 'Losing Account');
        insert new List<Account>{ winner, loser };

        ComplianceCertificate__c cert = new ComplianceCertificate__c(
            Name = 'Test Cert',
            AccountMD__c = loser.Id,
            StatusPL__c = 'Active'
        );
        insert cert;

        Test.startTest();
        merge winner loser;
        Test.stopTest();

        ComplianceCertificate__c updated = [
            SELECT AccountMD__c, StatusPL__c, StatusChangeReasonPL__c
            FROM ComplianceCertificate__c WHERE Id = :cert.Id
        ];
        System.assertEquals(winner.Id, updated.AccountMD__c);
        System.assertEquals('Inactive', updated.StatusPL__c);
        System.assertEquals('Inactive due to account merge', updated.StatusChangeReasonPL__c);
    }

    @IsTest
    static void ordinaryAccountDeleteDoesNotDeactivateCertificates() {
        Account acc = new Account(Name = 'Standalone Account');
        insert acc;
    
        ComplianceCertificate__c cert = new ComplianceCertificate__c(
            Name = 'Test Cert',
            AccountMD__c = acc.Id,
            StatusPL__c = 'Active'
        );
        insert cert;
    
        Test.startTest();
        delete acc; // not a merge - MasterRecordId stays null
        Test.stopTest();
    
        // ALL ROWS because AccountMD__c cascades on delete - deleting the parent
        // Account also deletes this cert. That's a schema fact, not our trigger
        // logic; we're only confirming our code never touched Status before that.
        ComplianceCertificate__c untouched = [
            SELECT StatusPL__c FROM ComplianceCertificate__c WHERE Id = :cert.Id ALL ROWS
        ];
        System.assertEquals('Active', untouched.StatusPL__c);
    }
}