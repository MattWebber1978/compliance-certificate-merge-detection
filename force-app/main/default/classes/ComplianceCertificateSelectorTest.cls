@IsTest
private class ComplianceCertificateSelectorTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Winning Account');
        insert acc;

        insert new ComplianceCertificate__c(
            Name = 'Test Cert',
            AccountMD__c = acc.Id
        );
    }

    @IsTest
    static void returnsCertModifiedByRunningUserWithinWindow() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ComplianceCertificate__c cert = [SELECT Id FROM ComplianceCertificate__c LIMIT 1];

        Datetime windowStart = Datetime.now().addSeconds(-60);

        Test.startTest();
        List<ComplianceCertificate__c> results = new ComplianceCertificateSelector()
            .selectRecentlyModifiedByAccountIdsAndUser(
                new Set<Id>{ acc.Id }, UserInfo.getUserId(), windowStart
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(cert.Id, results[0].Id);
    }

    @IsTest
    static void excludesCertOutsideTimeWindow() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // window starts in the future relative to when the cert was actually touched
        Datetime windowStart = Datetime.now().addSeconds(60);

        Test.startTest();
        List<ComplianceCertificate__c> results = new ComplianceCertificateSelector()
            .selectRecentlyModifiedByAccountIdsAndUser(
                new Set<Id>{ acc.Id }, UserInfo.getUserId(), windowStart
            );
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void excludesCertModifiedByDifferentUser() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Datetime windowStart = Datetime.now().addSeconds(-60);

        // real running user, deliberately not matching the modifiedById argument
        Id someOtherUserId = UserInfo.getUserId();

        Test.startTest();
        List<ComplianceCertificate__c> results = new ComplianceCertificateSelector()
            .selectRecentlyModifiedByAccountIdsAndUser(
                new Set<Id>{ acc.Id },
                '005000000000000AAA', // a deliberately non-matching Id
                windowStart
            );
        Test.stopTest();

        System.assertEquals(0, results.size());
    }
}