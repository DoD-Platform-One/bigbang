# Big Bang Package Architecture Review

- Big Bang to Package touch points / interactions - does the package have a GUI, storage needs, logging, monitoring, health checks, etc
- HA - What is required for HA
- SSO - does the package have SSO, is it a licensed feature, if not - is there a strategy to provide rudimentary SSO capability vis AuthService?
- Licensing - describe the licensing model and any tiers of capability that are impacted
- Storage - describe any package specific storage or database requirements
- Dependent packages - list any included dependent packages that will not be elevated to a BB Addon
