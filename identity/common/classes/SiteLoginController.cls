/**
 * An apex page controller that exposes the site login functionality
 */
global without sharing class SiteLoginController{
    global String username {get; set;}
    global String password {get; set;}
    public String startUrl {get; set;}
    public Id orgId {get; set;}
    
    global SiteLoginController(){
        orgId = UserInfo.getOrganizationId();
        startUrl = System.currentPageReference().getParameters().get('startURL');
        if (startUrl == null) startUrl = '/';
    }
    
    global PageReference login() {
        PageReference pg;
        if(String.isBlank(password)){
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Info, 'Password is a required'));
            return null;
        }
        else{

                pg = tryLogin(username, password, startUrl);
                if(pg != null){
                    ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.INFO, 'pg: ' + pg.getUrl()));
                    //login successful
                    return pg;
                }
                if(pg == null){
                    List<User> users = [SELECT Id, isActive FROM User WHERE Username = :username];
                    if(users.size() > 0){
                        User u = users[0];
                        if(!u.IsActive){
                            //user is inactive
                            //activate user
                            try {
                                UserProvisioningHelper.activateUser(u);
                            } catch (Exception e) {
                                ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Error activating user: ' + e.getMessage()));
                                return null;
                            }
                            //try login again
                            pg = tryLogin(username, password, startUrl);
                        } else {
                            //user is active
                            return pg;
                        }
                    }
                    else{
                        //user not found
                        ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'User not found'));
                        // create user
                        Profile p = LicenseHelper.getProfile('Chatter Free User');
                        if(p == null){
                            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Profile not found'));
                            return null;
                        }
                        try{
                            if(!LicenseHelper.isLicenseAvailable(p.Id, 10)){
                                // no licenses available
                                // deactivate user
                                UserProvisioningHelper.deactivateUser(p.Id);
                                
                            }
                            User u = UserProvisioningHelper.createUser(p.Id, username, password);
                            if(u != null){
                                //try login again
                                pg = tryLogin(u.Username, password, startUrl);
                            }
                        }
                        catch(Exception e){
                            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating user: ' + e.getMessage()));
                            return null;
                        }
                    }
                }
        }
        return pg;
    }

    private PageReference tryLogin(String username, String password, String startUrl){
        return Site.login(username, password, startUrl);
    }
}