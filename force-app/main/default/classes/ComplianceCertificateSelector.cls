public class ComplianceCertificateSelector implements IComplianceCertificateSelector {
    public List<ComplianceCertificate__c> selectRecentlyModifiedByAccountIdsAndUser(
        Set<Id> accountIds, Id modifiedById, DateTime windowStart) {
            return [
                SELECT Id, AccountMD__c 
                FROM ComplianceCertificate__c 
                WHERE AccountMD__c IN :accountIds 
                AND LastModifiedDate >= :windowStart 
                AND LastModifiedById = :modifiedById
            ];
    }
}