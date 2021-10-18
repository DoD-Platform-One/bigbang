# Big Bang Package: Policy Enforcement

Big Bang has several policies for Kubernetes resources to ensure best practices and security.  For example, images must be pulled from Iron Bank, or containers must be run as non-root.  These policies are currently enforced by [OPA Gatekeeper](https://repo1.dso.mil/platform-one/big-bang/apps/core/policy), which gets deployed as the first package in Big Bang.

When integrating your package, you must adhere to the policies that are enforced or your resources will be denied by the Kubernetes admission controller.  The following is how to identify and fix policy violations.

## Prerequisites

TBD

## Integration

## Validation
