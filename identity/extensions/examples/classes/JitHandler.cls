public with sharing class JitHandler implements Auth.SamlJitHandler {
    public class JitException extends Exception {}
    
    @TestVisible
    JitExtensionRegistry registry = new JitExtensionRegistry();
    
    public JitHandler() {
        System.debug(LoggingLevel.INFO, 'JitHandler()');
        // get other extensions
        System.debug(LoggingLevel.INFO, this.registry.extensions.size());
        registry.runExtensions(JitHandlerExtension.RunAfterContext.CONSTRUCTOR, new Map<String, Object>());
    }

    public User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {
        User u = new User();
        handleJit(true, u, samlSsoProviderId, communityId, portalId,
                  federationIdentifier, attributes, assertion);
        registry.runExtensions(JitHandlerExtension.RunAfterContext.CREATE_USER, new Map<String, Object>{
            'user' => u,
            'samlSsoProviderId' => samlSsoProviderId,
            'communityId' => communityId,
            'portalId' => portalId,
            'federationIdentifier' => federationIdentifier,
            'attributes' => attributes,
            'assertion' => assertion
        });
        return u;
    }
    public void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {
        User u = [SELECT Id, ProfileId, IsActive, Username FROM User WHERE Id = :userId];
        handleJit(false, u, samlSsoProviderId, communityId, portalId,
                  federationIdentifier, attributes, assertion);
        registry.runExtensions(JitHandlerExtension.RunAfterContext.UPDATE_USER, new Map<String, Object>{
            'user' => u,
            'samlSsoProviderId' => samlSsoProviderId,
            'communityId' => communityId,
            'portalId' => portalId,
            'federationIdentifier' => federationIdentifier,
            'attributes' => attributes,
            'assertion' => assertion
        });
    }
    private void handleUser(boolean create, User u, Map<String, String> attributes,
                            String federationIdentifier, boolean isStandard) {
         JitHelper.handleUser(create, u, attributes, federationIdentifier, isStandard);
         registry.runExtensions(JitHandlerExtension.RunAfterContext.HANDLE_USER, new Map<String, Object>{
            'user' => u,
            'create' => create,
            'federationIdentifier' => federationIdentifier,
            'isStandard' => isStandard,
            'attributes' => attributes
         });
    }
    private void handleJit(boolean create, User u, Id samlSsoProviderId, Id communityId, Id portalId,
                           String federationIdentifier, Map<String, String> attributes, String assertion) {
        if (communityId != null || portalId != null) {
            handleUser(create, u, attributes, federationIdentifier, false);
        } else {
            handleUser(create, u, attributes, federationIdentifier, true);
        }
        registry.runExtensions(JitHandlerExtension.RunAfterContext.HANDLE_JIT, new Map<String, Object>{
            'user' => u,
            'samlSsoProviderId' => samlSsoProviderId,
            'communityId' => communityId,
            'portalId' => portalId,
            'federationIdentifier' => federationIdentifier,
            'attributes' => attributes,
            'assertion' => assertion
        });
    }
}