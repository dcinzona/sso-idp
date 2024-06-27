public with sharing class JitHandler implements Auth.SamlJitHandler {
    public class JitException extends Exception {}

    public User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {
        User u = new User();
        handleJit(true, u, samlSsoProviderId, communityId, portalId,
                  federationIdentifier, attributes, assertion);
        return u;
    }

    public void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {
        User u = [SELECT Id, ProfileId, IsActive, Username FROM User WHERE Id = :userId];
        handleJit(false, u, samlSsoProviderId, communityId, portalId,
                  federationIdentifier, attributes, assertion);
    }

    private void handleUser(boolean create, User u, Map<String, String> attributes,
                            String federationIdentifier, boolean isStandard) {
         JitHelper.handleUser(create, u, attributes, federationIdentifier, isStandard);
    }

    private void handleJit(boolean create, User u, Id samlSsoProviderId, Id communityId, Id portalId,
                           String federationIdentifier, Map<String, String> attributes, String assertion) {
        if (communityId != null || portalId != null) {
            handleUser(create, u, attributes, federationIdentifier, false);
        } else {
            handleUser(create, u, attributes, federationIdentifier, true);
        }
    }
}