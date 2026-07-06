// Abbreviated to fit Apex's 40-character class name limit
@IsTest
private class ComplianceCertMergeDeactivatorTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        insert new ComplianceCertificate__c(
            Name = 'Test Cert',
            AccountMD__c = acc.Id,
            StatusPL__c = 'Active'
        );
    }

    @IsTest
    static void deactivatesGivenCertificates() {
        ComplianceCertificate__c cert = [SELECT Id FROM ComplianceCertificate__c LIMIT 1];

        Test.startTest();
        ComplianceCertificateMergeDeactivator.deactivateCertificates(new Set<Id>{ cert.Id });
        Test.stopTest();

        ComplianceCertificate__c updated = [
            SELECT StatusPL__c, StatusChangeReasonPL__c FROM ComplianceCertificate__c WHERE Id = :cert.Id
        ];
        System.assertEquals('Inactive', updated.StatusPL__c);
        System.assertEquals('Inactive due to account merge', updated.StatusChangeReasonPL__c);
    }

    @IsTest
    static void doesNothingWhenGivenEmptySet() {
        Test.startTest();
        ComplianceCertificateMergeDeactivator.deactivateCertificates(new Set<Id>());
        ComplianceCertificateMergeDeactivator.deactivateCertificates(null);
        Test.stopTest();

        ComplianceCertificate__c cert = [SELECT StatusPL__c FROM ComplianceCertificate__c LIMIT 1];
        System.assertEquals('Active', cert.StatusPL__c); // untouched
    }
}