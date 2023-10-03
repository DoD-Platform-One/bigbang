# Code Changes for Updates/Renovates

1. Checkout renovate/ironbank branch

2. Check upstream repo for chart updates https://github.com/kiali/helm-charts/tags

3. Check that operator image and upstream chart version match. If operator version matches upstream chart, upgrade chart with kpt.

From the root of the repo run, kpt pkg update chart@<v1.x.x> --strategy alpha-git-patch. Use the version tag you got in step 2-3. You may be prompted to resolve some conflicts - choose what makes sense (if there are BB additions/changes keep them, if there are upstream additions/changes keep them).

4. Modify the `version` in `Chart.yaml` - you will want to append `-bb.0` to the chart version from upstream. update dependencies to latest BB gluon library version.
    ```
    helm dependency update ./chart
    ```

5. Update `CHANGELOG.md` adding an entry for the new version and noting all changes (at minimum should include `Updated Kiali to x.x.x`).

6. Generate the `README.md` updates by following the [guide in gluon](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-package-readme.md).

7. Push up your changes, validate that CI passes. If there are any failures follow the information in the pipeline to make the necessary updates and reach out to the team if needed.

8. Perform the steps below for manual testing. CI provides a good set of basic smoke tests but it is beneficial to run some additional checks.

Manually testing steps TBD