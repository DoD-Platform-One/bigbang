# Confluence

Confluence is a collaborative document and workflow tool.  This is a licensed poduct and will require a license code when first going tothe web site.  

Additional docs for using  and its plugins can be found at <https://www.atlassian.com/software/confluence/features>

This baseline uses Confluence version 7.4.0.  This image was available in Iron Bank as a hardened container, but is in a peanding approval status.  The image has been retagged and added to the public apps Confluence Registry.  

The generated yaml was peoduced by following these instructions

* git clone <https://github.com/stevehipwell/helm-charts.git>

* cd helm-charts

* helm dep update charts/confluence-server/

* helm template confluence charts/confluence-server/ -f ../generated/values.yaml > ../generated/generated.yaml

## Usage

### Prerequisites

Kubernetes cluster deployed
Kubernetes config installed in ~/.kube/config

Install kubectl
brew install kubectl
Install kustomize
brew install kustomize

Deployment
Clone repository
git clone <https://repo1.dsop.io/platform-one/apps/fluentd-elasticsearch.git>
cd fluentd-elasticsearch
Apply kustomized manifest
kubectl -k ./

### Operations

By default, this application will use an index prefix name of logstash. To verify and configure the
index, utilize Kibana Discover.
The Fluentd inputs and outputs are defined in the ConfigMap resource, which sources from the conf files.

Container Environment Variables
These variables are patched in via kustomize and may require modifications depending on your
environment.

### Contributing

Clone repository
git clone <https://repo1.dsop.io/platform-one/apps/fluentd-elasticsearch.git>
Create a feature branch
git checkout -b <branch>
Stage and commit changes
git add .
git commit -m "Made a change for reasons"
Push commits to upstream branch
git push -u origin <branch>