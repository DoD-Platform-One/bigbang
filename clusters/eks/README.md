# eks

THIS IS STILL IN DEVELOPMENT

This folder contains _one example_ of deploying AWS `eks`, and is tuned specifically to run BigBang CI.
While it can be used as an example for deployments, please ensure you're taking your own needs into consideration.

## What's deployed

* `eks` cluster
  * sized according to BigBang CI Needs as non-ha
  * if ha is desired, simply change `servers = 3` in the installation or upgrade
* aws govcloud (`us-gov-west-1`)
* airgap
* single autoscaling generic agent nodepool
  * sized according to BigBang CI needs as 2 `m5a.4xlarge` instances
  * if additional nodes are needed, simply add more nodepools

## How's it deployed

The `eks` terraform modules used can be found on repo1 [here](https://repo1.dso.mil/platform-one/distros/aws/aws-eks-tf/-/tree/main/eks-tf).

Both `ci` and `dev` setups exist, the example below can be run locally for development workflows where local clusters may not suffice:

```bash
# ensure BigBang's CI network exists
cd .gitlab-ci/jobs/networking/aws/dependencies/terraform/env/dev
terraform init
terraform apply

# deploy eks
cd .gitlab-ci/jobs/eks/dependencies/terraform/env/dev
terraform init
terraform apply

# kubeconfig will be copied locally after terraform completes in ~5m
aws eks update-kubeconfig --region REGION --name EKS_CLUSTER_NAME
```