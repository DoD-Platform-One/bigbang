# Using Big Bang with Multiple Ingress Gateways

By default, Big Bang only creates one ingress for all of the packages.  Although this architecture reduces complexity, it also limits the ability to independently control network access and load balancing to groups of packages.  By configuring Big Bang for multiple ingress gateways through [Istio](https://istio.io/latest/), package access and load can be better controlled.

## Architecture

The following diagram illustrates a typical multiple ingress architecture for Big Bang with the following characteristics:

- A Kubernetes cluster running on a private subnet
- Some apps with exposure to the internet through a public network load balancer
- Some apps without exposure to the internet through a private (aka internal) network load balancer
- Single sign on (SSO) connected to the internet through a dedicated public network load balancer
- A service mesh ([Istio](https://istio.io/latest/)) handling TLS for all apps except SSO

Big Bang is capable of setting up everything within the private subnet using configuration.  The public load balancers would need to be configured outside of Big Bang's deployment.

```mermaid
graph LR
  internet((Internet))--http: 80<br/>https: 443-->pub_nlb & kc_nlb

  subgraph "Public Subnet"
    pub_nlb("Public Network Load Balancer")
    kc_nlb("Keycloak Network Load Balancer")
  end

  subgraph "Private Subnet"
    pri_nlb("Private Network Load Balancer<br/>10.0.0.0/24")--Dynamic-->pri_igw

    subgraph "Kubernetes Cluster"
      pub_nlb--status: 30000<br/>http: 30001<br/>https:30002-->pub_igw
      kc_nlb--status: 30100<br/>http: 30101<br/>https:30102-->kc_igw

      pub_igw("Public Ingress Gateway<br/>Type: NodePort")--http: 8080<br/>https: 8443-->pub_gw
      pri_igw("Private Ingress Gateway<br/>Type: Load Balancer")--http: 8080<br/>https: 8443-->pri_gw
      kc_igw("Keycloak Ingress Gateway"<br/>Type: NodePort)--http: 8080<br/>https: 8443-->kc_gw

      pub_gw("Public Gateway<br/>TLS Terminated<br/>*.bigbang.dev")--http: 8080<br/>gitlab.bigbang.dev-->pub_vs1
      pub_gw--http: 8080<br/>chat.bigbang.dev-->pub_vs2
      pri_gw("Private Gateway<br/>TLS Terminated<br/>*.bigbang.dev")--http: 8080<br/>grafana.bigbang.dev-->pri_vs1
      pri_gw--http: 8080<br/>kibana.bigbang.dev-->pri_vs2
      kc_gw("Keycloak Gateway<br/>TLS Passthrough<br/>keycloak.bigbang.dev")--https: 8443<br/>keycloak.bigbang.dev-->kc_vs1

      pub_vs1("Virtual Service<br/>Gitlab")--http-->pub_ser1("Service<br/>Gitlab")-->pub_pod1a("Pod") & pub_pod1b("Pod")
      pub_vs2("Virtual Service<br/>Mattermost")--http-->pub_ser2("Service<br/>Mattermost")-->pub_pod2a("Pod") & pub_pod2b("Pod")
      pri_vs1("Virtual Service<br/>Grafana")--http-->pri_ser1("Service<br/>Grafana")-->pri_pod1a("Pod") & pri_pod1b("Pod")
      pri_vs2("Virtual Service<br/>Kibana")--http-->pri_ser2("Service<br/>Kibana")-->pri_pod2a("Pod") & pri_pod2b("Pod")
      kc_vs1("Virtual Service<br/>Keycloak")--https-->kc_ser1("Service<br/>Keycloak")-->kc_pod1a("Pod") & kc_pod1b("Pod")
    end
  end

```

### Load Balancers

Load balancers are used to insure traffic is distributed to Istio's control plane running across the Kubernetes nodes.  In the diagram above, we only show one Kubernetes node for simplicity.  But, most clusters are run with multiple nodes.  Load balancers should be connected to all of the nodes.  It is recommended that you use Layer 3/4 network load balancers in Big Bang since Istio can handle layer 7 routing and balancing.

#### Public Load Balancer

Public load balancers must be created independent of Big Bang.  This is because the cluster is deployed in a private subnet and therefore does not have access to create resources in the public, internet-facing subnet.  In order for the load balancer, in the public subnet, to communicate to the Istio's Ingress Gateway, in the private subnet, node ports must be used.  Node ports will bind a port on each cluster node to a listener in the ingress gateway.  The load balancer will distribute traffic on that port to the cluster nodes.

> Not all deployments have a public subnet.  For example, a private network that can only be accessed through a VPN would not have a public subnet and not require any public load balancers.

In Big Bang, this is how you would setup an ingress gateway for Node Ports:

```yaml
istio:
  ingressGateways:
    public-ingressgateway: # This creates a new ingress gateway called "public-ingressgateway"
      type: "NodePort"     # Tell Big Bang this should be a node port ingress gateway rather than a load balancer type
      nodePortBase: 30000  # Bind the following ports: Status <-> 30000; HTTP <-> 30001; HTTPS <-> 30002; SNI <-> 30003
```

The load balancer can then be setup to forward HTTP traffic to all nodes on port 30001 and HTTPS traffic on all nodes to 30002.  Istio provides a ready status that can be reached via HTTP on the status port.  So, the load balancer's health check can be setup for all nodes on port 30000 to the URL `/healthz/ready`.  DNS entries should be created for each hostname to point to the load balancer's DNS.  Package endpoints can then be accessed using the FQDN from the internet.

#### Private / Internal Load Balancer

Private or internal load balancers can usually be created automatically by Big Bang via Istio using service annotations.  By using these annotations, a load balancer will be created for you and automatically mapped to the appropriate nodes/ports for distributing the load.

Here is how you would setup Big Bang for a private load balancer on AWS.  For other cloud providers, review [Kubernetes internal load balancer documentation](https://kubernetes.io/docs/concepts/services-networking/_print/#internal-load-balancer):

```yaml
istio:
  ingressGateways:
    private-ingressgateway: # This creates a new ingress gateway called "private-ingressgateway"
      type: "LoadBalancer"  # Tell Big Bang this should be a load balancer ingress gateway rather than a node port type
      kubernetesResourceSpec:
        serviceAnnotations:
          # The following annotations tell Istio to setup an internal network load balancer through AWS
          service.beta.kubernetes.io/aws-load-balancer-type: nlb
          service.beta.kubernetes.io/aws-load-balancer-internal: "true"
```

After the load balancer is created, you will need to setup DNS entries (e.g. Route 53 on AWS) to point to the load balancer using the host names of the applications.  You should then be able to access the package endpoints from the private network using the FQDN.
> Private network access can be achieved through SSH on a jump box (aka bastion), VPN, or other secure gateway.

### Ingress Gateways

Istio's Ingress Gateways are services that sit on the edge of the Kubernetes cluster and listen for incoming traffic.  In Big Bang, the Ingress Gateways are either setup as Node Port or Load Balancer services.  As a Node Port type, ports on the node are bound to the service and incoming traffic is routed to the nodes on those ports.  As a Load Balancer type, a load balancer is automatically created and configured to communicate to the service.
> In some cases, automatic load balancer creating oand configuration is not supported and a Node Port service must be used.

Ingress Gateways will listen for incoming traffic on their assigned ports and forward that traffic to attached Gateways on the appropriate port.  For example, traffic may be received on port 30002 and forwarded to all attached Gateways on port 8443.

In Big Bang, ingress gateways can be created and configured using the `istio.ingressGateways` values.  By adding additional keys under this value, additional ingress gateways will be created.  The following is an example of setting up three Ingress Gateways to match the architecture diagram above.
> It is recommended that you add `-ingressgateway` on the end of the name of the key to help identify the pods created in the Kubernetes cluster.

```yaml
istio:
  ingressGateways:
    public-ingressgateway:
      type: "NodePort"
      nodePortBase: 30000  # Bind the following ports: Status (15021) <-> 30000; HTTP (8080) <-> 30001; HTTPS (8443) <-> 30002; SNI (15443) <-> 30003

    private-ingressgateway:
      type: "LoadBalancer"
      kubernetesResourceSpec:
        # Setup an AWS internal (private) load balancer
        serviceAnnotations:
          service.beta.kubernetes.io/aws-load-balancer-type: nlb
          service.beta.kubernetes.io/aws-load-balancer-internal: "true"

    passthrough-ingressgateway:
      type: "NodePort"
      nodePortBase: 30100  # Bind the following ports: Status (15021) <-> 30100; HTTP (8080) <-> 30101; HTTPS (8443) <-> 30102; SNI (15443) <-> 30103
```

The default values for Ingress Gateways will work for most situations.  However, if you need finer control over the configuration, any of the settings in the [Kubernetes Resource Spec](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#KubernetesResourcesSpec) can be added to `kubernetesResourceSpec` as a map.  Some examples of additional settings include environmental variables, service selectors, affinity mapping, or additional ports.

### Gateways

While Ingress Gateways handle traffic using ports, Gateways manage traffic using protocol and hostname.  Each Gateway must be assigned to one or more Ingress Gateways to receive traffic.  Gateways are setup to listen on ports for specific protocols and hostnames.  Traffic is then sent on to Virtual Services for further routing.

Gateways can handle TLS encryption, including termination.  If a Gateway is setup for TLS termination, it handles the full TLS handshake during HTTPS connections and decrypts messages at the Gateway before passing traffic on the backend in the clear.  To perform this function, the Gateway must be provided a TLS private key and certificate.  There are [other TLS modes](https://istio.io/latest/docs/reference/config/networking/gateway/#ServerTLSSettings-TLSmode) supported by Gateways that may also be used.

In Big Bang, Gateways can be created and configured using the `istio.gateways` values.  By adding additional keys under this value, additional Gateways will be created.  By default, HTTP traffic is always redirected to HTTPS traffic in the Gateway.  The following is an example of setting up three Gateways to match the architecture diagram above.

> By default Big Bang uses TLS termination on Gateways.  For Keycloak, the package must manage the TLS encryption.  In that case, we use TLS passthrough on the Gateway and setup the TLS keys in the package.

```yaml
  gateways:
    public:
      ingressGateway: "public-ingressgateway"           # Connect to the 'public-ingressgateway'
      hosts:
      - "*.bigbang.dev"                                 # Match all hostnames in the domain
      tls:
        key: "-----BEGIN PRIVATE KEY-----\nMIIE...."    # TLS Private Key
        cert: "-----BEGIN CERTIFICATE-----\nMIIF...."   # TLS Certificate
    private:
      ingressGateway: "private-ingressgateway"          # Connect to 'private-ingressgateway'
      hosts:
      - "*.bigbang.dev"                                 # Match all hostnames in the domain
      tls:
        key: "-----BEGIN PRIVATE KEY-----\nMIIE...."    # TLS Private Key
        cert: "-----BEGIN CERTIFICATE-----\nMIIF...."   # TLS Certificate
    passthrough:
      ingressGateway: "passthrough-ingressgateway"      # Connect to 'passthrough-ingressgateway'
      hosts:
      - "keycloak.bigbang.dev"                          # Only match keycloak hostname
      tls:
        mode: "PASSTHROUGH"                             # Pass TLS encrypted traffic to application
```

Big Bang will automatically create a secret with the TLS key and cert provided for each Gateway.  In some cases, it may be advantageous to create the secrets ahead of time and have Big Bang use them.  In this case a TLS secret named `{name of gateway}-cert` can be prepopulated with the key and `tls.key` and `tls.cert` values can be left blank.  For example, for the `private` Gateway, a `private-cert` TLS secret would be created.

### Virtual Services

Virtual services use full URL host and path information to route incoming traffic to a Service.  Each package in Big Bang manages its own Virtual Services since the paths and ports vary for each package.  However, in order to receive traffic at the Virtual Service, it must be connected to a Gateway.  In Big Bang we configure this under each package.  The followng is an example of this configuration that matches the architecture diagram above.

```yaml
monitoring:
  ingress:
    gateway: "private"
logging:
  ingress:
    gateway: "private"
addons:
  gitlab:
    enabled: true
    ingress:
      gateway: "public"
  mattermost:
    enabled: true
    ingress:
      gateway: "public"
  keycloak:
    enabled: true
    ingress:
      gateway: "passthrough"
```

### Services and Pods

Once traffic passes through the Virtual Service, it is passed to a Service.  The service may have several redundant pods and a load balancing scheme to manage incoming traffic.  It will route the traffic to the appropriate pod based on these settings.  Each package implements the service and pods differently and typically the default configuration is adequate for most deployments.
