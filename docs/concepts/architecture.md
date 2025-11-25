# Architecture

## Kube API Server Webhooks Diagram

* Help new users understand how BigBang extends the kube-apiserver using webhooks to enable:
  * Best practice security controls
  * Abstractions that improve user experience for developers / maintainability
* Kubernetes Security Best Practice (per [kube-bench](https://github.com/aquasecurity/kube-bench)) for requests to the kube-apiserver is that requests should go through the following flow of controls:
  1. mTLS Authentication via x509 certs:
     * This is baked into Kubernetes
  1. RBAC Authorization of users and Node Authentication for worker nodes
     * `--authorization-mode=Node,RBAC` flag on kube-apiserver ensures this is set.
     * Deployed applications contain YAML manifests with rbac rules to minimize the rights of the application's service account.
  1. Admission Controllers: These take effect after Authn and Authz have occurred and allow the functionality of the api-server to be extended to enable additional security controls and advanced features.
     * There are apiserver plugins baked into Kubernetes that just need to be turned on like `--enable-admission-plugins=NodeRestriction` per kube-bench.
     * There's also webhooks that allow extending the apiserver with custom logic, this will be overviewed in the diagram below.

### BigBang Kubernetes API Server Webhooks Diagram

![kube-apiserver_webhooks_diagram.app.diagrams.net.png](https://repo1.dso.mil/big-bang/product/bb-static/-/raw/main/docs/assets/imgs/understanding-bigbang/kube-apiserver-webhooks-diagram.app.diagrams.net.png)

#### Notes

##### 1. Git Repo

* Can be HTTPS or SSH based, can exist on the Internet or in Private IP Space
* Airgap deployments are recommended to use SSH based Git Repo in Private IP Space
* Argo CD / Flux CD need network connectivity to and in most cases read only credentials to view the contents of the git repo.

##### 2. Mutating Admission Controllers

* This improves user experience for developers. If a namespace is labeled `istio-injection=enabled`, then a developer can submit a YAML manifest where the pod only needs to reference 1 container image/the application. After the request is authenticated and authorized against the kube-apiserver, it's admission controller will see a mutating admission webhook exists and the manifest will be sent to the `istiod` pod in the `istio-system` namespace to mutate the manifest and inject an Istio init container and Istio envoy proxy sidecar container into the YAML manifest. This allows the developer's pod to be integrated into the service mesh with minimal configuration / effort on their part/no adjustments to their YAMLs were needed.
* Note: It's possible to use Istio CNI Plugin to eliminate the need for Istio Init Containers.

##### 3. Validating Admission Controllers

* As of BigBang >= 2.0.0 Kyerno is used instead of Gatekeeper. See [Kyverno overview](../packages/core/kyverno.md)
* As of BigBang 1.7.0 OPA GK defaults to dry-run/warn and not blocking/enforcing mode, [there are plans to change the default behavior to blocking/enforcing mode.](https://repo1.dso.mil/big-bang/bigbang/-/issues/468)
* OPA GK can enforce security policy such as only allowing whitelisted container registries, PodSecurityPolicies equivalent functionality, and more.

## Logs Data Flow Diagram

* Help new users understand the data flow of pod logs

### Kubernetes Pod Logs Data Flow Diagram

![logs_data_flow_diagram.app.diagrams.net.png](https://repo1.dso.mil/big-bang/product/bb-static/-/raw/main/docs/assets/imgs/understanding-bigbang/logs-data-flow-diagram.app.diagrams.net.png)

| Line Number | Protocol | Port | Description |
| --- |  --- | --- | --- |
| N1 | Volume Mount | NA | Fluent Bit reads pod logs from a host node volume mount |
| N2 | HTTPS | TCP:9200 | Fluent Bit sends logs to Elastic Search over the URL: `https://logging-ek-es-http:9200` (This URL is only exposed over the Kubernetes Inner Cluster Network, and because Fluent Bit and ElasticSearch have Istio Envoy Proxy sidecar containers the network traffic is protected by the service mesh.) |

### Notes

1. The Fluent Bit log shipper is configured to send pod logs to the ElasticSearch Cluster in the logstash data format.  Logstash_Format On
2. By default: The log index logstash-%Y.%m.%d will create a new log index everyday, because %d will increment by one everyday. There are no default Index Lifecycle Management Policies that are created or applied to these indexes. It is recommended that customers create a Index Lifecycle policy to prevent disk space from filling up. (Example: Archive to s3 and then delete from PVC logs older than N days.)

## Metrics Data Flow Diagram

* Help new users understand the data flow of prometheus metrics

### Prometheus Metrics Data Flow Diagram

![metrics_data_flow_diagram.app.diagrams.net.png](https://repo1.dso.mil/big-bang/product/bb-static/-/raw/main/docs/assets/imgs/understanding-bigbang/metrics-data-flow-diagram.app.diagrams.net.png)

| Line Number | Protocol | Port | Description |
| --- |  --- | --- | --- |
| N1 | HTTP | varies* | *A standard port number for prometheus metric endpoint URLs doesn't exist. The Prometheus Operator is able to use ServiceMonitors and Kubernetes Services to automatically discover IP addresses of pods and these varying prometheus metric endpoint ports. Once a minute the prometheus Operator dynamically regenerates a metric collection config file that the Prometheus Server continuously uses to collect metrics. In the majority of cases prometheus metric endpoints, are read over HTTP, and are only reachable over the Kubernetes Inner Cluster Network.  |

## Network Encryption and Ingress Diagram

* Help new users better understand:
  * That the CNI component of Kubernetes creates an Inner Cluster Network.
  * Kubernetes Ingress (How network traffic flows from LAN to Inner Cluster Network)
  * How Big Bang is leveraging Istio Operator
  * Network Encryption in the context of Big Bang (HTTPS, mTLS, and spots where Network Encryption is not present by default.)

### Big Bang Network Ingress Diagram

![network_encryption_and_ingress_diagram.app.diagrams.net.png](https://repo1.dso.mil/big-bang/product/bb-static/-/raw/main/docs/assets/imgs/understanding-bigbang/network-encryption-and-ingress-diagram.app.diagrams.net.png)

#### Notes

##### 1. CNAP (Cloud Native Access Point) or Equivalent

* CNAP is a P1 service offering separate from Big Bang, that bundles several technologies together: Palo Alto Firewall, AppGate Software Defined Perimeter, and P1's Keycloak Implementation which has a plugin baked in that allows SSO using Common Access Cards, by leveraging the x509 certs/PKI associated with the cards and DoD CAs as an federated identity provider.
* CNAP is basically an advanced edge firewall that can do many things. In terms of Network Encryption it can act as a trusted MITM (Terminating HTTPS, inspecting the decrypted traffic for WAF (Web Application Firewall) protection purposes, and then re-encrypting traffic before forwarding to it's intended destination (usually a private IP Address of an Ingress LB of a Big Bang Cluster.)
* More details on CNAP can be found on the [CNAP Transition to Cloud One](https://repo1.dso.mil/platform-one/bullhorn-delivery-static-assets/-/raw/master/p1/Cloud%20Native%20Access%20Point%20(CNAP)%20Transition%20to%20Cloud%20One%20-%2006_03_2025.pdf).
* If your DoD command is interested in leveraging CNAP to protect a Big Bang Cluster [this page has instructions on how to ask for more details.](https://p1.dso.mil/#/services)
* `There is no hard requirement that consumers of Big Bang must leverage CNAP`.
  * P1 uses CNAP to add defense in depth security for many of it's public internet facing services.
  * A consumer of Big Bang can decide not to use CNAP if their AO allows; which could be due to: risk acceptance, alternatives, other compensating controls / circumstances like: users only connecting through trusted networks like NIPRNet, airgap, etc. that are accessed via bastion, VPN, VDI, etc.

##### 2. Ingress LB Provisioning Logic

* If an admin runs the following command against a Big Bang Cluster `kubectl get istiooperator -n=istio-system -o yaml`, they will see that this CR (custom resource) has a YAML array / list of Ingress Gateways.
* Each Ingress Gateway in the list will (by default) spawn:
  * A Kubernetes Service of type Load Balancer, which spawns a CSP LB.
  * A Kubernetes Deployment of pods acting as an Istio Ingress Gateway.
* A Big Bang Cluster can end up with more than 1 LB if the list (in the istiooperator CR) contains multiple Ingress Gateways OR if there is more than 1 istiooperator CR (which could contain it's own additional list of Ingress Gateways). (The easy creation of multiple Ingress Gateways was added to Big Bang's helm values, in v1.13.0)
* A Production Deployment of Big Bang should (in most cases):
  * Set the Big Bang values.yaml file to leverage Kubernetes service annotations to ensure the provisioned CSP LBs are provisioned with Private IP Addresses.
  * Separate traffic destined for admin management GUIs from user facing applications.
    * One way of doing this is to edit the helm values to create multiple Ingress Gateways (which would create multiple CSP LBs) and map admin management GUIs to a LB for admins to access, and user services to a LB for users to access. Then a firewall / network access control list could be used to limit traffic to the admin management GUI's CSP LB as a KISS solution.
    * Another way is to have user and admin traffic enter the cluster via the same CSP LB, and use Big Bang's Auth Service SSO Proxy to filter webpage access based on a user's group membership defined by the backend identity provider.
    * Combining both of these is an additional option if defense in depth is desired.

##### 3. Network Ingress Traffic Flow

1. Port 443 of the CSP LB gets load balanced between a NodePort of the Kubernetes Nodes. (The NodePort can be randomly generated or static, depending on helm values.)
2. Kube Proxy (in most cases) is responsible for mapping/forwarding traffic from the NodePort, which is accessible on the Private IP Space Network, to port 443 of the istio-ingressgateway service which is accessible on the Kubernetes Inner Cluster Network. (So Kube Proxy and Node Ports are how traffic crosses the boundary from Private IP Space to Kubernetes Inner Cluster Network Space.)
3. Istio-ingressgateway service port 443 then maps to port 8443 of istio-ingressgateway pods associated with the deployment (they use the non-privileged port 8443, because they've gone through the IronBank Container hardening process. (From the end users perspective the end user only sees 443, and an http --> https redirect is also configured.)
4. The Istio Ingress Gateway pods are basically Envoy Proxies / Layer 7 Load Balancers that are dynamically configured using declarative Kubernetes Custom Resources managed via GitOps. These Ingress Gateway pods terminate HTTPS (in most cases) and then forward traffic to web services hosted in a Big Bang Cluster.

##### 4. Ingress HTTPS Certificates

* A Gateway CR will reference a HTTPS Certificate stored in a Kubernetes secret of type TLS.
* Some environments will mandate 1 HTTPS Certificate per DNS name. In this scenario you'll need 1 gateway CR and secret of type TLS for each virtual service.
* In order for Ingress to work correctly DNS names must match in 4 places:
  1. DNS needs to point to the correct CSP Ingress LB
  2. DNS name associated with HTTPS Certificate in a Kubernetes Secret of type TLS
  3. DNS name referenced in Virtual Service CR
  4. DNS name referenced in Gateway CR
* Additionally if Big Bang is configured to leverage multiple Ingress Gateways the Virtual Service CR much reference the correct Gateway CR and the Gateway CR must reference the correct HTTPS cert in a Kubernetes Secret of type TLS.

##### 5. Network Encryption of Ingress Traffic

* Traffic from the user through a CSP Layer 4/TCP LB to the Istio Ingress Gateway pods is encrypted in transit in 100% of cases per default settings.
* Usually HTTPS is terminated at the Istio Ingress Gateway, using an HTTPS Certificate embedded in a Kubernetes secret of type TLS.
* One exception is if the Keycloak addon is enabled then the gateway CR is configured to have traffic destined for the Keycloak DNS name to leverage TLS Passthrough, and the Keycloak pod terminates the HTTPS connection.

##### 6. Network Encryption of Node to Node Traffic

* CNIs (Container Network Interfaces) create Inner Cluster Networks that allow pods and services to talk to each other and usually set up network routing rules/filters that make it so external traffic can only initiate a connection to by going through explicitly opened NodePorts.
* Different CNIs create an Inner Cluster Network in different ways. Some CNIs uses BGP. Others make use of VXLANs.
* Some CNIs support encrypting 100% of the CNI traffic and others don't.
* Installation and configuration of CNI is outside the scope of Big Bang and is considered a prerequisite, consult with your AO to determine their requirements for encryption of traffic in transit.

##### 7. Network Encryption of Traffic on the Inner Cluster Network

* HTTPS for Ingress Traffic is terminated at the Istio Ingress Gateway, but network encryption from the Istio Ingress Gateway to the final destination can vary depending on if they're integrated into the service mesh or not.
* If the app is part of the service mesh (which can usually be seen by checking if the namespace is labeled istio-injection=enabled and verifying an istio-proxy sidecar container exists), then it's using mTLS or HTTPS (in the case of ElasticSearch, which is done for compatibility).
* If the app isn't part of the service mesh (which as of Big Bang 1.8.0 is the case for Grafana, Prometheus, and AlertManager) then traffic from the Istio Ingress Gateway to the destination pod won't be encrypted, unless the application provides it's own encryption like in the case of Keycloak and Twistlock.
* Kubernetes Operators have their own built in HTTPS.
* Kubernetes Control Plane Components have built in mTLS.
* CoreDNS that ships with Kubernetes doesn't leverage encrypted DNS.
