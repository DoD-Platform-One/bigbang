# Appendix D - Big Bang Prerequisites

BigBang is built to work on all the major kubernetes distributions.  However, since distributions differ and may come
configured out the box with settings incompatible with BigBang, this document serves as a checklist of pre-requisites
for any distribution that may need it.

## All Clusters

The following apply as prerequisites for all clusters

* A default `StorageClass` capable of resolving `ReadWriteOnce` `PersistentVolumeClaims` must exist
