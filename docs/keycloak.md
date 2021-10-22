# NXRM Keycloak Configuration

**SAML/SSO integration is a *Pro* license feature.**

Nexus is a SAML client, not OIDC; the client ID must be a URL. Due to these facts it is not practical to automate SSO testing.

Due to this limitation, we will not be providing a complete values example here or in bigbang.

BigBang requires/prefers SAML/SSO integration out of the box; unfortunately, the upstream Helm chart did not have a solution at the drafting of this integration. To achieve our goal, we added a Kubernetes job that handles the SAML/SSO integration as part of the NXRM Helm installation. To enable this functionality, ensure `sso.enabled` is set to `true`; you will additionally require a Keycloak instance, the IDP metadata file, along with other parameters you may define in `sso.idp_data`.

Our implementation closely follows the [Sonatype SAML Integration](https://support.sonatype.com/hc/en-us/articles/1500000976522-SAML-integration-for-Nexus-Repository-Manager-Pro-3-and-Nexus-IQ-Server-with-Keycloak) documentation.

## Download Keycloak IdP Metadata
1. Login to the Keycloak Admin Console i.e. <KeycloakURL>/auth/admin/master/console/
2. From the left-side menu, click on *Realm Settings*.
3. From the General tab, right-click on SAML 2.0 Identity Provider Metadata under the Endpoints field and save the link/file locally. This is the Keycloak IdP metadata that will be needed when configuring NXRM/IQ.

## Configure Users and Groups in Keycloak
4. To add groups, via the left-side menu, under *Manage*, select *Groups* and then *New*.
5. In the next screen enter a group name and select *Save*. This will create a group that will be used for role mapping on the NXRM/IQ side.
6. To add users, via the left-side menu, under *Manage*, select *Users* and then *Add user*.
7. In the next screen, enter a *username*, First Name, Last Name* and *Email*, then click *Save*.
8. Once saved, the user will be created but will not have a default password set or be assigned to any groups. To set the password, click on the *Credentials* tab, set a password and click *Reset Password*.
9. To add the user to a group, click on the Groups tab and from the *Available Groups* field enter the name of the group created in Step 5 and click *Join*.


## NXRM Configuration
```
# values.yaml
sso:
  enabled: false
  idp_data:
    entityId: "{{ base_url }}/service/rest/v1/security/saml/metadata"
    usernameAttribute: "username"
    firstNameAttribute: "firstName"
    lastNameAttribute: "lastName"
    emailAttribute: "email"
    groupsAttribute: "groups"
    validateResponseSignature: true
    validateAssertionSignature: true
    idpMetadata: 'string'
  realm:
    - "NexusAuthenticatingRealm"
    - "NexusAuthorizingRealm"
    - "SamlRealm"
  role:
    id: "nexus"
    name: "nexus"
    description: "nexus group"
    privileges:
      - "nx-all"
    roles:
      - "nx-admin"

# Retrieve a list of all available privileges:
# curl -X GET "https://{{ base_url }}/service/rest/v1/security/privileges" -H "accept: application/json"
```

10. Obtain a copy of the NXRM 3 SAML Metadata by opening the Entity ID URI i.e. <NXRMBaseURL>/service/rest/v1/security/saml/metadata and saving the XML to file

## Configure Keycloak - Client Config and Attribute Mapping
11. Further to configuring the NXRM/IQ side, to import the NXRM or IQ SAML metadata into Keycloak, via the Keycloak Admin Console select Clients from the left-side menu, then click *Create*.
12. In the Add Client screen, click *Select file* from the Import field, upload the NXRM or IQ SAML metadata that was obtained when configuring the NXRM/IQ side and click *Save*.
13. After saving, in the next screen, for the Client SAML Endpoint field, enter the Nexus instance*s Assertion Consumer Service (ACS) URL i.e. <NXRMBaseURL>/saml for NXRM 3 or <IQBaseURL>/saml for Nexus IQ Server and click *Save*.
14. If in the Configure Nexus Applications section, the *Validate Response Signature* and *Validate Assertion Signature* fields are set to "Default" or "True", then in the Clients → Settings tab ensure that the *Sign Documents* and *Sign Assertions* fields are enabled.

Once the client has been created and the Client SAML Endpoint has been set, an attribute for each of the mappable fields that were configured in the Configure Nexus Applications section i.e. username, firstName, lastName, email and groups, will need to be created.

15. To map an attribute, select the Mappers tab and then click on 'Create'.
16. Create a mapper for each of the mappable attributes with the values shown here:

**Note: You must turn off `Full group path` when generating the `groups` mapper.**

  | Name        | Mapper Type   | Property  | Friendly Name | SAML Attribute Name | SAML Attribute NameFormat |
  |-------------|---------------|-----------|---------------|---------------------|---------------------------|
  | username    | User Property | username  | username      | username            | Basic                     |
  | First Name  | User Property | firstName | firstName     | firstName           | Basic                     |
  | Last Name   | User Property | lastName  | lastName      | lastName            | Basic                     |
  | Email       | User Property | email     | email         | email               | Basic                     |
  | Groups      | Group list    | groups    | groups        | *N/A*               | Basic                     |

17. FINAL NOTE: If your Keycloak client is already configured but you have a new Nexus deployment you must update the Nexus x509 certificate in the Keycloak client.
  - get new Nexus x509 cert from Nexus Admin UI after logging in as ```admin``` user  
      https://nexus.bigbang.dev/service/rest/v1/security/saml/metadata
  - copy and paste the single line cert into a text file
      ```
      vi nexus-x509.txt
      -----BEGIN CERTIFICATE-----
      paste single line Nexus x509 certificate here 
      -----END CERTIFICATE-----
      ```
  - make a valid pem file with proper wrapping at 64 characters per line
      ```
      fold -w 64 nexus-x509.txt > nexus.pem
      ```
  - in Keycloak Nexus client on the ```Keys``` tab import the nexus.pem file in two places, ```the Signing Key``` and the ```Encryption Key```
