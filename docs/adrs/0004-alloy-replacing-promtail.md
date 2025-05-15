# 4. Grafana Alloy replacing Promtail as core log collector

Date: 2025-04-25

## Status

Accepted

## Context

Grafana Promtail has served as our primary log collection agent, shipping logs to Loki for storage and aggregation. Grafana has announced that Promtail is now deprecated and moved to Long-Term Support (LTS) on February 13, 2025.

Grafana Labs will no longer be adding additional features to products in LTS, but will continue to provide fixes for critical bugs and security issues. At the time of writing (April 2025) Grafana anticipates LTS for Promtail will extend until February 28, 2026 at which point Promtail will move to end-of-life (EOL) and will stop receiving updates entirely.

Grafana Labs has officially announced Promtail's deprecation in favor of Grafana Alloy, which serves as their next-generation collector built on top of [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/).

If customers have any custom Promtail configurations they want to make available to Alloy, they will need to follow Grafana's recommended upgrade path to convert Promtail configurations to Alloy compatible configurations:

`alloy convert --source-format=promtail --output=<OUTPUT_CONFIG_PATH> <INPUT_CONFIG_PATH>`

Source: [Grafana Docs - Migrate from Promtail to Grafana Alloy](https://grafana.com/docs/alloy/latest/set-up/migrate/from-promtail/)

For additional context on Grafana Labs' decision to migrate to Alloy we recommend the following posts:
 - [Grafana Labs Blog](https://grafana.com/blog/2025/02/13/grafana-loki-3.4-standardized-storage-config-sizing-guidance-and-promtail-merging-into-alloy/?camp=blog&cnt=Grafana+Loki+3.4+is+here%21&mdm=social&src=li)
 - [Promtail Documentation](https://grafana.com/docs/loki/latest/send-data/promtail/)


### Migration Timeline

| Milestone | Date | Description |
|-----------|------|-------------|
| 2.50.00 | Q1 2025 | Promtail deprecation notice started being included in release notes, Alloy moved to individual namespace | 
| 2.51.00 | Q1 2025 | Alloy-logging features added to Big Bang, Promtail deprecation warning added to NOTES.txt |
| 2.53.00 | Q2 2025 | Alloy moved to Big Bang "core" values, removed from addons | 
| 3.00.00 | Q2 2025 | Alloy with alloy-logs enabled by default, Promtail disabled by default |
| 3.05.00 | Q2 2025 | Promtail removed from Big Bang charts, Promtail repository migrated to `community` | 

## Decision

We will replace Grafana Promtail with Grafana Alloy as our primary log collection agent. This transition will be implemented according to the following guidelines:

1. The Big Bang 3.0 release will come preset with Alloy and alloy-logs features enabled, with Promtail disabled.
2. Promtail will not be removed from Big Bang until the 3.05 release, or later, giving customers ample time to convert their configurations using Grafana Labs' provided path.
3. Alloy will be enabled with capabilities that are equivalent to the current Promtail setup.

## Consequences

### Positive 

1. Future-proofing: Moving to Grafana's actively supported collector ensures continued updates and security patches beyond February 2026.
2. Unified telemetry: Alloy provides a single agent for logs, metrics, and traces, simplifying observability architecture.
3. OpenTelemetry alignment: Aligns our observability stack with industry standards and the OpenTelemetry ecosystem.

### Negative

1. Migration effort: Customers with custom Promtail configurations will need to convert and test their setups with Alloy.
2. Learning curve: Technical staff will need to familiarize themselves with Alloy's configuration model and capabilities.
3. Potential configuration gaps: The automated conversion tool may not handle all edge cases, requiring manual intervention.