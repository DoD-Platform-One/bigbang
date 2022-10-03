# Upgrading to a new version

The below details the steps required to update to a new version of the Nexus package.

1. Read release notes from upstream [Nexus Releases](https://help.sonatype.com/repomanager3/product-information/release-notes). Be aware of changes that are included in the upgrade. Take note of any manual upgrade steps that customers might need to perform, if any.
1. Do diff of [upstream chart](https://github.com/sonatype/helm3-charts/tree/nexus-repository-manager-40.1.0/charts/nexus-repository-manager) between old and new release tags to become aware of any significant chart changes. A graphical diff tool such as [Meld](https://meldmerge.org/) is useful. You can see where the current helm chart came from by inspecting ```/chart/kptfile```
1. Create a development branch and merge request from the Gitlab issue.
1. Merge/Sync the new helm chart with the existing Nexus package code. A graphical diff tool like [Meld](https://meldmerge.org/) is useful. Reference the "Modifications made to upstream chart" section below. Be careful not to overwrite Big Bang Package changes that need to be kept. Note that some files will have combinations of changes that you will overwrite and changes that you keep. Stay alert. The hardest file to update is the ```/chart/values.yaml``` because the changes are many and complicated.
1. In `chart/Chart.yaml` update gluon to the latest version and run `helm dependency update chart` from the top level of the repo to package it up.
1. Modify the `image.tag` value in `chart/values.yaml` to point to the newest version of Nexus.
1. Update `chart/Chart.yaml` to the appropriate versions. The annotation version should match the ```appVersion```.
    ```yaml
    version: X.X.X-bb.X
    appVersion: X.X.X
    annotations:
      bigbang.dev/applicationVersions: |
        - Nexus: X.X.X
    ```
1. Update `CHANGELOG.md` adding an entry for the new version and noting all changes (at minimum should include `Updated Nexus to x.x.x`).
1. Generate the `README.md` updates by following the [guide in gluon](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-package-readme.md).
1. Open an MR in "Draft" status and validate that CI passes. This will perform a number of smoke tests against the package, but it is good to manually deploy to test some things that CI doesn't.
1. Once all manual testing is complete take your MR out of "Draft" status and add the review label.

# How to test Nexus

Big Bang has added several CaC (config as code) jobs to automate certain configurations that the upstream Nexus Helm chart does not support. Nexus upgrades could break the CaC jobs (which are not currently tested in CI). Note that you will need a license to test the SSO job. The CaC job for repo creation does not require a license. Big Bang has a license for development/testing purposes - you can request this license from one of the CODEOWNERS or reach out via the BB team channel.

## Test Basic Functionality, Repo Job, and Monitoring

Deploy with the following Big Bang override values to test the repo job and monitoring interaction:

```yaml
clusterAuditor:
  enabled: false

gatekeeper:
  enabled: false

istiooperator:
  enabled: true

istio:
  enabled: true

jaeger:
  enabled: false

kiali:
  enabled: false

logging:
  enabled: false

eckoperator:
  enabled: false

fluentbit:
  enabled: false

monitoring:
  enabled: true

twistlock:
  enabled: false

addons:
  nexus:
    enabled: true
    git:
      tag: null
      branch: "name-of-your-development-branch"
    values:
      nexus:
        docker:
          enabled: true
          registries:
            - host: containers.bigbang.dev
              port: 5000
        repository:
          enabled: true
          repo:
            - name: "containers"
              format: "docker"
              type: "hosted"
              repo_data:
                name: "containers"
                online: true
                storage:
                  blobStoreName: "default"
                  strictContentTypeValidation: true
                  writePolicy: "allow_once"
                cleanup:
                  policyNames:
                    - "string"
                component:
                  proprietaryComponents: true
                docker:
                  v1Enabled: false
                  forceBasicAuth: true
                  httpPort: 5000
```

1. Log in as admin and run through the setup wizard to set an admin password and disable anonymous access.
1. Locally run `docker login containers.bigbang.dev` using the username `admin` and password that you setup. Make sure that you have added `containers.bigbang.dev` to your `/etc/hosts` file along with the other hostnames.
1. Locally run `docker tag alpine containers.bigbang.dev/alpine` (or tag a similar small image) then push that image with `docker push containers.bigbang.dev/alpine`. Validate the image pushes successfully which will confirm our repo job setup the docker repo.
1. Navigate to the Prometheus target page (https://prometheus.bigbang.dev/targets) and validate that the Nexus target shows as up.

## Test SSO Job

SSO Job testing will require your own deployment of Keycloak because you must change the client settings. This cannot be done with P1 login.dso.mil because we don't have admin privileges to change the config there.

Follow the instructions from the corresponding `DEVELOPMENT_MAINTENANCE.md` testing instructions in the Keycloak Package to deploy Keycloak. Then deploy Nexus with the following values (note the `idpMetadata` value must be filled in with your Keycloak's information and `license_key` from the license file):

```yaml
addons:
  nexus:
    enabled: true
    git:
      tag: null
      branch: "name-of-your-development-branch"
    # -- Base64 encoded license file.
    # cat ~/Downloads/sonatype-license-XXXX-XX-XXXXXXXXXX.lic | base64 -w 0 ; echo
    license_key: ""
    sso:
      enabled: true
      idp_data:
        entityId: "https://nexus.bigbang.dev/service/rest/v1/security/saml/metadata"
        username: "username"
        firstName: "firstName"
        lastName: "lastName"
        email: "email"
        groups: "groups"
        # Fill this in with the result from `curl https://keycloak.bigbang.dev/auth/realms/baby-yoda/protocol/saml/descriptor ; echo`
        idpMetadata: 'xxxxxxxxxxxxxxx'
      role:
        # id is the name of the Keycloak group (case sensitive)
        - id: "Nexus"
          name: "Keycloak Nexus Group"
          description: "unprivilaged users"
          privileges: []
          roles: []
        - id: "Nexus-Admin"
          name: "Keycloak Nexus Admin Group"
          description: "keycloak users as admins"
          privileges:
            - "nx-all"
          roles:
            - "nx-admin"
```

Once Nexus is up and running complete the following steps to properly configure the Keycloak client:

1. Get the Nexus x509 cert from Nexus Admin UI (after logging in as admin you can get this from https://nexus.bigbang.dev/service/rest/v1/security/saml/metadata inside of the `X509Certificate` XML section).
1. Copy and paste the Nexus single line cert into a text file and save it:
    ```bash
    vi nexus-x509.txt
    ```
    Add the following content
    ```console
    -----BEGIN CERTIFICATE-----
    put-single-line-nexus-x509-certificate-here
    -----END CERTIFICATE-----
    ```
1. Make a valid pem file with proper wrapping at 64 characters per line
     ```bash
     fold -w 64 nexus-x509.txt > nexus.pem
     ```
1. In Keycloak go to the Nexus client and on the Keys tab (https://keycloak.bigbang.dev/auth/admin/master/console/#/realms/baby-yoda/clients/f975a475-89c7-43bc-bddb-c9d974ff5ac3/saml/keys) import the nexus.pem file in both places, setting the archive format as Certificate PEM.

Return to Nexus and validate you are able to login via SSO.

# Modifications made to upstream chart
This is a high-level list of modifications that Big Bang has made to the upstream helm chart. You can use this as as cross-check to make sure that no modifications were lost during an upgrade process.

##  chart/charts/*.tgz
- add the gluon library archive from ```helm dependency update ./chart```

- commit the tar archives that were downloaded from the helm dependency update command. And also commit the requirements.lock that was generated.

## chart/templates/bigbang/*
- add istio VirtualService
- add ServiceMonitor
- add PeerAuthentication
- add NetworkPolicies
- add custom jobs for CaC: saml sso, license, repo, etc.

## chart/templates/test/*
- delete the upstream tests

## chart/templates/tests/*
- add templates for helm tests

## chart/templates/_helpers.tpl
- add definition for nexus.licenseKey
- add definition for nexus.defaultAdminPassword

## chart/templates/configmap-properties.yaml
- fix extraLabels indentation to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)
- add templating to handle CaC for license

## chart/templates/configmap.yaml
- fix extraLabels indentation to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)

## chart/templates/deployment.yaml
- fix extraLabels indentation to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)
- add extraLables to spec.template.metadata.labels
- add spec.template.spec.affinity
- add volumemount for nexus-data/etc
  not sure why this is needed.
  could have been trial code that was accidentally committed
  but upgrades fail if it is removed
- add volumemount for license
- add subPath to the secret volumemount
- add volume for license
- add volume for admin password
- add securityContext: '$.Values.nexus.containerSecurityContext` to containers:

## chart/templates/ingress.yaml
- fix extraLabels indentation in 2 places to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)

## chart/templates/pv.yaml
- fix extraLabels indentation to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)

## chart/templates/pvc.yaml
- fix extraLabels indentation to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)

## chart/templates/secret.yaml
- delete secret file. It was moved to chart/templates/bigbang/ to handle CaC for admin password

## chart/templates/service.yaml
- fix extraLabels indentation in 2 places to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)
- fix istio port name "http-nexus-ui"

## chart/templates/serviceaccount.yaml
- fix extraLabels indentation to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)

## chart/tests/cypress/*
- add cypress tests

##  chart/Chart.lock
- add the lock file from ```helm dependency update ./chart```

## chart/Chart.yaml
- changes for Big Bang version, gluon dependency, and annotations

## chart/Kptfile
- add Kptfile

## chart/values.yaml
- Big Bang additions at the top of the values file
- Replace image with Iron Bank image
- add imagePullSecret.name = private-registry
- add nexus.affinity
- add nexus.extraLabels
- add nexus.blobsttores
- add nexus.repository
- add fips option to nexus.env.value
- comment nexus.properties.data: nexus.scripts.allowCreation
- set nexus.resources: requests and limits
- set nexus.securityContext values
- set .Values.secret.enabled true for CaC with admin credentials
- added bbtests values to support cypress/script tests
