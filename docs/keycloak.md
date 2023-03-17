# Keycloak SSO Mattermost Config

## Keycloak Client Setup

The Keycloak client can be set up by following [this tutorial](https://medium.com/@mrtcve/mattermost-teams-edition-replacing-gitlab-sso-with-keycloak-dabf13ebb99e). A summary is provided below, but if there are any issues refer to the source linked.

Create client:
- client id - you pick, "mattermost"
- enabled - on
- client protocol - openid-connect
- access type - confidential
- standard flow enabled - on
- valid redirect URIs - "{mattermosturl}/signup/gitlab/complete"

Under the mappers tab, create a new mapper:
- name - mattermostId
- mapper type - user attribute
- user attribute - mattermostId
- token claim name - id
- claim JSON type - long
- add to userinfo - on

Create username mapper:
- name - username
- mapper type - user property
- property - username
- token claim name - username
- claim JSON type - string
- add to userinfo - on
- all other sliders off

Create email mapper:
- name - email
- mapper type - user property
- property - email
- token claim name - email
- claim JSON type - string
- add to userinfo - on
- all other sliders off

Add mattermostid to existing user:
- Login to keycloak Admin Console with the master realm user
- Go to your realm
- Go to the users section and edit the user
- Go to the Attributes tab
- In the bottom row type `mattermostId` in the key and a random number in the `value` field.
- Click Add.

This mattermostid needs to be unique per user, so it's a bad idea to generate these by hand.  This process is just a way to edit test/existing users.

## Helm Values

First get the values you need for your Keycloak:
- client_id: This is the client id you created and picked earlier
- client_secret: This is under the credential tab for your client, you can click regenerate and then copy it
- endpoints: Go to your realm settings and then open the "OpenID Endpoint Configuration". There should be values for authorization_endpoint, token_endpoint, and userinfo_endpoint which correspond to the auth, token, and user_api endpoints in the values.

Modify your values.yaml according to these example values to enable Gitlab Auth provider for SSO. If you have a licensed version of Mattermost that supports OIDC the Mattermost OIDC client backend will obtain the endpoints automatically from the [well-known OIDC endpoint](https://login.dso.mil/auth/realms/baby-yoda/.well-known/openid-configuration).
```
# SSO Additions
sso:
  enabled: true
  client_id: platform1_a8604cc9-f5e9-4656-802d-d05624370245_bb8-mattermost
  client_secret: nothing # Change to your Keycloak client secret
  auth_endpoint: https://login.dso.mil/auth/realms/baby-yoda/protocol/openid-connect/auth
  token_endpoint: https://login.dso.mil/auth/realms/baby-yoda/protocol/openid-connect/token
  user_api_endpoint: https://login.dso.mil/auth/realms/baby-yoda/protocol/openid-connect/userinfo

```

Example install:
```
helm upgrade -i mattermost chart -n mattermost --create-namespace -f my-values.yml
```

## Role Based Authentication

Role based authentication can be configured as long as you are on an enterprise version.

Follow the steps in [this tutorial](https://docs.mattermost.com/deployment/advanced-permissions.html) to customize the permissions given to users. In general permissions can be edited under the "System Console -> User Management -> Permissions". Users should be created by default under the "Member" group, except for the first user to sign up or login.

## OIDC Custom CA

Mattermost can be configured to point to specific files to trust with an OIDC auth connection, here is an example when using Big Bang to deploy mattermost, assuming you are populating a secret named "ca-cert" in the same namespace, with a key of cert.pem and value of a single PEM encoded certificate (an easy way to make this secret is included below as well):

```yaml
addons:
  mattermost:
    values:
      volumes:
        - name: ca-cert
          secret:
            secretName: ca-secret
            defaultMode: 0644
      volumeMounts:
        - name: ca-cert
          mountPath: /etc/ssl/certs
          readOnly: true
```

For secret creation with this example and a pem file at `/path/to/cert.pem`:
```bash
kubectl create secret generic ca-secret --from-file=cert.pem=/path/to/cert.pem -n mattermost
```
