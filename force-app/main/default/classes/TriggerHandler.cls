public virtual class TriggerHandler {
    
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;
    
    @testVisible
    private TriggerContext context;
    @testVisible
    private Boolean isTriggerExecuting;
    
    static {
        loopCountMap = new Map<String, loopCount>();
        bypassedHandlers = new Set<String>();
    }
    
    public TriggerHandler() {
        this.setTriggerContext();
    }
        
    public void run() {
        if(!validateRun()) {
            return;
        }
        addToLoopCount();
        
        switch on this.context {
            when BEFORE_INSERT { this.beforeInsert(); }
            when BEFORE_UPDATE { this.beforeUpdate(); }
            when AFTER_INSERT { this.afterInsert(); }
            when AFTER_UPDATE { this.afterUpdate(); }
            when BEFORE_DELETE { this.beforeDelete(); }
            when AFTER_DELETE { this.afterDelete(); } 
            when AFTER_UNDELETE { this.afterUndelete(); }
        }
    }
        
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if(!loopCountMap.containsKey(handlerName)) {
            loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            loopCountMap.get(handlerName).setMax(max);
        }
    }
        
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }
    
    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }
    
    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }
    
    public static Boolean isBypassed(String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }
    
    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }
    
    @testVisible
    private void setTriggerContext() {
        if(!Trigger.isExecuting) {
            this.isTriggerExecuting = false;
            return;
        }
        this.isTriggerExecuting = true;
        
        if (Trigger.isBefore && Trigger.isInsert) this.context = TriggerContext.BEFORE_INSERT;
        else if (Trigger.isBefore && Trigger.isUpdate) this.context = TriggerContext.BEFORE_UPDATE;
        else if (Trigger.isAfter && Trigger.isInsert) this.context = TriggerContext.AFTER_INSERT;
        else if (Trigger.isAfter && Trigger.isUpdate) this.context = TriggerContext.AFTER_UPDATE;
        else if (Trigger.isBefore && Trigger.isDelete) this.context = TriggerContext.BEFORE_DELETE;
        else if (Trigger.isAfter && Trigger.isDelete) this.context = TriggerContext.AFTER_DELETE;
        else if (Trigger.isAfter && Trigger.isUndelete) this.context = TriggerContext.AFTER_UNDELETE;
    }
    
    @testVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        if (loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = loopCountMap.get(handlerName).increment();
            if (exceeded) {
                Integer max = loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException('Max loop count of: ' + max + ' reached in ' + handlerName);
            }
        }
    }
    
    @testVisible
    private Boolean validateRun() {
        if (!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException('TriggerHandler.run() called outside of a trigger context');
        }
        return !bypassedHandlers.contains(getHandlerName());
    }
    
    @testVisible
    private String getHandlerName() {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf('['));
    }
    
    // override these in the concrete handlers
    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}
    
    @testVisible
    private class LoopCount {
        private Integer max;
        private Integer count;
        
        public LoopCount() { this.max = 5; this.count = 0; }
        public LoopCount(Integer max) { this.max = max; this.count = 0; }
        
        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }
        public Boolean exceeded() { return this.max >= 0 && this.count > this.max; }
        public void setMax(Integer max) { this.max = max; } 
    }
    
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, AFTER_UNDELETE
    }
    
    public class TriggerHandlerException extends Exception {}
    
}