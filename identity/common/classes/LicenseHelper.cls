public without sharing class LicenseHelper {

    public static Profile getProfile(String profileName) {
        if(String.isBlank(profileName)){
            throw new JitHandler.JitException('Profile name is required');
        }

        List<Profile> profiles = [SELECT Id, UserLicenseId, 
            UserLicense.TotalLicenses,
            UserLicense.UsedLicenses, 
            UserLicense.Name FROM  
            Profile 
            WHERE Name = :profileName];

        if (profiles.size() > 0) {
            return profiles[0];                
        }

        return null;
    }

    public static Boolean isLicenseAvailable(Id profileId, Integer minimumAvailableLicenseThreshold) {
        Integer availableLicenses = 0;

        List<UserLicense> licenses = [
            SELECT Id, Name, MasterLabel, LicenseDefinitionKey, UsedLicenses, TotalLicenses, Status
            FROM UserLicense
            WHERE Status = 'Active'
            AND Id IN (
                SELECT UserLicenseId
                FROM Profile
                WHERE Id = :profileId
            )
        ];

        if (licenses.isEmpty()) {
            throw new JitHandler.JitException('No licenses available');
        }

        availableLicenses = licenses[0].TotalLicenses - licenses[0].UsedLicenses;
        return availableLicenses > minimumAvailableLicenseThreshold;
    }

    public static Integer licensesAvailable(Integer total, Integer used) {
        return total - used;
    }
}