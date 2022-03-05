# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [1.0.0-bb.7] - 2022-03-03

### Changed

- Renamed `disallow-default-namespace` to `disallow-namespaces`.  Parameterized list of disallowed namespaces, with `default` as the default.
- Decoupled testing from namespace
- Used default namespace for testing
- Updated test script to set policy action automatically

## [1.0.0-bb.6] - 2022-03-02

### Changed

- Added `localhost/*` as another acceptable default AppArmor profile
- Updated metadata in `Chart.yaml`
- Fixed typo for `restrict-capabilities` action in `values.yaml`
- Fixed `disallow-default-namespace` to allow blank namespace in pod controller template, but require pod controller to have a namespace.
- Fixed `restrict-host-path` to ignore pods with no volumes
- Fixed `require-non-root-group` exclusions indentions
- Fixed `disallow-deprecated-apis` matching to work with exclusions
- Updated `disallow-deprecated-apis` with Kubernetes 1.26 deprecations
- Updated `require-requests-equal-limits` to work with Kyverno 1.6.0
- Add `system:service-account-issuer-discovery` to the exclusion list for `disallow-rbac-on-default-serviceaccounts`.  Clusters allow service accounts access to discovery.
- Fixed `disallow-rbac-on-default-serviceaccounts` to ignore role bindings without a subject.
- Fixed `require-non-root-user` to allow either `runAsNonRoot: true` or `runAsUser: >0`.
- Fixed `disallow-tolerations` to check pod controllers
- Renamed `require-ro-host-path` to `restrict-host-path-write` and added an `allow` list for paths
- Renamed `restrict-host-path` to `restrict-host-path-mount` to distinguish from `restrict-host-path-write`
- Increased memory allocation for `wait-for-ready` job to avoid OOM errors
- Renamed `disallow-subpath-volumes` to `disallow-shared-subpath-volume-writes` to clarify functionality.
- Fixed `disallow-shared-subpath-volume-writes` to narrow conditions specific to vulnerability
- Fixed `helpers.tpl` match and exclusion to handle `any` and `all` permutations

### Added

- `wait.sh` added to pipeline to wait for all policies to be ready before running helm test

### Removed

- `disallow-host-path` policy overlapped `restrict-volume-types` policy and was removed

## [1.0.0-bb.5] - 2022-02-03

### Changed

- Updated kubectl to 1.22
- Removed version from UBI image in most test resources (latest is ok)

## [1.0.0-bb.4] - 2022-01-31

### Changed

- Updated policy names and parameters to be inline with `docs/naming.md`
- Split restrict-selinux policy into restrict-selinux-type and disallow-selinux-options policies

## [1.0.0-bb.3] - 2022-01-28

### Added

- update-image-pull-policy policy
- disallow-subpath-volumes policy
- update-token-automount policy
- require-annotations policy
- require-image-signature
- require-istio-on-namespaces policy
- disallow-istio-injection-bypass policy
- require-labels policy
- disallow-annotations policy
- disallow-labels policy
- disallow-pod-exec policy
- disallow-tolerations policy
- max. on cpu and memory limits in require-cpu-limits and require-memory-limits policies
- Gatekeeper policy vs. Kyverno policy documentation
- Policy description documentation

### Changed

- require-resource-limits split into require-cpu-limits and require-memory-limits policies
- Added timestamp to wait-for-ready job so upgrades do not try to change immutable job.

### Removed

- cve-add-log4j2-mitigation policy (Mitigation proved to be insufficient)

## [1.0.0-bb.2] - 2022-01-14

### Added

- restrict-external-names policy
- disallow-host-path policy
- disallow-nodeport-services policy
- disallow-rbac-on-default-serviceaccounts policy
- require-drop-all-capabilities policy
- require-labels policy
- require-probes policy
- require-requests-equal-limits policy
- require-resource-limits policy
- require-ro-host-path policy
- restrict-host-path policy

### Changed

- Simplified restrict-capabilities policy
- Updated disallow-selinux to restrict-selinux-type in accordance with Pod Security Standards

## [1.0.0-bb.1] - 2021-12-20

### Added

- restrict-external-ips policy
- disallow-host-namespace policy
- disallow-default-namespace policy
- disallow-privilege-escalation policy
- disallow-privileged-containers policy
- disallow-selinux policy
- require-non-root-group policy
- require-non-root-user policy
- require-ro-rootfs policy
- restrict-apparmor policy
- restrict-group-id policy
- restrict-host-ports policy
- restrict-image-registries policy
- disallow-image-tags policy
- restrict-proc-mount policy
- restrict-seccomp policy
- restrict-sysctls policy
- restrict-user-id policy
- restrict-volume-types policy

## [1.0.0-bb.0] - 2021-12-2

### Added

- Initial creation of the chart
