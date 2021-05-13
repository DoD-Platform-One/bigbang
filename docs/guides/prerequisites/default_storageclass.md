# Default Storage Class prerequisite
* BigBang assumes the cluster you're deploying to supports [dynamic volume provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/).
* A BigBang Cluster should have 1 Storage Class annotated as the default SC.
* For Production Deployments it is recommended to leverage a Storage Class that supports the creation of volumes that support ReadWriteMany [Access Mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes), as there are a few BigBang Addons, where an HA application configuration requires a storage class that supports ReadWriteMany. 


## How Dynamic volume provisioning works in a nut shell
* StorageClass + PersistentVolumeClaim = Dynamically Created Persistent Volume
* A PersistentVolumeClaim that does not reference a specific StorageClass will leverage the default StorageClass. (Of which there should only be 1, identified using kubernetes annotations.) Some Helm Charts allow a storage class to be explicitly specified so that multiple storage classes can be used simultaneously. 


## How to check what storage classes are installed on your cluster
* `kubectl get storageclass` can be used to see what storage classes are available on a cluster, the default will be marked as such. 
* Note: You can have multiple storage classes, but you should only have 1 default storage class.
```bash
kubectl get storageclass
# NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
# local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  47h
```

------------------------------------------------------

## AWS Specific Notes

### Example AWS Storage Class Configuration
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: gp2
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2 #gp3 isn't supported by the in-tree plugin
  fsType: ext4
#  encrypted: 'true' #requires kubernetes nodes have IAM rights to a KMS key
#  kmsKeyId: 'arn:aws-us-gov:kms:us-gov-west-1:110518024095:key/b6bf63f0-dc65-49b4-acb9-528308195fd6'
reclaimPolicy: Retain
allowVolumeExpansion: true
```

### AWS EBS Volumes:
* AWS EBS Volumes have the following limitations:
  * An EBS volume can only be attached to a single Kubernetes Node at a time, thus ReadWriteMany Access Mode isn't supported.
  * An EBS PersistentVolume in AZ1 (Availability Zone 1), cannot be mounted by a worker node in AZ2.

### AWS EFS Volumes:
* An AWS EFS Storage Class can be installed according to the [vendors docs](https://github.com/kubernetes-sigs/aws-efs-csi-driver#installation).
* AWS EFS Storage Class supports ReadWriteMany Access Mode. 
* AWS EFS Persistent Volumes can be mounted by worker nodes in multiple AZs.
* AWS EFS is basically NFS(NetworkFileSystem) as a Service. NFS cons like latency apply equally to EFS, thus it's not a good fit for for databases.  

------------------------------------------------------

## Azure Specific Notes
### Azure Disk Storage Class Notes
* The Kubernetes Docs offer an Example [Azure Disk Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/#azure-disk)
* An Azure disk can only be mounted with Access mode type ReadWriteOnce, which makes it available to one node in AKS. 
* An Azure Disk PersistentVolume in AZ1, can be mounted by a worker node in AZ2 (although some additional lag is involved in such transitions).

------------------------------------------------------

## Bare Metal/Cloud Agnostic Store Class Notes
* The BigBang Product team put together a [Comparison Matrix of a few Cloud Agnostic Storage Class offerings](../../k8s-storage/README.md#kubernetes-storage-options)
* Note: No storage class specific container images exist in IronBank at this time. 
  * Approved IronBank Images will show up in https://registry1.dso.mil
  * https://repo1.dso.mil/dsop can be used to check status of IronBank images.
