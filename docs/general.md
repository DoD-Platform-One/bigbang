# NXRM Storage, Database, and High Availability

## Blob Store

Can be a shared file system or a cloud object store.

[Blob Stores](https://help.sonatype.com/repomanager3/high-availability/configuring-blob-stores)

### Recommended Shared File Systems

- NFS v4
- AWS EFS
- AWS S3

## Database

Nexus 3 by default uses an embedded OrientDB for holding metadata and pointers
for the blob store, or you may elect to use an external database.

## External Database Support

Nexus 3 supports integration with an [external database](https://help.sonatype.com/repomanager3/installation-and-upgrades/configuring-nexus-repository-pro-for-h2-or-postgresql).

To enable external database support you must satisfy the following conditions:

- Pro license
- nexus.properties.override must be set to true
- Add a key value pair of `nexus.datastore.enabled: true` to `nexus.properties.data`
- Add a value for `custom_admin_password` and set in database
- A provisioned database, typically RDS or equivalent
- An understanding of migration steps relevant for your environment:
  - [Initial provision](https://help.sonatype.com/repomanager3/installation-and-upgrades/configuring-nexus-repository-pro-for-h2-or-postgresql)
  - [Database migration](https://help.sonatype.com/repomanager3/installation-and-upgrades/migrating-to-a-new-database)

Additionally, the following must be supplied in `nexus.env`:

```yaml
- name: NEXUS_DATASTORE_NEXUS_JDBCURL
  value: jdbc:postgresql://rds-hostname.us-east-1.rds.amazonaws.com:5432/nexus
- name: NEXUS_DATASTORE_NEXUS_USERNAME
  value: nexus
- name: NEXUS_DATASTORE_NEXUS_PASSWORD
   value: password
```

Please note - the randomized password generation does not support populating a
database password.
After the database is provisioned (via Terraform, for example), connect to the
database and follow [this document](https://support.sonatype.com/hc/en-us/articles/213467158-How-to-reset-a-forgotten-admin-password-in-Nexus-3-x)
to create the admin user and password. Ensure the value is populated in
`custom_admin_password`.

```bash
# you can use the following pod to execute psql commands to interact with your database
kubectl exec -it -n gitlab deploy/gitlab-toolbox -c toolbox -- sh
$ psql -U USER -h HOSTNAME
```

## High Availability

Discussing with Sonatype to ensure their HA-C solution is compatible with our deployment.

The upstream charts have the replica count hard-coded to `1`, possibly due to a limitation.

## Monitoring Node Health

NXRM provides two endpoints to monitor health status. Success is represented as
`HTTP 200 OK`, failure is represented as `HTTP 503 SERVICE UNAVAILABLE`.

- `http://<hostname>:<port>/service/rest/v1/status`

Verifies that a node can handle read requests.

- `http://<hostname>:<port>/service/rest/v1/status/writable`

Verifies that a node can handle read and write requests.
