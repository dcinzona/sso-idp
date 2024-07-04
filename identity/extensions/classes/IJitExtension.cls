public interface IJitExtension {
    void run(Map<String, Object> context);
    Integer sortOrder();
}