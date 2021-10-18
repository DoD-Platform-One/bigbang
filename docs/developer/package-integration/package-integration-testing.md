# Big Bang Package: Testing

Usually, Helm charts come with a set of Helm tests that can be run to test the deployment of the application.  Big Bang requires some additional tests to verify integration is working as expected.  By adding additional tests, the goal is to verify that the package is functioning.  For example, we may want to validate that

- The HTTPS endpoint can be reached
- The admin user can login using the configured (or randomized) password
- A non-admin user can be created and can login
- Data can be stored and retrieved from the database
- Artifacts can be stored and retrieved from the object storage
- Interactions with other services/packages works

## Prerequisites

TBD

## Integration

## Validation
