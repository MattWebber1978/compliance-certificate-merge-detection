public class AccountMergeCertificateResolver {
    
    @TestVisible
    private static IComplianceCertificateSelector certSelector = new ComplianceCertificateSelector();
        
    public static Set<Id> resolveReparentedCertificateIds(List<Account> mergeLosers) {
        Set<Id> confirmedCertIds = new Set<Id>();
        
        Set<Id> masterAccountIds = new Set<Id>();
        for(Account losingAccount : mergeLosers) {
            if(losingAccount.MasterRecordId != null) {
                masterAccountIds.add(losingAccount.MasterRecordId);
            }
        }
        if(masterAccountIds.isEmpty()) {
            return confirmedCertIds;
        }
        
        DateTime windowStart = DateTime.now().addSeconds(-20);
        
        List<ComplianceCertificate__c> candidatesForDeactivation = certSelector.selectRecentlyModifiedByAccountIdsAndUser(
            masterAccountIds, UserInfo.getUserId(), windowStart
        );
        
        for(ComplianceCertificate__c cert : candidatesForDeactivation) {
            confirmedCertIds.add(cert.Id);
        }
        
        return confirmedCertIds;
    }
}