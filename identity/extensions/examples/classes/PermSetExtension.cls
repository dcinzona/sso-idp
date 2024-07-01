public with sharing class PermSetExtension extends JitHandlerExtension {

    public PermSetExtension() {
        super(100);
    }
    public PermSetExtension(Integer sortOrderNumber) {
        super(sortOrderNumber);
    }

    public override void run() {
        // Implementation
        System.debug(LoggingLevel.INFO, 'PermSetExtension.run()');
    }
}