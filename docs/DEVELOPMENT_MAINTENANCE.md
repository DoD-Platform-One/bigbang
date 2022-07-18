# Upgrading to a new version

The below details the steps required to update to a new version of the Nexus package.

1. Read release notes from upstream [Nexus Releases](https://help.sonatype.com/repomanager3/product-information/release-notes). Be aware of changes that are included in the upgrade. Take note of any manual upgrade steps that customers might need to perform, if any.
1. Do diff of [upstream chart](https://github.com/sonatype/helm3-charts/tree/nexus-repository-manager-40.1.0/charts/nexus-repository-manager) between old and new release tags to become aware of any significant chart changes. A graphical diff tool such as [Meld](https://meldmerge.org/) is useful. You can see where the current helm chart came from by inspecting ```/chart/kptfile```
1. Create a development branch and merge request from the Gitlab issue.
1. Merge/Sync the new helm chart with the existing Nexus package code. A graphical diff tool like [Meld](https://meldmerge.org/) is useful. Reference the "Modifications made to upstream chart" section below. Be careful not to overwrite Big Bang Package changes that need to be kept. Note that some files will have combinations of changes that you will overwite and changes that you keep. Stay alert. The hardest file to update is the ```/chart/values.yaml``` because the changes are many and complicated.
1. Delete all the ```/chart/charts/*.tgz``` files. You will replace these files in a later step.
1. update gluon to the latest version, tgz the chart directory from [here](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/tags) and place new chart in ```/chart/charts/xxx.tgz```
1. In ```/Chart.yaml``` update the gluon library dependency to the latest version that you .
1. Modify the `image.tag` value in `chart/values.yaml` to point to the newest version of Nexus.
1. Update /chart/Chart.yaml to the appropriate versions. The annotation version should match the ```appVersion```.
    ```yaml
    version: X.X.X-bb.X
    appVersion: X.X.X
    annotations:
    annotations:
      bigbang.dev/applicationVersions: |
        - Gitlab: X.X.X
    ```
1. Update `CHANGELOG.md` adding an entry for the new version and noting all changes (at minimum should include `Updated Nexus to x.x.x`).
1. Generate the `README.md` updates by following the [guide in gluon](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-package-readme.md).
1. Open an MR in "Draft" status and validate that CI passes. This will perform a number of smoke tests against the package, but it is good to manually deploy to test some things that CI doesn't. 
1. Once all manual testing is complete take your MR out of "Draft" status and add the review label.

# How to test Nexus
Note that Big Bang has added several CaC jobs to automate certain configurations that the upstream Nexus is not aware of. Nexus upgrades could break the CaC jobs. You need a license to test the SSO job. The CaC job for repo creation might also require a license, not sure. Currently waiting for license from aquisitions. You can request a one-time trial license from the [Nexus website](https://www.sonatype.com/products/repository-pro/trial) if you register an account with your email. Deploy with the following Big Bang values with SSO disabled. 
```
domain: bigbang.dev

flux:
  interval: 1m
  rollback:
    cleanupOnFail: false


networkPolicies:
  enabled: true

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
  enabled: false

twistlock:
  enabled: false
  values:
    console:
      persistence:
        size: 5Gi

# Gloabl SSO parameters
sso:
  oidc:
    host: keycloak.bigbang.dev
    realm: baby-yoda
  client_secret: ""

addons:

  metricsServer:
    enabled: false

  nexus:
    enabled: true

    git:
      tag: null
      branch: "name-of-your-development-branch"

    # -- Base64 encoded license file.
    # cat ~/Downloads/sonatype-license-XXXX-XX-XXXXXXXXXX.lic | base64 -w 0 ; echo
    license_key: ""
    ingress:
      gateway: "public"
    sso:
      # -- https://support.sonatype.com/hc/en-us/articles/1500000976522-SAML-integration-for-Nexus-Repository-Manager-Pro-3-and-Nexus-IQ-Server-with-Keycloak#h_01EV7CWCYH3YKAPMAHG8XMQ599
      enabled: false
      idp_data:
        entityId: "https://nexus.bigbang.dev/service/rest/v1/security/saml/metadata"
        # -- IdP Field Mappings
        # -- NXRM username attribute
        username: "username"
        firstName: "firstName"
        lastName: "lastName"
        email: "email"
        groups: "groups"
        # -- IDP SAML Metadata XML as a single line string in single quotes
        # -- this information is public and does not require a secret
        # curl https://keycloak.bigbang.dev/auth/realms/baby-yoda/protocol/saml/descriptor ; echo
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
    values:
      nexus:
        repository:
          enabled: true
```
To test with SSO enabled you will need your own deployment of Keycloak because you must change the client settings. This cannot be done with P1 login.dso.mil because we obviously don't have admin priveleges to change config. For instructions to set up your own Keycloak see the corresponding DEVELOPMENT_MAINTENANCE.md testing instructions in the Keycloak Package. Then you need to perform the following steps.
1. get nexus x509 cert from Nexus Admin UI
   https://nexus.bigbang.dev/service/rest/v1/security/saml/metadata
1. copy and paste the nexus single line cert into a text file and save it
     ```bash
     vi nexus-x509.txt
     ```
     add the following content
     ```console
     -----BEGIN CERTIFICATE-----
     put-single-line-nexus-x509-certificate-here
     -----END CERTIFICATE-----
     ```
1. make a valid pem file with proper wrapping at 64 characters per line
     ```bash
     fold -w 64 nexus-x509.txt > nexus.pem
     ```
1. In Keycloak go to the nexus client and on the Keys tab import the nexus.pem file in two places

Extra Credit: You can also deploy logging and monitoring and verify that they are still working.


# Modifications made to upstream chart
This is a high-level list of modifitations that Big Bang has made to the upstream helm chart. You can use this as as cross-check to make sure that no modifications were lost during an upgrade process.

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

## chart/templates/configmap.ymal
- fix extraLabels indentation to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)

## chart/templates/deployment.ymal
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

## chart/templates/deployment.ymal
- line 1 add conditional for not istio.enabled
- fix extraLabels indentation in 2 places to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)

## chart/templates/pv.ymal
- fix extraLabels indentation to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)

## chart/templates/pvc.ymal
- fix extraLabels indentation to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)

## chart/templates/secret.yaml
- delete secret file. It was moved to chart/templates/bigbang/ to handle CaC for admin password

## chart/templates/service.yaml
- fix extraLabels indentation in 2 places to avoid templating errors with helm, fluxcd, etc.
  reference original [commit](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus/-/commit/cbdc94fbb2baffce8871ae8d4540e54532ec6944)
- fix istio port name "http-nexus-ui"

## chart/templates/serviceaccount.ymal
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