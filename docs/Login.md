# Default Token Login

Kiali offers 5 options for authentication. Big Bang will default to using the token method.

The token method uses the Kubernetes service account token for authentication. To get the default Kiali SA token for login:

  ```shell
  kubectl get secret -n kiali -o go-template='{{range $secret := .items}}{{with $secret.metadata.annotations}}{{with (index . "kubernetes.io/service-account.name")}}{{if eq . "kiali-service-account"}}{{$secret.data.token | base64decode}}{{end}}{{end}}{{end}}{{end}}'
  ```

For additional details on other authentication methods see the [SSO](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/charter/packages/kiali/Architecture.md#single-sign-on-sso) and [Non-SSO](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/charter/packages/kiali/Architecture.md#non-sso-login) login sections of the architecture document in Big Bang.
