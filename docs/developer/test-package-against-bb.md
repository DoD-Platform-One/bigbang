# Testing your package branch against bigbang before package merge

These instructions right now are written for istio changes, but the same is probably true for kyverno and maybe for others as well. CODEOWNERS reviewing MRs should enforce this.

## Run bigbang tests against your branch
As part of your MR that modifies istio you will need to run bigbang tests against your branch. To do this, at a minimum, you will need to
1. Create a new branch on bigbang off of master `git checkout master && git pull && git checkout -b my-bigbang-branch-for-testing`
1. Modify the test values (you may need more than this)
    ```yaml
    myAppPackage:
      git:
        tag: null
        branch: my-package-branch-that-needs-testing
      istio:
        hardened:
          enabled: true
    ```
1. Stage your changes `git add -A`
1. Commit your changes `git commit -m "prepping for test"`
1. Push your changes `git push -u origin my-bigbang-branch-for-testing`
1. Create the bigbang MR as a draft with `TEST ONLY DO NOT MERGE` in the title
1. Wait for tests to finish, and do fixes on your package branch as needed until they pass
1. Close the bigbang MR by deleting the bigbang branch `git push -d origin my-bigbang-branch-for-testing`
1. Link the bigbang MR on your package MR as evidence of your package working in bigbang
