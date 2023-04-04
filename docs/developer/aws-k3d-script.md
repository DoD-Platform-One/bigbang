# Development k3d cluster automation

> NOTE: This script does not does not install Flux or deploy Big Bang. You must handle those deployments after your k3d dev cluster is ready.

The instance will automatically terminate 8 hours after creation.

## Install and Configure Dependencies

1. Install aws cli

   ```shell
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   # sudo apt install unzip -y
   unzip awscliv2.zip
   sudo ./aws/install
   rm -rf aws
   rm awscliv2.zip
   aws --version
   ```

1. Configure aws cli

   ```shell
   aws configure
   # aws_access_key_id - The AWS access key part of your credentials
   # aws_secret_access_key - The AWS secret access key part of your credentials
   # region - us-gov-west-1
   # output - json

   # Verify configuration
   aws configure list
   ```

1. Install jq  
    Follow jq installation instructions for your workstation operating system.  
    <https://stedolan.github.io/jq/download/>

1. Mac users will need to install the GNU version of the sed command.  
   <https://medium.com/@bramblexu/install-gnu-sed-on-mac-os-and-set-it-as-default-7c17ef1b8f64>

## Usage

The default with no options specified is to use the EC2 public IP for the k3d cluster and the security group.

```shell
./docs/assets/scripts/developer/k3d-dev.sh -h
AWS User Name: your.name
Usage:
k3d-dev.sh -b -p -m -d -h

 -b   use big M5 instance. Default is t3.2xlarge
 -p   use private IP for security group and k3d cluster
 -m   create k3d cluster with metalLB
 -d   destroy related AWS resources
 -h   output help
```
## To use a different AWS profile, VPC, or AMI
The script uses the default AWS profile and defaults the VPC id and AMI id. 
To change this default behavior you can export environment variables before running the script.  

Run the script with a specific AWS profile by first exporting the AWS_PROFILE environment variable:
```shell
export AWS_PROFILE=my-aws-profile
```
To run the script with a specific VPC:
```shell
export VPC_ID=vpc-XXXXXXXXXXXX
```
To run the script with a specific AMI:
```shell
export AMI_ID=ami-XXXXXXXXXX
```
To specify a specific Kubernetes version (the eligible choices are [here](https://hub.docker.com/r/rancher/k3s/tags)):
```shell
export K3S_IMAGE_TAG=sometag
```

You can also run these inline with the script, without exporting them to your environment.  Example:

```shell
K3S_IMAGE_TAG=v1.24.12-k3s1 ./docs/assets/scripts/developer/k3d-dev.sh
```

## After Running The Script

Follow the instructions from the script output to access and use the cluster.


## Install FluxCD

The Big Bang product is tightly coupled with the GitOps tool FluxCD. Before you can deploy Big Bang you must deploy FluxCD on your k8s cluster. To guarantee that you are using the version of FluxCD that is compatible with the version of Big Bang that you are deploying use the Big Bang provided [script](../../scripts/install_flux.sh). You will need your Iron Bank pull credentials and command line access to the k8s cluster from your workstation.

```shell
./scripts/install_flux.sh -u your-user-name -p your-password
```

## Deploy Bigbang

From the bigbang directory deploy BigBang via helm
```shell
helm upgrade -i bigbang chart/ -n bigbang --create-namespace --set registryCredentials.username=XXXXX --set registryCredentials.password='XXXXX' -f chart/values.yaml
```

Overrides can be supplemented by adding references to the specific yaml file, the right-most values file will take highest precedence: 
```shell
-f ../other-overrides.yaml
```

## Troubleshooting

1. If you are on a Mac insure that you have GNU sed command installed. Otherwise you will see this error and the kubeconfig will not be updated with the IP from the instance.

   ```console
   copy kubeconfig
   config                         100% 3019    72.9KB/s   00:00
   sed: 1: "...": extra characters at the end of p command

   ```

2. If you get a failure from the script study and correct the error. Then run script with "-d" option to clean up resources. Then re-run your original command.

3. Occasionally a ssh command will fail because of connection problems. If this happens the script will fail with "unexpected EOF". Simply try again. Run the script with `-d` to clean up resources. Then re-run your original command.
