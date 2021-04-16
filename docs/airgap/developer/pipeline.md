### Current Pipeline Outline and Notes

<ol>
<li><h4>.pre</h4>

  <ol>
    <li>
      <h4><b>changelog</b></h4> Does a diff to lint what has changed for the logs
    </li>
    <li><h4><b>commits</b></h4> enforces the conventional commits stuff
    </li>
    <li>
      <h4><b>pre vars</b></h4>
      pre checks
    </li>
    <li>
      <h4><b>version</b></h4>
      gets various versions to build a complex version number for the build
    </li>
  </ol>
</li>

<li><h4><b>smoke tests</b></h4>
  <ol>
    <li><h4><b>clean install</b></h4>
      Doesn't really effect airgap, this sets up things like cluster names and such
    </li>
    <li><h4><b>upgrade</b></h4>
      Splits out testing and determines if there are breaking changes for testing of upgrades.
    </li>
  </ol>
</li>

<li><h4><b>network up</b></h4>
  <ol>
    <li><h4><b>airgap/network up</b></h4>
      Creates a VPC and subnets for the cluster to be deployed in.
    </li>
    <li><h4><b>aws/airgap/package</b></h4>
      Packages everything needed for the airgap install into a tar file. This leaves the repositories and images bundled in the Releases section for BB (https://repo1.dso.mil/platform-one/big-bang/bigbang/-/releases)
    </li>
  </ol>
</li>

<li><h4><b>airgap up</b></h4>
  <ol>
    <li><h4><b>aws/airgap/utility up</b></h4>
      Sets up proxies using Route 53 to essentially fake out where Repo 1 and Registry 1 exist for the purposes of using an air gap registry and git repo.
    </li>
  </ol>
</li>

<li><h4><b>cluster up</b></h4>
  <ol>
    <li><h4><b>airgap/rke2/cluster up</b></h4>
      Stands up an RKE2 cluster for BB in an airgapped network. ** Uses terraform ./gitlab-ci/jobs/rke2/dependencies/terraform/

      Both this and the non-airgapped use the same image registry.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates/k3d-builder:0.0.1
    </li>
  </ol>
</li>

<li><h4><b>bigbang up</b></h4>
  <ol>
    <li><h4><b>airgap/rke2/bigbang up</b></h4>
      Stands up big bang
    </li>
  </ol>
</li>

<li><h4><b>test</b></h4>
  <ol>
    <li><h4><b>airgap/rke2/bigbang test</b></h4>
      Runs some basic tests to make sure that Big Bang is up and working.
    </li>
  </ol>
</li>

<li><h4><b>bigbang down</b></h4>
  <ol>
    <li><h4><b>airgap/rke2/bigbang down</b></h4>
      Tears down the Big Bang instance
    </li>
  </ol>
</li>

<li><h4><b>cluster down</b></h4>
  <ol>
    <li><h4><b>airgap/rke2/cluster down</b></h4></li>
  </ol>
</li>

<li><h4><b>airgap down</b></h4>
  <ol>
    <li><h4><b>aws/airgap/package delete</b></h4></li>
    <li><h4><b>aws/airgap/utility down</b></h4></li>
  </ol>
</li>

<li><h4><b>network down</b></h4>
  <ol>
    <li><h4><b>airgap/network down</b></h4></li>
  </ol>
</li>
</ol>

