# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [1.0.0-bb.3] - 2022-01-28

### Added

- update-image-pull-policy policy
- cve-disallow-subpath-volumes policy
- remove-token-automount policy
- require-annotations policy
- require-image-signature
- require-istio-on-namespaces policy
- require-istio-on-pods policy
- require-labels policy
- restrict-annotations policy
- restrict-labels policy
- restrict-pod-exec policy
- restrict-tolerations policy
- max. on cpu and memory limits in restrict-cpu-limits and restrict-memory-limits policies
- Gatekeeper policy vs. Kyverno policy documentation
- Policy description documentation

### Changed

- require-resource-limits split into restrict-cpu-limits and restrict-memory-limits policies
- Added timestamp to wait-for-ready job so upgrades do not try to change immutable job.

### Removed

- cve-add-log4j2-mitigation policy (Mitigation proved to be insufficient)

## [1.0.0-bb.2] - 2022-01-14

### Added

- cve-restrict-external-names policy
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
- Updated disallow-selinux to restrict-selinux in accordance with Pod Security Standards

## [1.0.0-bb.1] - 2021-12-20

### Added

- cve-restrict-external-ips policy
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
- restrict-image-tags policy
- restrict-proc-mount policy
- restrict-seccomp policy
- restrict-sysctls policy
- restrict-user-id policy
- restrict-volume-types policy

## [1.0.0-bb.0] - 2021-12-2

### Added

- Initial creation of the chart
