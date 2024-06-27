global class SelfRegController implements Auth.ConfigurableSelfRegHandler {

	private final Long CURRENT_TIME = Datetime.now().getTime();
	private final String[] UPPERCASE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
	private final String[] LOWERCASE_CHARS = 'abcdefghijklmnopqrstuvwxyz'.split('');
	private final String[] NUMBER_CHARS = '1234567890'.split('');
	private final String[] SPECIAL_CHARS = '!#$%-_=+<>'.split('');

	// This method is called once after verification (if any was configured)
	// This method should create a user and insert it
	// Password can be null
	// Return null or throw an exception to fail creation
	global Id createUser(Id accountId, Id profileId, Map<SObjectField, String> registrationAttributes, String password) {
		User u = new User();
        System.debug('accountId: ' + accountId);
        System.debug('profileId: ' + profileId);
        System.debug('registrationAttributes: ' + registrationAttributes);
        //Profile p = [SELECT Id FROM Profile WHERE Name='Chatter Free User' LIMIT 1];
        //System.debug('profile: ' + p);
		u.ProfileId = profileId; // p.Id;

		for (SObjectField field : registrationAttributes.keySet()) {
			String value = registrationAttributes.get(field);
			u.put(field, value);
		}
        u.FederationIdentifier = u.Email + '.scratch';
        List<User> usersWithFedId = [SELECT Id FROM User WHERE FederationIdentifier = :u.FederationIdentifier];
        if (usersWithFedId.size() > 0) {
            Integer count = [SELECT COUNT() FROM User WHERE FederationIdentifier LIKE :u.Email + '.scratch%'];
            u.FederationIdentifier = u.Email + '.scratch' + count;
        }
		u = handleUnsetRequiredFields(u);
		// generateContact(u, accountId);
		// if (String.isBlank(password)) {
		// 	password = generateRandomPassword();
		// }
		Site.validatePassword(u, password, password);

		if (u.contactId == null) {
            // System.debug('account: ' + accountId);
            try{
                deactivateUser(profileId);
                return Site.createExternalUser(u, accountId, password);
            } catch (Exception e) {
                System.debug('error: ' + e);
            }
		}
        u.isActive = true;
		u.languagelocalekey = UserInfo.getLocale();
		u.localesidkey = UserInfo.getLocale();
		u.emailEncodingKey = 'UTF-8';
		u.timeZoneSidKey = UserInfo.getTimezone().getID();
        System.debug('u: ' + u);
		insert u;
		System.setPassword(u.Id, password);
		return u.id;
	}

	// Method to autogenerate a password if one was not passed in
	// By setting a password for a user, we won't send a welcome email to set the password
	private String generateRandomPassword() {
		String[] characters = new List<String>(UPPERCASE_CHARS);
		characters.addAll(LOWERCASE_CHARS);
		characters.addAll(NUMBER_CHARS);
		characters.addAll(SPECIAL_CHARS);
		String newPassword = '';
		Boolean needsUpper = true, needsLower = true, needsNumber = true, needsSpecial = true;
		while (newPassword.length() < 50) {
			Integer randomInt = generateRandomInt(characters.size());
			String c = characters[randomInt];
			if (needsUpper && c.isAllUpperCase()) {
				needsUpper = false;
			} else if (needsLower && c.isAllLowerCase()) {
				needsLower = false;
			} else if (needsNumber && c.isNumeric()) {
				needsNumber = false;
			} else if (needsSpecial && !c.isAlphanumeric()) {
				needsSpecial = false;
			}
			newPassword += c; 
		}
		newPassword = addMissingPasswordRequirements(newPassword, needsLower, needsUpper, needsNumber, needsSpecial);
		return newPassword;
	}

	private String addMissingPasswordRequirements(String password, Boolean addLowerCase, Boolean addUpperCase, Boolean addNumber, Boolean addSpecial) {
		if (addLowerCase) {
			password += LOWERCASE_CHARS[generateRandomInt(LOWERCASE_CHARS.size())];
		}
		if (addUpperCase) {
			password += UPPERCASE_CHARS[generateRandomInt(UPPERCASE_CHARS.size())];
		}
		if (addNumber) {
			password += NUMBER_CHARS[generateRandomInt(NUMBER_CHARS.size())];
		}
		if (addSpecial) {
			password += SPECIAL_CHARS[generateRandomInt(SPECIAL_CHARS.size())];
		}
		return password;
	}

	// Generates a random number from 0 up to, but not including, max.
	private Integer generateRandomInt(Integer max) {
		return Math.mod(Math.abs(Crypto.getRandomInteger()), max);
	}

	// Loops over required fields that were not passed in to set to some default value
	private User handleUnsetRequiredFields(User u) {
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

	// Method to construct a contact for a user
	private void generateContact(User u, Id accountId) {
		// Add logic here if you want to build your own contact for the user
        Contact c = new Contact();
        c.AccountId = accountId;
        c.FirstName = u.FirstName;
        c.LastName = u.LastName;
        insert c;
        u.ContactId = c.Id;
	}

	// Default implementation to try to provide uniqueness
	private String generateAlias() {
		String timeString = String.valueOf(CURRENT_TIME);
		return timeString.substring(timeString.length() - 8);
	}

	// Default implementation to try to provide uniqueness
	private String generateLastName() {
		return 'ExternalUser' + CURRENT_TIME;
	}

	// Default implementation to try to provide uniqueness
	private String generateUsername() {
		return 'externaluser' + CURRENT_TIME + '@company.com';
	}

	// Default implementation to try to provide uniqueness
	private String generateEmail() {
		return 'externaluser' + CURRENT_TIME + '@company.com';
	}

	// Default implementation to try to provide uniqueness
	private String generateCommunityNickname() {
		return 'ExternalUser' + CURRENT_TIME;
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