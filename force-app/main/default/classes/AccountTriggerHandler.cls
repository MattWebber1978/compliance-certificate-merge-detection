public class AccountTriggerHandler extends TriggerHandler {
    private List<Account> newAccounts;
    private List<Account> oldAccounts;
    private Map<Id, Account> newAccountsMap;
    private Map<Id, Account> oldAccountsMap;
        
    public AccountTriggerHandler () {
        this.newAccounts = (List<Account>) Trigger.new;
        this.oldAccounts = (List<Account>) Trigger.old;
        this.newAccountsMap = (Map<Id, Account>) Trigger.newMap;
        this.oldAccountsMap = (Map<Id, Account>) Trigger.oldMap;
    }
    
    protected override void beforeInsert () {
        
    }
    
    protected override void beforeUpdate () {
        
    }
    
    protected override void afterInsert () {
        
    }
    
    protected override void afterUpdate () {
        
    }
    
    protected override void beforeDelete () {
        
    }
    
    protected override void afterDelete () {
        Set<Id> reparentedCertIds = AccountMergeCertificateResolver.resolveReparentedCertificateIds((List<Account>) Trigger.old);
        if (reparentedCertIds.isEmpty()) {
            return;
        }
        
        ComplianceCertificateMergeDeactivator.deactivateCertificates(reparentedCertIds);    
    }
    
    protected override void afterUndelete () {
        
    }
}