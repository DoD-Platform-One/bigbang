# Keycloak SSO helm config

Modify your values.yaml to enable sso:
```
# SSO Additions
sso:
  enabled: true
  secret: secret
  id: platform1_a8604cc9-f5e9-4656-802d-d05624370245_bb8-mattermost
  authendpoint: https://login.dso.mil/oauth/authorize
  tokenendpoint: https://login.dso.mil/oauth/token
  userapiendpoint: https://login.dso.mil/api/v4/user
```
Example install:
```
helm upgrade -i mattermost chart -n mattermost --create-namespace -f tests/test-values.yml
```

# Keycloak SSO Kustomize config

Generate secret for client:
Go to Baby-Yoda realm
  1. Click on Clients
  2. Click on il2_00eb8904-5b88-4c68-ad67-cec0d2e07aa6_mattermost
  3. Click the credentials tab
  4. Press Regenerate Secret and copy it to clipboard

Create Mattermost secret
  1. Create sso-creds.env
  2. Edit sso-creds.env
  ```
  MM_GITLABSETTINGS_ENABLE="true"
  MM_GITLABSETTINGS_SECRET=OID_SECRET
  MM_GITLABSETTINGS_ID=OID_ID
  MM_GITLABSETTINGS_AUTHENDPOINT=OID_AUTH_ENDPOINT
  MM_GITLABSETTINGS_TOKENENDPOINT=OID_TOKEN_ENDPOINT
  MM_GITLABSETTINGS_USERAPIENDPOINT=OID_USERAPI_ENDPOINT
  ```
  3. Encrypt the variables.  This can be done with `sops -e sso-creds.env > sso-creds.enc.env`
  4. Remove the unecrypted `sso-creds.env` file.
  5. Add `sso-creds.enc.env` as kubernetes secret `sso-creds-generator.yaml`:
  ```
  ---
  # SSO configuration
  
  apiVersion: goabout.com/v1beta1
  kind: SopsSecretGenerator
  metadata:
    name: sso-secret
  disableNameSuffixHash: true
  envs:
    - sso-creds.enc.env
  ```
  6. Kustomize patch clusterinstallation.yaml with keyloak settings:
  ```
  apiVersion: mattermost.com/v1alpha1
  kind: ClusterInstallation
  metadata:
    name: chat
  spec:
    mattermostEnv:
    # Keycloak Settings
    - name: MM_GITLABSETTINGS_ENABLE
      valueFrom:
        secretKeyRef:
          name: sso-secret
          key: MM_GITLABSETTINGS_ENABLE
    - name: MM_GITLABSETTINGS_SECRET
      valueFrom:
        secretKeyRef:
          name: sso-secret
          key: MM_GITLABSETTINGS_SECRET
    - name: MM_GITLABSETTINGS_ID
      valueFrom:
        secretKeyRef:
          name: sso-secret
          key: MM_GITLABSETTINGS_ID
    - name: MM_GITLABSETTINGS_ID
      valueFrom:
        secretKeyRef:
          name: sso-secret
          key: MM_GITLABSETTINGS_ID
    - name: MM_GITLABSETTINGS_AUTHENDPOINT
      valueFrom:
        secretKeyRef:
          name: sso-secret
          key: MM_GITLABSETTINGS_AUTHENDPOINT
    - name: MM_GITLABSETTINGS_TOKENENDPOINT
      valueFrom:
        secretKeyRef:
          name: sso-secret
          key: MM_GITLABSETTINGS_TOKENENDPOINT
    - name: MM_GITLABSETTINGS_USERAPIENDPOINT
      valueFrom:
        secretKeyRef:
          name: sso-secret
          key: MM_GITLABSETTINGS_USERAPIENDPOINT
  ```
  In Kustomization.yaml
  ```
  patchesStrategicMerge:
  - clusterinstallation.yaml
  ```
Mattermost is now configured to use keycloak for SSO.  Any baby-yoda realm users created from the keycloak Admin Console will need
a mattermostid attribute added to their user.  Users who register throuh an invite link or with a CAC will automatically had this
id generated.

Add mattermostid to user
  1. Login to keycloak Admin Console with the master realm user created above
  1. Go to the baby-yoda realm 
  1. Go to the users section and edit the user you created in the baby-yoda realm
  1. Go to the Attributes tab
  1. In the bottom row type `mattermostid` in the key and a random number in the `value` field.
  1. Click Add.

This mattermostid needs to be unique per user, so it's a bad idea to generate these by hand.  The registration process will
automatically generate these for users, but in the case that you generated a test user it can be handy to add a mattermostid.