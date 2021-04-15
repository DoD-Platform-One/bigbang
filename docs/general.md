# NXRM Storage, Database, and High Availability

## Storage
## Blob Store
Can be a shared file system or a cloud object store.

[Blob Stores](https://help.sonatype.com/repomanager3/high-availability/configuring-blob-stores)

### Recommended Shared File Systems
- NFS v4
- AWS EFS
- AWS S3

## Database
Nexus 3 uses builtin DB OrientDB for holding metadata and pointers for blob objects.

## High Availability
Discussing with Sonatype to ensure their HA-C solution is compatible with our deployment.

The upstream charts have the replica count hard-coded to `1`, possibly due to a limitation.

## Monitoring Node Health
NXRM provides two endpoints to monitor health status. Success is represented as `HTTP 200 OK`, failure is represented  
as `HTTP 503 SERVICE UNAVAILABLE`.

- `http://<hostname>:<port>/service/rest/v1/status`
Verifies that a node can handle read requests.

- `http://<hostname>:<port>/service/rest/v1/status/writable`
Verifies that a node can handle read and write requests.

