# Big Bang Storage Options Guide

This document provides guidance on storage options for Big Bang deployments, including:

- Cloud Service Provider (CSP) managed storage (recommended for production)
- Kubernetes PersistentVolume storage (CSP or on-prem CSI)
- Cloud-native object storage services (external or in-cluster)
- External storage services for Big Bang applications (e.g., GitLab, Mattermost, SonarQube)

> **Recommendation:** For production systems running in AWS, Azure, or GCP, prefer **CSP-managed storage services** wherever possible.  
> In-cluster storage solutions are most appropriate for dev/test environments. We recommend deploying storage external to the cluster stable, reliable upgrades to Big Bang apps.
>
> The Big Bang team validates supported applications against CSP database services (primarily AWS RDS). While Big Bang updates the versions of database dependencies in sub-charts, the Big Bang team does **not** validate the Big Bang upgrade path using those embedded database dependencies.  
>
> **Even in air-gapped environments, the Big Bang team recommends hosting databases (especially PostgreSQL) externally from the Kubernetes cluster where feasible**, to reduce risk and avoid coupling critical state to the lifecycle of the cluster.

---

## Storage Categories in Big Bang

Big Bang workloads typically require one or more of the following storage types:

### Block Storage (RWO)

Used for:

- Databases (when unavoidable in-cluster)
- Stateful app volumes (e.g., GitLab components)
- SonarQube data volumes

### File Storage (RWX)

Used for:

- Shared filesystem workloads
- Some legacy app patterns
- High-availability file shares

### Object Storage (S3-compatible)

Used for:

- Backups
- Artifacts
- GitLab object storage (LFS, uploads, packages, registry)
- Mattermost file storage
- Velero backups

---

## Recommended Approach (Production)

### In CSP environments (AWS, Azure, GCP)

Use:

- CSP CSI drivers for Kubernetes PersistentVolumes
- CSP-managed databases (RDS, Cloud SQL, etc.)
- CSP-managed object storage (S3, GCS, Azure Blob)
- CSP-managed file services where needed (EFS, Azure Files)

This reduces operational burden and improves:

- Availability
- Performance consistency
- Patch/upgrade responsibility
- Disaster recovery options

---

## Storage Guidance for Airgapped / Disconnected Environments

Air-gapped storage is most common when:

- You cannot use CSP-managed services
- You are running on-prem, bare metal, or tactical edge
- You are in IL4/IL5/IL6-style disconnected environments
- You need storage that works entirely inside the environment boundary

> **Important:** Air-gapped does not necessarily mean “everything must run inside Kubernetes.”  
> Where possible, **databases (especially PostgreSQL) should be hosted external to the cluster**, even if still inside the same air-gapped boundary (e.g., VM-based PostgreSQL, appliance storage, or a dedicated DB cluster).  
>
> The Big Bang team does not recommend in-cluster database hosting when an external option is feasible.

---

# 1. Kubernetes CSI Options (PersistentVolumes)

These options provide Kubernetes-native block and/or file volumes.

## CSP CSI Drivers (Recommended for Production in Cloud)

### AWS EBS CSI (Block / RWO)

- Best for most stateful workloads on EKS
- Easy to operate
- Strong integration with AWS
- Does **not** provide RWX (use EFS CSI for RWX)

### AWS EFS CSI (File / RWX)

- Shared file system for RWX workloads
- Often used for workloads requiring shared mounts

### Azure Disk CSI (Block / RWO)

- Default block storage for AKS
- Good for most stateful workloads

### Azure Files CSI (File / RWX)

- RWX support via SMB/NFS depending on configuration

### GCP Persistent Disk CSI (Block / RWO)

- Standard block storage for GKE

---

## In-Cluster CSI (Airgap / On-Prem)

### Rook + Ceph (Block + File + Object)

**Best fit for:** production-grade airgapped clusters with dedicated storage nodes.

Provides:

- RBD (block volumes / RWO)
- CephFS (file volumes / RWX)
- RGW (S3-compatible object storage)

**Pros:**

- Most complete storage platform for disconnected environments
- Mature ecosystem
- Strong performance when properly designed

**Cons:**

- Operational complexity
- Requires careful sizing and failure domain planning

---

### Longhorn (Block + RWX via NFS)

**Best fit for:** small-to-medium disconnected clusters, simpler operations.

**Pros:**

- Easy installation and UI
- Great day-2 operational experience
- Built-in backups and snapshot support

**Cons:**

- RWX typically implemented via NFS layer
- Not as scalable as Ceph for large clusters

---

### OpenEBS (Local PV / cStor / Mayastor)

**Best fit for:** teams that want composable storage and local PV patterns.

**Pros:**

- Flexible designs
- Strong for local PV patterns and high-performance setups

**Cons:**

- Operational model varies by engine
- Requires careful selection (not a single “one size fits all” solution)

---

### NFS CSI (External or In-Cluster NFS)

**Best fit for:** simple RWX needs in disconnected environments.

**Pros:**

- Very simple
- Easy to debug

**Cons:**

- Not ideal for performance-sensitive or HA requirements
- Often becomes a bottleneck

---

# 2. Object Storage (S3-Compatible)

Object storage is often required for:

- Velero backups
- GitLab object storage (recommended)
- Mattermost file storage
- Harbor registry storage (depending on design)

---

## Garage (S3-Compatible) — Recommended for In-Cluster Use

**Best fit for:** edge/distributed environments with object-first storage needs. Soon to be substituted for MinIO in Big Bang packages where S3 compatible storage is needed as a chart dependency.

**Pros:**

- Designed for distributed and failure-tolerant object storage
- Lightweight compared to Ceph

**Cons:**

- Less common in Kubernetes enterprise environments
- Operational maturity varies by organization

---

## Ceph RGW (via Rook-Ceph)

**Best fit for:** environments already using Ceph for PVs.

**Pros:**

- Consolidated storage platform (block + file + object)
- Good for larger deployments

**Cons:**

- More complex setup and operations than Garage
- Requires Ceph operational expertise

---

## MinIO (S3-Compatible) — Approaching EOL / Not Recommended

**Status:** MinIO is no longer maintained upstream and is expected to be removed from the Big Bang ecosystem.

MinIO may still be encountered in existing environments and can function as an S3-compatible endpoint, but it should be treated as a **legacy option**.

**Pros:**

- Widely used historically
- Well documented
- Works well for airgap

**Cons:**

- Approaching EOL in the Big Bang ecosystem
- Not recommended for new deployments
- Requires operational ownership (upgrades, monitoring, disks)

> **Guidance:** Do not choose MinIO for new Big Bang deployments. Prefer **Garage** or **Ceph RGW** for in-environment object storage.

---

# 3. External Storage Options for Big Bang Applications (Recommended)

Many Big Bang apps support externalizing their storage dependencies. This is strongly recommended in production cloud environments and is also preferred in air-gapped environments when feasible.

---

## Common External Storage Services

### Object Storage (Recommended)

- **AWS S3**
- **Azure Blob Storage**
- **Google Cloud Storage**
- **External S3-compatible endpoints** (on-prem object storage, appliance-backed, etc.)

### Managed / External Databases (Strongly Recommended)

- **AWS RDS** (Postgres/MySQL)
- **Azure Database for PostgreSQL**
- **Cloud SQL**
- **Aurora** (where appropriate)
- **VM-based PostgreSQL** (for airgap environments)

### Managed / External File Storage (When Needed)

- **AWS EFS**
- **Azure Files**
- **Filestore (GCP)**
- **External NFS** (on-prem / airgap)

---

# 4. Application-Specific Storage Recommendations

---

## GitLab

GitLab typically requires:

- PostgreSQL
- Redis
- Object storage (highly recommended)
- PersistentVolumes for internal components (if not fully externalized)

### Recommended (Production in CSP)

- PostgreSQL: **AWS RDS (Postgres)**
- Object Storage: **AWS S3**
- Redis: **ElastiCache (optional, if supported)**
- PVs: **EBS CSI** for remaining stateful components

**Why this is preferred:**

- GitLab is storage-heavy and operationally complex
- Offloading database + object storage reduces risk significantly

### Recommended (Airgap / Disconnected)

- PostgreSQL: **external to the cluster where feasible** (VM-based Postgres, dedicated DB cluster, or managed platform inside the boundary)
- Object Storage: **Ceph RGW or Garage**
- PVs: **Rook-Ceph or Longhorn**

> Only use in-cluster PostgreSQL when external hosting is not feasible.

---

## Mattermost

### Recommended (Production in CSP)

- PostgreSQL: **AWS RDS**
- File storage: **S3**

### Recommended (Airgap / Disconnected)

- PostgreSQL: **external to the cluster where feasible**
- File storage: **Ceph RGW or Garage**
- PVs: **Rook-Ceph or Longhorn**

> Only use in-cluster PostgreSQL when external hosting is not feasible.

---

## SonarQube

### Recommended (Production in CSP)

- PostgreSQL: **AWS RDS**
- PV: **EBS CSI**

### Recommended (Airgap / Disconnected)

- PostgreSQL: **external to the cluster where feasible**
- PV: **Rook-Ceph or Longhorn**

> Only use in-cluster PostgreSQL when external hosting is not feasible.

---

## Keycloak

### Recommended (Production in CSP)

- PostgreSQL: AWS RDS / managed Postgres

### Recommended (Airgap / Disconnected)

- PostgreSQL: **external to the cluster where feasible**
- PV: if required, use Rook-Ceph or Longhorn

> Only use in-cluster PostgreSQL when external hosting is not feasible.

---

## Harbor (if deployed)

### Recommended (Production in CSP)

- Database: managed Postgres
- Object storage: S3

### Recommended (Airgap / Disconnected)

- Database: **external to the cluster where feasible**
- Object storage: **Garage or Ceph RGW**

> Avoid MinIO for new Harbor deployments.

---

# 5. Big Bang Backup Storage (Velero)

## Recommended (Production in CSP)

- Backup target: S3 / GCS / Azure Blob

## Recommended (Airgap / Disconnected)

- Backup target: **Garage or Ceph RGW**
- (Legacy option): MinIO (not recommended for new deployments)

---

# 6. Summary Recommendations

## AWS / Azure / GCP (Production)

Use:

- CSP CSI drivers for PVs
- Managed databases (RDS / Cloud SQL)
- CSP object storage (S3 / GCS / Blob)
- Managed file storage only when required (EFS / Azure Files)

## Airgapped / On-Prem / Disconnected

Use:

- Rook-Ceph for full storage platform (block + file + object)
- Longhorn for simpler operations and smaller clusters
- Garage or Ceph RGW for S3-compatible object storage
- Databases (especially PostgreSQL): **external to the cluster where feasible**

> In-cluster PostgreSQL should be treated as a fallback option, not the default recommendation.

---

# 7. Future Enhancements (Optional)

This document can be extended with:

- Reference architectures (AWS / on-prem)
- StorageClass examples for each CSI
- Performance and sizing guidance
- Operational checklists (upgrades, DR, monitoring)
- Known Big Bang integration notes and gotchas