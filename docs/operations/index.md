# Operations

This section covers day-to-day operation of a Big Bang deployment that's already running — monitoring, backup and recovery, upgrades, and troubleshooting. It does not cover initial deployment; see [Getting Started](../getting-started/index.md) for that.

## What You'll Find Here
 
Operating a running deployment breaks down into three areas:
 
- **Day-to-day operations** — cluster health, through monitoring.
- **Lifecycle management** — data protection through backup and restore, and moving through Big Bang's two-week release cadence via planned upgrades.
- **Issue resolution** — troubleshooting guides organized by symptom, not by component, so you start from what you're observing

## Find the Right Starting Point

| Your goal | Start here |
| --- | --- |
| Set up observability and alerting | [Monitoring](monitoring.md) — put this in place before an incident, not during one |
| Protect your data | [Backup and Restore](backup-restore.md) — and actually test the restore, not just the backup |
| Upgrade Big Bang or a package | [Upgrades](upgrades.md) — plan your cadence deliberately; Big Bang releases every two weeks |
| Automate dependency updates | [Maintenance](maintenance/index.md), including [Renovate](maintenance/renovate.md) |
| Diagnose a specific problem | [Troubleshooting](troubleshooting/index.md) — worth a skim before you need it, organized by symptom: [installation](troubleshooting/installation.md), [networking](troubleshooting/networking.md), [packages](troubleshooting/packages.md), [performance](troubleshooting/performance.md), [upgrades](troubleshooting/upgrades.md) |