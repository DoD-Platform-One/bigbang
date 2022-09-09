# PlatformOne uses MniOrange sso pulgins for Atlassian products

MiniOrange Plugin:
https://plugins.miniorange.com/oauth-openid-single-sign-on-sso-confluence-using-keycloak

Atlassian Marketplace:
https://marketplace.atlassian.com/apps/1218360/oauth-openid-connect-for-confluence-sso?hosting=server&tab=overview

Confluence OAuth/OpenID app gives the ability to enable OAuth/OpenID Single Sign-On for Confluence. Confluence is compatible with all OAuth/OpenID Providers. Here we will go through a guide to configure SSO between Confluence and your OAuth/OpenID Provider. By the end of this guide, users from your OAuth/OpenID Provider should be able to log in and register to Confluence.

## Pre-requisites
To integrate your OAuth/OpenID provider with Confluence, you need the following items:

* Confluence should be installed and configured.
* Confluence Server is https enabled (optional).
* Admin credentials are set up in Confluence.
* Valid Confluence Server and Data center Licence.

## Download And Installation
* Log into your Confluence instance as an admin.
* Navigate to the settings menu and Click Manage Apps.
* Click Find new apps or Find new add-ons from the left-hand side of the page.
* Locate Confluence OAuth/OpenID Connect Single Sign On (SSO), Confluence SSO via search.
* Click Try free to begin a new trial or Buy now to purchase a license for OAuth/OpenID Connect for Confluence SSO.
* Enter your information and click Generate license when redirected to MyAtlassian.
* Click Apply license.

## Step 1: Setup Keycloak as OAuth Provider
* Create openid client : Login to your Keycloak server. Go to the Clients and click on Create button. Enter client id and select openid-connect as client protocol and select Save.
* Change Access type: After client is created change its access type to confidential.
* Enter Valid Redirect URIs :
  * Copy the Callback URL from plugin and insert into Valid Redirect URIs field.
  * Click on SAVE.

* Keycloak Group Mapper:
  * Now, if you want to fetch the user groups you will have to map the client and group membership.
  * For that, navigate to the Clients and select the client Id you created, then go to the Mappers tab and click on Create.
  * Provide Name, select Mapper Type as Group Membership and enter the Token Claim Name i.e attribute name corresponding to which the groups will be sent.
  * Turn off Full group path else group mapping will fail. And then click on Save.
* Realm name: You need a realm name when you set up Keycloak as an OAuth provider, kindly copy it. For example in this case it is Master
* Get Client Secret: To get Client Secret Navigate to Clients, select Client Id and navigate to the Credentials tab.

## Step 2: Setup Confluence as OAuth Client
* Go to Configure OAuth tab, enter copied Client ID, Secret in the plugin.
* Enter the Host Name (Base URL of the Keycloak server For eg. http://example.com) and Realm Name you copied from the keycloak server.
* Enter JWKS EndPoint URL or Public Key for signature validation. eg.http://${yourKeycloakDomain}/auth/realms/${realmName}/protocol/openid-connect/certs
* Click on Test Configuration.

## Step 3: User Profile
We will be setting up user profile attributes for Confluence. If your users are stored in a directory that is Read Only, please check Disable Attribute Mapping in User Profile tab and follow steps given in Matching a User.
a. Finding correct attributes
  * Go to Configure OAuth tab. Scroll down and click on Test Configuration.
  * You will see all the values returned by your Oauth/OpenID Provider to Confluence in a table. If you don't see value for First Name, Last Name, Email or Username, make the required settings in your Oauth/OpenID Provider to return this information.
  * Once you see all the values in Test Configuration, keep the window open and go to User Profile tab.

b. Setting profile attributes
  * In this tab, fill the values by matching the name of the attribute. For instance, if the Attribute Name in the Test Configuration window is NameID, enter NameID against Username
  * Setting up both Username and Email is required if you want to let users register. If you want existing users to the only login, configure the attribute using which you will match the user in Confluence.

c. Matching a User
When the user logs into Confluence, one of the user's data/attribute coming in from the OAuth/OpenID Provider is used to search the user in Confluence. This is used to detect the user in Confluence and log in the user to the same account.
  * Go to User Profile tab
  * Select Username or Email for Login/Search Confluence user account by
  * Enter the attribute name from OAuth/OpenID Provider which corresponds to Username or Email using Finding Correct Attributes .

d. Custom Attribute Mapping
  * The custom attributes recieved in the OAuth/OpenID response can be configured using Configure User Properties(Custom Attributes) option.
  * Click Add Attributes .
  * Enter the attribute name( E.g. department) as User Property Key.
  * This option will be added in the profiles of Confluence Users.
  * Corresponding to this key, fill the attribute value you recieved in Test Configuration window. For instance, if the Attribute Name in the Test Configuration window is Department, enter Department as Attribute.
  * Another attribute e.g. location can be added by reclicking on Add Attributes option.

## Step 4: User Groups
We will be setting up user group attributes for Confluence. If your users are stored in a directory that is Read Only, please check Disable Group Mapping in User Groups tab and skip to Setting default group.

a. Setting default group
* Select the users' Default Group in the tab User Groups. If no group is mapped, users are added by default to this group.
* You can enable default groups for All Users or New Users using the option.Select None if you don't want to assign any default group to SSO users. Using the option Assign Default Group To.

b. Finding Group Attribute
* Just like we found Attribute Name for User Profile attributes, we find group attribute.
* Go to Configure OAuth tab. Scroll down and click on Test Configuration.
* You will see all the values returned by your OAuth/OpenID Provider to Confluence in a table. If you don't see value with groups, make the required settings in your OAuth Provider to return group names.
* Once you see all the values in Test Configuration, keep the window open and go to User Groups tab.
* Enter the Attribute Name of group against Group Attribute.
* Check Disable Group Mapping option if you don't want to update groups of existing users.

c. Group Mapping
Group Mapping can be done in two ways:
* Manual group mapping: If the names of groups in Confluence are different than the corresponding groups in OAuth/OpenID Provider, then you should use Manual group mapping.
* On-The-Fly group mapping: If the names of groups in Confluence and OAuth/OpenID Provider are same, you should use On-The-Fly group mapping.

I. Manual Group Mapping
* Check Restrict User Creation Based on Group Mapping option if you want new users to be created only if at least one of the user's OAuth/OpenID Provider groups is mapped to a group in the application.
* For mapping, first select a Confluence group from the dropdown which lists all groups present in Confluence and then enter the name of the OAuth/OpenID Provider group to be mapped in the textbox beside
* For example, if you want all users in 'dev' group in OAuth/OpenID Provider to be added to confluence-users, you will need to select confluence-users from the dropdown and enter 'dev' against confluence-users.
* Use '+1' and '+10' buttons to add extra mapping fields.
* Use '-' button next to each mapping to delete that mapping.

II. On-The Fly Group Mapping
* Check Create New Groups option if you want new groups from OAuth/OpenID Provider to be created if not found in Confluence.
* If the user is part of some group in Confluence and that group is not present in the OAuth/OpenID response returned by OAuth/OpenID Provider, then the user will be removed from that group in Confluence.
* If you don't want On-The-Fly group mapping to affect Confluence groups which are managed locally then add those groups in Exclude Groups field.

## Step 5: Sign In Settings
The settings in SSO Settings tab define the user experience for Single Sign On.
a. Sign In Settings
* Set Enable SSO for Confluence Server to allow SSO for Confluence users.
* Change the text on the SSO button on the login page using the Login Button Text option.
* Set the Relay State to the URL to which the users would be redirected after login. Keep this empty to redirect users to the same page they started with.
* Enable Auto-redirect to OAuth/OpenID Provider if you want to allow users to login only using OAuth/OpenID Provider. Enable backdoor for emergency.
* Restrict the access of backdoor URL to limited users by using the Restrict backdoor URL access based on user groups feature.
* Use Domain Restriction to allow login to only a specific set of users. You can configure multiple domains (semicolon-separated).
* For example, if only 'miniorange.com' and 'gmail.com' domains are allowed then, the user test@miniorange.com and test@gmail.com will be able to log in and user test@yahoo.com will not be able to login.
* Select Secure Admin Login Options to control admin access. User needs to authenticate again to access admin settings or to perform any admin operation. This helps you to add an extra level of security for admin access.

b. Sign Out Settings
* Set Logout URL or Logout Template to redirect users after logout action.

c. SSO Error Settings
* Set error template to redirect users to a custom error page instead of login page. Use this if you have Auto-redirect to Provider enabled.
