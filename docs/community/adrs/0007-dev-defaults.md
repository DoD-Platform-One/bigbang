# 7. Package Development Defaults

Date: 2025-07-07

## Status

Accepted

## Context

Big Bang faces an inherent tension between two competing goals: being secure and production-ready versus being accessible and easy to evaluate. As a DoD-focused platform, security is paramount, but overly restrictive defaults can create significant barriers to adoption and development.

Currently, many Kubernetes platforms and security tools default to production-hardened configurations that require extensive setup before achieving a working deployment. This approach, while secure, presents several challenges:

1. **High barrier to entry**: New users cannot quickly evaluate Big Bang's capabilities without significant configuration effort
2. **Slow development cycles**: Developers working on Big Bang packages need lightweight environments for rapid iteration
3. **Complex prerequisites**: Production defaults often require external dependencies (identity providers, certificate authorities, object storage) that aren't available in development environments
4. **Evaluation friction**: Teams considering Big Bang adoption need a low-effort path to test its features and assess fit

The community needs a clear philosophy on how Big Bang approaches this balance between security and usability in its default configuration.

## Decision

Big Bang will adopt a "development-friendly by default, production-ready by configuration" philosophy for its package defaults.

This means:

1. **Default values prioritize initial deployment success** over production hardening. The out-of-the-box experience should result in a functional, near production-ready, deployment.

2. **Production readiness is achieved through explicit configuration**, not defaults. Users deploying to production environments are expected to override defaults with appropriate values for their security and operational requirements.

3. **Clear differentiation between development and production** configurations will be maintained through documentation, examples, and tooling. The project will explicitly communicate which defaults are unsuitable for production use.

4. **Development defaults should still demonstrate security features**, just in a more accessible way. For example, authentication might be enabled but use simple defaults rather than requiring external identity provider configuration.

5. **The definition of "development-friendly" includes**:
   - Minimal external dependencies
   - Reduced resource requirements where appropriate
   - Simplified authentication and authorization
   - Pre-configured integrations between Big Bang components
   - Reasonable timeouts and intervals for faster feedback

This philosophy applies to both Big Bang's core configuration and the defaults used in individual package integrations.

## Consequences

### Positive

- **Lower barrier to entry**: New users can deploy and explore Big Bang with minimal configuration
- **Faster development iteration**: Package developers and contributors can quickly test changes
- **Improved evaluation experience**: Teams can assess Big Bang's value before investing in production configuration
- **Clearer mental model**: The distinction between development and production deployments becomes more explicit
- **Better alignment with user journey**: Supports the natural progression from evaluation to development to production

### Negative

- **Security risk if misused**: Development defaults could inadvertently be used in production environments
- **Additional documentation burden**: Must clearly communicate which settings need adjustment for production
- **Potential for misconceptions**: Users might incorrectly assume defaults are production-appropriate
- **Maintenance overhead**: Need to ensure development defaults remain functional as packages evolve

To mitigate these risks, Big Bang will:
- Provide clear warnings in documentation about development versus production configurations
- Call out production considerations in package documentation
- Include comments in values overlays where development defaults have been chosen in lieu of a more production-like configuration
  - Reasoning for the choice should be documented
  - Comments should include links to documentation when possible
