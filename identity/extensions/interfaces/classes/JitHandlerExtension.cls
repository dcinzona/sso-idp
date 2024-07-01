public abstract class JitHandlerExtension implements JitExtensionInterface {

    public Integer sortOrderNumber = 100;

    public JitHandlerExtension() {
        System.debug(LoggingLevel.INFO, 'JitHandlerExtension()');
    }
    public JitHandlerExtension(Integer sortOrderNumber) {
        this.sortOrderNumber = sortOrderNumber;
        System.debug(LoggingLevel.INFO, 'JitHandlerExtension(sortOrderNumber)');
    }
    
    public virtual Integer sortOrder() {
        System.debug(LoggingLevel.INFO, 'Virtual JitHandlerExtension.sortOrder()');
        return this.sortOrderNumber;
    }

    public abstract void run();

}