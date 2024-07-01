public abstract class JitHandlerExtension implements JitExtensionInterface {

    public Integer sortOrderNumber = 100;
    public static Map<String, Object> DEFAULT_CONTEXT = new Map<String, Object>();

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

    public virtual void run() {
        System.debug(LoggingLevel.INFO, 'abstract JitHandlerExtension.run()');
        run(DEFAULT_CONTEXT);
    }

    public virtual void run(Map<String, Object> context){
        System.debug(LoggingLevel.INFO, 'abstract JitHandlerExtension.run(Map<String, Object>)');
        System.debug(LoggingLevel.INFO, context);
    }

}