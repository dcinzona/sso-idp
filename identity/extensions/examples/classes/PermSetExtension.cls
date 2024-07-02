public with sharing class PermSetExtension extends JitHandlerExtension {

    public PermSetExtension() {
        super(100);
    }

    public PermSetExtension(Integer sortOrderNumber) {
        super(sortOrderNumber);
    }

    public override void run(Map<String, Object> context) {
        // Implementation
        System.debug(LoggingLevel.INFO, 'PermSetExtension.run(Map<String, Object>)');
    }

    public override RunAfterContext runAfterContext() {
        // Implementation
        System.debug(LoggingLevel.INFO, 'PermSetExtension.runAfterContext()');
        return RunAfterContext.HANDLE_JIT;
    }
}