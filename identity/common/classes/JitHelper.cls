public with sharing class JitHelper {
    public static void handleUser(boolean isNewUser, User user, Map<String, String> attributes,
                            String federationIdentifier, boolean isStandard) {
        System.debug('Attributes: \n' + json.serializePretty(attributes)); 
        if (isNewUser) {
            System.debug('Federation Identifier: ' + federationIdentifier);
            if(String.isNotBlank(federationIdentifier)){
                user.FederationIdentifier = federationIdentifier;
            }
            UserProvisioningHelper.createUser(user, getAttributesFromAssertion(attributes));
        } else {
            Boolean hasLicensesAvailable = LicenseHelper.isLicenseAvailable(user.ProfileId, 10);

            if (!user.isActive) {
                if (!hasLicensesAvailable) {
                    UserProvisioningHelper.deactivateUser(user.ProfileId);
                }
                user.isActive = true;

                try {
                    update user;
                } catch(Exception e) {
                    throw new JitHandler.JitException('Error Activating User');
                }
            }
        }
    }

    public static Map<String,String> getAttributesFromAssertion(Map<String,String> attributes) {
        Map<String,String> newMap = new Map<String,String>();
        for(String key : attributes.keySet()) {
            if (key != 'username') {
                newMap.put(key, attributes.get(key));
            } 
        }
        // Parse assertion and populate attributes
        return newMap;
    }
}