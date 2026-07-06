public interface IComplianceCertificateSelector {
    List<ComplianceCertificate__c> selectRecentlyModifiedByAccountIdsAndUser(
        Set<Id> accountIds, Id modifiedById, DateTime windowStart);
}