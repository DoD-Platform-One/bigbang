# Resource-constrained Configuration Example

The [example values file](../../reference/configs/appliance-mode/values.yaml) reduces package resource requests and disables selected capabilities for development or evaluation on a resource-constrained cluster.

This example is not a supported hardware minimum, production sizing recommendation, high-availability profile, or security baseline. Its capacity and package choices are not automatically updated when package requirements change.

Before using it:

1. Compare every override with the values and release notes for the selected Big Bang release.
2. Enable only the packages required for the evaluation.
3. Render the configuration and confirm that the cluster can schedule all requests.
4. Test storage, ingress, authentication, policy, and application behavior.
5. Build a separate capacity and availability plan before production use.

See [Resource Planning](../../getting-started/prerequisites.md#resource-planning) for production considerations.
