@IsTest
private class AccountMergeCertificateResolverTest {

    private class FakeCertSelector implements IComplianceCertificateSelector {
        List<ComplianceCertificate__c> canned;
        Boolean wasCalled = false;

        FakeCertSelector(List<ComplianceCertificate__c> canned) {
            this.canned = canned;
        }

        public List<ComplianceCertificate__c> selectRecentlyModifiedByAccountIdsAndUser(
            Set<Id> accountIds, Id modifiedById, Datetime windowStart) {
            wasCalled = true;
            return canned;
        }
    }

    // MasterRecordId is read-only, so Apex won't let us set it via a normal
    // constructor. Serializing to an untyped map and back is the standard
    // workaround for assigning fields Apex blocks direct writes to.
    private static Account fakeMergeLoser(Id losingAccountId, Id masterRecordId) {
        Map<String, Object> fieldsMap = new Map<String, Object>{
            'Id' => losingAccountId,
            'MasterRecordId' => masterRecordId
        };
        return (Account) JSON.deserialize(JSON.serialize(fieldsMap), Account.class);
    }

    @TestSetup
    static void setup() {
        insert new List<Account>{
            new Account(Name = 'Fake Winning Account'),
            new Account(Name = 'Fake Losing Account')
        };
    }

    @IsTest
    static void returnsCertIdsFromSelectorWhenMasterRecordIdPresent() {
        List<Account> accounts = [SELECT Id, Name FROM Account ORDER BY Name];
        Account winner = accounts[0]; // 'Fake Winning Account'
        Account loser = accounts[1];  // 'Fake Losing Account'

        insert new ComplianceCertificate__c(Name = 'Fake Cert', AccountMD__c = winner.Id);
        ComplianceCertificate__c fakeCert = [SELECT Id FROM ComplianceCertificate__c LIMIT 1];

        FakeCertSelector fake = new FakeCertSelector(new List<ComplianceCertificate__c>{ fakeCert });
        AccountMergeCertificateResolver.certSelector = fake;

        Account fakeLoser = fakeMergeLoser(loser.Id, winner.Id);

        Test.startTest();
        Set<Id> result = AccountMergeCertificateResolver.resolveReparentedCertificateIds(
            new List<Account>{ fakeLoser }
        );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assert(result.contains(fakeCert.Id));
        System.assert(fake.wasCalled);
    }

    @IsTest
    static void doesNotQueryWhenNoMasterRecordId() {
        // a genuinely un-merged Account naturally has MasterRecordId == null,
        // so no JSON trick needed here at all
        Account nonMergeDelete = [SELECT Id, MasterRecordId FROM Account LIMIT 1];

        FakeCertSelector fake = new FakeCertSelector(new List<ComplianceCertificate__c>());
        AccountMergeCertificateResolver.certSelector = fake;

        Test.startTest();
        Set<Id> result = AccountMergeCertificateResolver.resolveReparentedCertificateIds(
            new List<Account>{ nonMergeDelete }
        );
        Test.stopTest();

        System.assertEquals(0, result.size());
        System.assertEquals(false, fake.wasCalled);
    }
}