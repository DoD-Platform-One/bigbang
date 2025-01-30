# Post-Renderers in Helm, Flux, and Kustomize

Post-renderers are a powerful feature that extend the functionality of Helm by enabling custom modifications to rendered Kubernetes manifests before they are applied to the cluster. This doc explores post-renderers: their applications, advantages, and limitations, particularly in the context of Helm, Flux, and Kustomize.

---

## What Are Post-Renderers?

A **post-renderer** is a program or script that Helm executes _after_ rendering a chart but _before_ applying the resulting Kubernetes manifests to a cluster. Post-renderers allow you to:

- Make adjustments to Kubernetes manifests without having to fork from the upstream repository.
- Apply organization-specific policies or transformations.
- Integrate external tools to enhance the generated manifests.

For more details, see the [Helm documentation on post-renderers](https://helm.sh/docs/topics/advanced/#post-rendering).

---

## Advantages of Using Post-Renderers

Using post-renderers in a repository offers several advantages, the biggest of which at Big Bang is allowing for security-hardened modifications without having to fork upstream charts:

1. **Customizability:**
   - Post-renderers allow you to tailor Kubernetes manifests to specific organizational requirements without altering the upstream Helm chart or templates.

2. **Policy Enforcement:**
   - Security and compliance policies can be enforced dynamically by injecting labels, annotations, or security contexts into resources.

3. **Reuse of Charts:**
   - By using post-renderers, the same Helm chart can be reused across multiple environments with unique configurations applied during deployment.

4. **Seamless Integration:**
   - Post-renderers can integrate external tools or scripts into the deployment pipeline, making it easier to manage complex workflows.

5. **Environment-Specific Customization:**
   - Tailor deployments to different environments (e.g., development, staging, production) by dynamically altering configurations.

---

## How Post-Renderers Work in Helm

- **Execution Flow:**
   1. Helm renders the chart templates.
   2. The rendered output is passed to the post-renderer.
   3. The post-renderer modifies the manifests as needed and returns the updated output.

---

## Post-Renderers and Kustomize

Kustomize is a tool for customizing Kubernetes YAML manifests without using templating. It allows you to define declarative patches or overlays to modify resources in a structured and reusable way. When you use Kustomize as a post-renderer, Helm passes the rendered manifests to Kustomize, which then applies its patches or overlays. The result is the modified manifests that Helm deploys to the cluster. For more information, see the [Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/) documentation.

The Flux HelmRelease resource has an api reference for Kustomize to apply patches for Kubernetes manifest augmentation. Refer to to Flux [HelmRelease Kustomize api reference doc](https://v2-0.docs.fluxcd.io/flux/components/helm/api/#helm.toolkit.fluxcd.io/v2beta1.Kustomize) for more information.

___

## Post-Renderers in Flux

As part of the Big Bang product, we apply post-renders through Flux, a GitOps tool that integrates with Helm charts via the Helm Controller using the `HelmRelease` resource's built-in Kustomize directives.

**HelmRelease Resource:**
   In Flux, the `HelmRelease` resource is used to deploy Helm charts. To apply Kustomize post-rendering you can use HelmRelease `spec.postRenderers` (see [Helm Release postRenderers](https://fluxcd.io/flux/components/helm/helmreleases/#post-renderers) and the [HelmRelease Kustomize api reference doc](https://v2-0.docs.fluxcd.io/flux/components/helm/api/#helm.toolkit.fluxcd.io/v2beta1.Kustomize)  for more info) to modify Kubernetes resources that are deployed from that HelmRelease. When using Kustomize to augment the manifest, you can refer to the Kustomize documentation, specifically the [Kustomize patches doc](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/) as a helpful resource. 

## Post-Rendering Example in Big Bang
An example of using post-renderers in Big Bang can be found in the Mimir template. 

1. The Mimir template in the Big Bang umbrella chart contains a `_postrenderers.tpl` file: [bigbang/chart/templates/mimir/_postrenderers.tpl](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/chart/templates/mimir/_postrenderers.tpl). This specific template adds tcp/grpc appProtocols to the Mimir service, a new containerPort, and an `app.kubernetes.io/part-of` label. You can see this with `app.kubernetes.io~1part-of` which gets translated to `app.kubernetes.io/part-of`. This is because the RFC6902 JSON patches are expected to use RFC6901 JSON pointer syntax (Both are respectively outlined in: [JavaScript Object Notation (JSON) Patch](https://datatracker.ietf.org/doc/html/rfc6902) and [JavaScript Object Notation (JSON) Pointer](https://datatracker.ietf.org/doc/html/rfc6901)).
2. The HelmRelease resource for Mimir includes the `mimir.istioPostRenderers` from the `_postrenderers.tpl` template (found under `spec.postRenderers`): [bigbang/chart/templates/mimir/helmrelease.yaml](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/chart/templates/mimir/helmrelease.yaml#L42).
3. Post-renderers get applied during the `helm install`, patching the Mimir service/deployments.

---

## Limitations of Post-Renderers

### Helm:
- **Does not support Helm tests:** Post-renderers are not executed during `helm test` runs so it is not possible to augment the manifests that are deployment during `helm test` using HelmRelease post-renderers. 

---

## Conclusion

Post-renderers provide flexibility for concluding customizations of Kubernetes manifests. However, their integration with tools like Flux and Kustomize introduces additional complexity. Understanding their advantages and limitations ensures smoother deployments and maintainable workflows.

For more information, refer to:
- [Helm Post-Rendering](https://helm.sh/docs/topics/advanced/#post-rendering)
- [Flux Helm Release Post Renderers](https://fluxcd.io/flux/components/helm/helmreleases/#post-renderers)
- [Kustomize Documentation](https://kustomize.io/)
