# Default Token Login

Kiali offers 5 options for authentication. Big Bang will default to using the token method.

The token method uses the Kubernetes service account token for authentication. To get the default Kiali SA token for login:

  ```shell
kubectl -n kiali create token kiali-service-account
  ```

For additional details on other authentication methods see the [SSO](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/understanding-bigbang/package-architecture/kiali.md#single-sign-on-sso) and [Non-SSO](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/understanding-bigbang/package-architecture/kiali.md#non-sso-login) login sections of the architecture document in Big Bang.
