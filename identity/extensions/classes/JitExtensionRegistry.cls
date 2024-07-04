public without sharing class JitExtensionRegistry {
    private static List<JitHandlerExtension> kExtensions;
    public static JitExtensionComparator sorter = new JitExtensionComparator();

    public List<JitHandlerExtension> extensions {
        get {
            if (JitExtensionRegistry.kExtensions == null) {
                // get other extensions
                kExtensions = new List<JitHandlerExtension>();
                List<ApexTypeImplementor> implementors = [SELECT ClassName, ClassNamespacePrefix
                    FROM ApexTypeImplementor
                    WHERE InterfaceName = 'IJitExtension' 
                    and IsConcrete=true];
        
                for (ApexTypeImplementor implementor : implementors) {
                    Type t = Type.forName(implementor.ClassNamespacePrefix, implementor.ClassName);
                    JitHandlerExtension e = (JitHandlerExtension)t.newInstance();
                    JitExtensionRegistry.kExtensions.add(e);
                }
                JitExtensionRegistry.kExtensions.sort(JitExtensionRegistry.sorter);
            }
            return JitExtensionRegistry.kExtensions;
        }
        private set;
    }

    public JitExtensionRegistry() {
        // get other extensions
        System.debug(LoggingLevel.INFO, this.extensions.size());
    }

    public List<JitHandlerExtension> getExtensions() {
        return this.extensions;
    }

    public List<JitHandlerExtension> getExtensions(JitHandlerExtension.RunAfterContext context) {
        List<JitHandlerExtension> extensions = new List<JitHandlerExtension>();
        for (JitHandlerExtension e : this.extensions) {
            if (e.runAfterContext() == context) {
                extensions.add(e);
            }
        }
        return extensions;
    }

    public void runExtensions(JitHandlerExtension.RunAfterContext runAfter, Map<String, Object> context) {
        for (JitHandlerExtension e : this.getExtensions(runAfter)) {
            e.run(context);
        }
    }
}