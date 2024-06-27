public without sharing class UserProvisioningHelper {
	private static final Long CURRENT_TIME = Datetime.now().getTime();
	private static final String[] UPPERCASE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
	private static final String[] LOWERCASE_CHARS = 'abcdefghijklmnopqrstuvwxyz'.split('');
	private static final String[] NUMBER_CHARS = '1234567890'.split('');
	private static final String[] SPECIAL_CHARS = '!#$%-_=+<>'.split('');

	public static User createUser(Id profileId, String emailAddress, String password) {
        User u = new User();
        u.ProfileId = profileId;
        return createUser(u, new Map<string, string>{'email' => emailAddress, 'password' => password});
	}

    public static User createUser(User u, Map<string, string> attributes) {
        if(u == null){
            u = new User();
        }
        if(u.ProfileId == null){
            u.ProfileId = getProfileIdFromConfig();
        }
        Id orgId = UserInfo.getOrganizationId();

        if(attributes.containsKey('email')){
            u.Email = attributes.get('email');
        } else {
            u.Email = generateEmail();    
        }
        if(attributes.containsKey('username')){
            u.Username = attributes.get('username');
        } else {
            u.Username = u.Email + '.' + orgId;
        }
        if(u.FederationIdentifier == null){
            u.FederationIdentifier = u.Email + '.scratch';
            List<User> usersWithFedId = [SELECT Id FROM User WHERE FederationIdentifier = :u.FederationIdentifier];
            if (usersWithFedId.size() > 0) {
                Integer count = [SELECT COUNT() FROM User WHERE FederationIdentifier LIKE :u.Email + '.scratch%'];
                u.FederationIdentifier = u.Email + '.scratch' + count;
            }
        }

        u = handleUnsetRequiredFields(u);
        u.isActive = true;
        u.languagelocalekey = UserInfo.getLocale();
        u.localesidkey = UserInfo.getLocale();
        u.emailEncodingKey = 'UTF-8';
        u.timeZoneSidKey = UserInfo.getTimezone().getID();
        System.debug('u: ' + u);
        insert u;

        if(attributes.containsKey('password')){
            System.setPassword(u.Id, attributes.get('password'));
        }
        return u;
    }

    public static User createUser(Id profileId, Map<string, string> attributes) {
        User u = new User();
        return createUser(u, attributes);
    }

    private static Id getProfileIdFromConfig(){
        try{
            return [SELECT Id FROM Profile WHERE Name = :JIT_Config__mdt.getAll().values()[0].Profile_Name__c LIMIT 1].Id;
        } catch(Exception e){
            System.debug('No JIT Config found: \n' + e.getMessage());
        }
        return null;
    }

	// Generates a random number from 0 up to, but not including, max.
	private static Integer generateRandomInt(Integer max) {
		return Math.mod(Math.abs(Crypto.getRandomInteger()), max);
	}

	// Loops over required fields that were not passed in to set to some default value
	private static User handleUnsetRequiredFields(User u) {
		if (String.isBlank(u.LastName)){
			u.LastName = generateLastName();
		}
		if (String.isBlank(u.Username)) {
			u.Username = generateUsername();
		}
		if (String.isBlank(u.Email)) {
			u.Email = generateEmail();
		}
		if (String.isBlank(u.Alias)) {
			u.Alias = generateAlias();
		}
		if (String.isBlank(u.CommunityNickname)) {
			u.CommunityNickname = generateCommunityNickname();
		}
		return u;
	}
    
	// Default implementation to try to provide uniqueness
	private static String generateAlias() {
		String timeString = String.valueOf(CURRENT_TIME);
		return timeString.substring(timeString.length() - 8);
	}

	// Default implementation to try to provide uniqueness
	private static String generateLastName() {
		return 'ExternalUser' + CURRENT_TIME;
	}

	// Default implementation to try to provide uniqueness
	private static String generateUsername() {
		return 'externaluser' + CURRENT_TIME + '@company.com';
	}

	// Default implementation to try to provide uniqueness
	private static String generateEmail() {
		return 'externaluser' + CURRENT_TIME + '@company.com';
	}

	// Default implementation to try to provide uniqueness
	private static String generateCommunityNickname() {
		return 'ExternalUser' + CURRENT_TIME;
	}

    public static User activateUser(User u){
        if(u != null && !u.isActive){
            u.isActive = true;
            update u;
        }
        return u;
    }

    @Future(callout=false)
    public static void deactivateUser(Id profileId) {

        // get available licenses
        List<Profile> profiles = [SELECT Id, Name, UserLicenseId FROM Profile WHERE Id = :profileId];
        System.debug('profiles: ' + profiles);
        if (profiles.size() == 0) {
            System.debug('profile not found');
        }
        // get available licenses
        List<UserLicense> licenses = [SELECT Id, Name, TotalLicenses, UsedLicenses FROM UserLicense WHERE Id = :profiles[0].UserLicenseId];
        System.debug('licenses: ' + licenses);
        if (licenses.size() == 0) {
            System.debug('license not found');
        }
        Integer availableLicenses = licenses[0].TotalLicenses - licenses[0].UsedLicenses;
        System.debug('availableLicenses: ' + availableLicenses);
        if (availableLicenses <= licenses[0].TotalLicenses - 1) {
            //deactivate user
            List<User> userToDeactivate = [SELECT Id FROM User WHERE ProfileId = :profileId AND IsActive = true ORDER BY LastLoginDate ASC];
            if (userToDeactivate.size() > 0) {
                userToDeactivate[0].IsActive = false;
                update userToDeactivate[0];
            } else {
                System.debug('no user to deactivate');
            }
        }

    }
}