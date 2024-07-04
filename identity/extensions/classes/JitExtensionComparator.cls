public class JitExtensionComparator implements Comparator<JitHandlerExtension>{
    public Integer compare(JitHandlerExtension e1, JitHandlerExtension e2) {
        // Implementation
        System.debug(LoggingLevel.INFO, 'JitExtensionComparator.compare()');
        if(e1?.sortOrder() == e2?.sortOrder()){
            return 0;
        } else if(e1?.sortOrder() == null){
            return 1;
        } else if(e2?.sortOrder() == null){
            return -1;
        } else if(e1?.sortOrder() > e2?.sortOrder()){
            return 1;
        } else if(e1?.sortOrder() < e2?.sortOrder()){
            return -1;
        } else {
            return 0;
        }
    }
}