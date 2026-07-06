public class ComplianceCertificateMergeDeactivator {
    public static void deactivateCertificates(Set<Id> certificateIds) {
        if (certificateIds == null || certificateIds.isEmpty()) {
            return;
        }
        
        List<ComplianceCertificate__c> certsToUpdate = new List<ComplianceCertificate__c>();
        for(Id certId : certificateIds) {
            certsToUpdate.add(new ComplianceCertificate__c(
                Id = certId,
                StatusPL__c = 'Inactive',
                StatusChangeReasonPL__c = 'Inactive due to account merge'
            ));
        }
        update certsToUpdate;
    }
}