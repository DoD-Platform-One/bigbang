# Maintenance

Today, Renovate is the only maintenance task covered here. Bug fixes are tracked and labeled separately — see [Big Bang work items](https://repo1.dso.mil/big-bang/bigbang/-/work_items).

Every Big Bang package repository is created from a shared template containing a default `renovate.json`, so within Big Bang's own package ecosystem, Renovate is on by default for any repository with that file — it's automatically included in Big Bang's nightly Renovate run. New packages still need package-specific configuration added on top of the template's defaults.
 
If you deploy the Renovate package in your own environment, this auto-inclusion doesn't apply — you'll need to configure which repositories to include yourself. See [Renovate](renovate.md) for details.
 
- For deploying or configuring Renovate in your own environment, see [Renovate](renovate.md).
- For the common review, testing, and merge process that applies across all packages, see [Renovate Package Maintenance](renovate-maintenance.md).
- For a specific package's own configuration and caveats, see that package's `DEVELOPMENT_MAINTENANCE.md` in its repository.