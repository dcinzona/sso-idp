public interface JitExtensionInterface {
    void run(Map<String, Object> context);
    Integer sortOrder();
}
