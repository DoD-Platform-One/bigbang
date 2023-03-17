# Upgrading to a new version

Mattermost is a Big Bang built chart. As a result there is no `Kptfile` to handle any automatic updates from upstream. The below details the steps required to update to a new version of the Mattermost package.

1. Review the [upstream changelog](https://docs.mattermost.com/install/self-managed-changelog.html) for the update you are going to, as well as any versions skipped over between the last BB release and this one. Note any breaking changes and new features.

2. Modify the `image.tag` value in `chart/values.yaml` to point to the newest version of Mattermost.

3. You should check the latest version of `minio-instance` and run `kpt pkg update chart/deps/minio@4.5.4-bb.1 --strategy alpha-git-patch` then `helm dependency update chart` if applicable.

4. Based on the upstream changelog review from earlier, make any changes required to resolve breaking changes.

5. Modify the `version` in `Chart.yaml` - this is a BigBang built and owned chart so we sync the chart version with the appVersion (ex: appVersion `6.6.0` -> chart version `6.6.0-bb.0`). Also modify the `appVersion` and the `bigbang.dev/applicationVersions` to the new upstream version of Mattermost (same version you put in for the image tag value).

6. Update `CHANGELOG.md` adding an entry for the new version and noting all changes (at minimum should include `Updated Mattermost to x.x.x`).

7. Generate the `README.md` updates by following the [guide in gluon](https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-package-readme.md).

8. Validate that `tests/dependencies.yaml` points to the latest tag for `mattermost-operator`. If it doesn't, update it.

9. Open an MR in "Draft" status and validate that CI passes. This will perform a number of smoke tests against the package, but it is good to manually deploy to test some things that CI doesn't. Follow the steps below for manual testing.

10. Once all manual testing is complete take your MR out of "Draft" status and add the review label.

# Testing for updates

NOTE: For these testing steps it is good to do them on both a clean install and an upgrade. For clean install, point mattermost to your branch. For an upgrade do an install with mattermost pointing to the latest tag, then perform a helm upgrade with mattermost pointing to your branch.

You will want to install with:
- Mattermost, Mattermost Operator, and Minio Operator enabled
- Istio enabled
- [Dev SSO values](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/chart/dev-sso-values.yaml) for Mattermost
- [Enterprise enabled](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/7b14b4739b26b900cf7e6f1c075edc33c271eca6/chart/values.yaml#L962) - if you do not pass a license in, navigate to the System Console after install to start a trial
- Elasticsearch enabled + [integration enabled](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/7b14b4739b26b900cf7e6f1c075edc33c271eca6/chart/values.yaml#L1038)
- Monitoring enabled

Testing Steps:
- Log in with SSO via your `login.dso.mil` account.
- Follow the initial setup to create a team and send an initial chat.
- Under account settings, upload a profile picture. Validate the upload is successful and your profile picture is visible.
- Navigate to prometheus and validate that the Mattermost target shows as up (make sure you are on enterprise and have started a trial).
- Under system console -> elastic -> index now and validate success (make sure you are on enterprise and have started a trial).
- Check Grafana for data in the `Mattermost Performance Monitoring v2` dashboard (Ensure you change the server on the dashboard to point to the mattermost pod ip)

When in doubt with any testing or upgrade steps ask one of the CODEOWNERS for assistance.
