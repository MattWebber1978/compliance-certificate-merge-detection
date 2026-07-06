@IsTest
private class TriggerHandlerTest {

    // Purpose-built subclass that records which lifecycle hook fired,
    // so dispatch can be verified without any real SObject or trigger.
    private class TestHandler extends TriggerHandler {
        public Boolean beforeInsertCalled = false;
        public Boolean beforeUpdateCalled = false;
        public Boolean beforeDeleteCalled = false;
        public Boolean afterInsertCalled = false;
        public Boolean afterUpdateCalled = false;
        public Boolean afterDeleteCalled = false;
        public Boolean afterUndeleteCalled = false;

        protected override void beforeInsert()  { beforeInsertCalled = true; }
        protected override void beforeUpdate()  { beforeUpdateCalled = true; }
        protected override void beforeDelete()  { beforeDeleteCalled = true; }
        protected override void afterInsert()   { afterInsertCalled = true; }
        protected override void afterUpdate()   { afterUpdateCalled = true; }
        protected override void afterDelete()   { afterDeleteCalled = true; }
        protected override void afterUndelete() { afterUndeleteCalled = true; }
    }

    @IsTest
    static void runThrowsWhenCalledOutsideTriggerContext() {
        TestHandler handler = new TestHandler();
        Boolean exceptionThrown = false;

        try {
            handler.run();
        } catch (TriggerHandler.TriggerHandlerException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('outside of a trigger context'));
        }

        System.assert(exceptionThrown);
    }

    @IsTest
    static void dispatchesToBeforeInsertOnly() {
        TestHandler handler = new TestHandler();
        handler.isTriggerExecuting = true;
        handler.context = TriggerHandler.TriggerContext.BEFORE_INSERT;

        handler.run();

        System.assert(handler.beforeInsertCalled);
        System.assert(!handler.afterInsertCalled);
        System.assert(!handler.beforeUpdateCalled);
    }

    @IsTest
    static void dispatchesToAfterDeleteOnly() {
        TestHandler handler = new TestHandler();
        handler.isTriggerExecuting = true;
        handler.context = TriggerHandler.TriggerContext.AFTER_DELETE;

        handler.run();

        System.assert(handler.afterDeleteCalled);
        System.assert(!handler.beforeDeleteCalled);
        System.assert(!handler.afterUpdateCalled);
    }

    // Same pattern covers BEFORE_UPDATE, BEFORE_DELETE, AFTER_INSERT,
    // AFTER_UPDATE, AFTER_UNDELETE - worth adding one test per remaining
    // context for full coverage of the switch statement.

    @IsTest
    static void bypassPreventsDispatch() {
        TestHandler handler = new TestHandler();
        handler.isTriggerExecuting = true;
        handler.context = TriggerHandler.TriggerContext.BEFORE_INSERT;

        String handlerName = handler.getHandlerName();
        TriggerHandler.bypass(handlerName);

        handler.run();

        System.assert(!handler.beforeInsertCalled);
        System.assert(TriggerHandler.isBypassed(handlerName));

        TriggerHandler.clearBypass(handlerName);
        System.assert(!TriggerHandler.isBypassed(handlerName));
    }

    @IsTest
    static void clearAllBypassesRemovesEveryBypass() {
        TriggerHandler.bypass('SomeHandler');
        TriggerHandler.bypass('AnotherHandler');

        TriggerHandler.clearAllBypasses();

        System.assert(!TriggerHandler.isBypassed('SomeHandler'));
        System.assert(!TriggerHandler.isBypassed('AnotherHandler'));
    }

    @IsTest
    static void loopCountThrowsOnceMaxExceeded() {
        TestHandler handler = new TestHandler();
        handler.isTriggerExecuting = true;
        handler.context = TriggerHandler.TriggerContext.BEFORE_UPDATE;
        handler.setMaxLoopCount(1);

        handler.run(); // 1st call - within limit
        Boolean exceptionThrown = false;
        try {
            handler.run(); // 2nd call - exceeds limit of 1
        } catch (TriggerHandler.TriggerHandlerException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Max loop count'));
        }

        System.assert(exceptionThrown);
    }

    @IsTest
    static void clearMaxLoopCountRemovesLimit() {
        TestHandler handler = new TestHandler();
        handler.isTriggerExecuting = true;
        handler.context = TriggerHandler.TriggerContext.BEFORE_UPDATE;
        handler.setMaxLoopCount(1);
        handler.clearMaxLoopCount();

        handler.run();
        handler.run();
        handler.run(); // would have thrown by now if the limit weren't cleared

        System.assert(handler.beforeUpdateCalled);
    }
}