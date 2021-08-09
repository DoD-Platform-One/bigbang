# Goals of this Architecture Diagram

* Help new users better understand:
  * That the CNI component of Kubernetes creates an Inner Cluster Network.
  * Kubernetes Ingress (How network traffic flows from LAN to Inner Cluster Network)
  * How Big Bang is leveraging Istio Operator
  * Network Encryption in the context of Big Bang (HTTPS, mTLS, and spots where Network Encryption is not present by default.)

## Big Bang Network Ingress Diagram

![network_encryption_and_ingress_diagram.app.diagrams.net.png](images/network_encryption_and_ingress_diagram.app.diagrams.net.png)

### Notes

#### 1. CNAP (Cloud Native Access Point) or Equivalent

* CNAP is a P1 service offering separate from Big Bang, that bundles several technologies together: Palo Alto Firewall, AppGate Software Defined Perimeter, and P1's Keycloak Implementation which has a plugin baked in that allows SSO using Common Access Cards, by leveraging the x509 certs/PKI associated with the cards and DoD CAs as an federated identity provider.
* CNAP is basically an advanced edge firewall that can do many things. In terms of Network Encryption it can act as a trusted MITM (Terminating HTTPS, inspecting the decrypted traffic for WAF (Web Application Firewall) protection purposes, and then re-encrypting traffic before forwarding to it's intended destination (usually a private IP Address of an Ingress LB of a Big Bang Cluster.)
* More details on CNAP can be found on the [Ask Me Anything Slides located here](https://software.af.mil/dsop/documents/).
* If your DoD command is interested in leveraging CNAP to protect a Big Bang Cluster [this page has instructions on how to ask for more details.](https://p1.dso.mil/#/services)
* `There is no hard requirement that consumers of Big Bang must leverage CNAP`.
  * P1 uses CNAP to add defense in depth security for many of it's public internet facing services.
  * A consumer of Big Bang can decide not to use CNAP if their AO allows; which could be due to: risk acceptance, alternatives, other compensating controls / circumstances like: users only connecting through trusted networks like NIPRNet, airgap, etc. that are accessed via bastion, VPN, VDI, etc.

#### 2. Ingress LB Provisioning Logic

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

#### 3. Network Ingress Traffic Flow

1. Port 443 of the CSP LB gets load balanced between a NodePort of the Kubernetes Nodes. (The NodePort can be randomly generated or static, depending on helm values.)
2. Kube Proxy (in most cases) is responsible for mapping/forwarding traffic from the NodePort, which is accessible on the Private IP Space Network, to port 443 of the istio-ingressgateway service which is accessible on the Kubernetes Inner Cluster Network. (So Kube Proxy and Node Ports are how traffic crosses the boundary from Private IP Space to Kubernetes Inner Cluster Network Space.)
3. Istio-ingressgateway service port 443 then maps to port 8443 of istio-ingressgateway pods associated with the deployment (they use the non-privileged port 8443, because they've gone through the IronBank Container hardening process. (From the end users perspective the end user only sees 443, and an http --> https redirect is also configured.)
4. The Istio Ingress Gateway pods are basically Envoy Proxies / Layer 7 Load Balancers that are dynamically configured using declarative Kubernetes Custom Resources managed via GitOps. These Ingress Gateway pods terminate HTTPS (in most cases) and then forward traffic to web services hosted in a Big Bang Cluster.

#### 4. Ingress HTTPS Certificates

* A Gateway CR will reference a HTTPS Certificate stored in a Kubernetes secret of type TLS.
* Some environments will mandate 1 HTTPS Certificate per DNS name. In this scenario you'll need 1 gateway CR and secret of type TLS for each virtual service.
* In order for Ingress to work correctly DNS names must match in 4 places:
  1. DNS needs to point to the correct CSP Ingress LB
  2. DNS name associated with HTTPS Certificate in a Kubernetes Secret of type TLS
  3. DNS name referenced in Virtual Service CR
  4. DNS name referenced in Gateway CR
* Additionally if Big Bang is configured to leverage multiple Ingress Gateways the Virtual Service CR much reference the correct Gateway CR and the Gateway CR must reference the correct HTTPS cert in a Kubernetes Secret of type TLS.

#### 5. Network Encryption of Ingress Traffic

* Traffic from the user through a CSP Layer 4/TCP LB to the Istio Ingress Gateway pods is encrypted in transit in 100% of cases per default settings.
* Usually HTTPS is terminated at the Istio Ingress Gateway, using an HTTPS Certificate embedded in a Kubernetes secret of type TLS.
* One exception is if the Keycloak addon is enabled then the gateway CR is configured to have traffic destined for the Keycloak DNS name to leverage TLS Passthrough, and the Keycloak pod terminates the HTTPS connection.

#### 6. Network Encryption of Node to Node Traffic

* CNIs (Container Network Interfaces) create Inner Cluster Networks that allow pods and services to talk to each other and usually set up network routing rules/filters that make it so external traffic can only initiate a connection to by going through explicitly opened NodePorts.
* Different CNIs create an Inner Cluster Network in different ways. Some CNIs uses BGP. Others make use of VXLANs.
* Some CNIs support encrypting 100% of the CNI traffic and others don't.
* Installation and configuration of CNI is outside the scope of Big Bang and is considered a prerequisite, consult with your AO to determine their requirements for encryption of traffic in transit.

#### 7. Network Encryption of Traffic on the Inner Cluster Network

* HTTPS for Ingress Traffic is terminated at the Istio Ingress Gateway, but network encryption from the Istio Ingress Gateway to the final destination can vary depending on if they're integrated into the service mesh or not.
* If the app is part of the service mesh (which can usually be seen by checking if the namespace is labeled istio-injection=enabled and verifying an istio-proxy sidecar container exists), then it's using mTLS or HTTPS (in the case of ElasticSearch, which is done for compatibility).
* If the app isn't part of the service mesh (which as of Big Bang 1.8.0 is the case for Grafana, Prometheus, and AlertManager) then traffic from the Istio Ingress Gateway to the destination pod won't be encrypted, unless the application provides it's own encryption like in the case of Keycloak and Twistlock.
* Kubernetes Operators have their own built in HTTPS.
* Kubernetes Control Plane Components have built in mTLS.
* CoreDNS that ships with Kubernetes doesn't leverage encrypted DNS.
