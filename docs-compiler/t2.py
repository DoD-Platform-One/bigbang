pkgs = [
    [
        "submodules/istio-controlplane",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane",
    ],
    [
        "submodules/istio-operator",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-operator",
    ],
    [
        "submodules/jaeger",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/jaeger",
    ],
    ["submodules/kiali", "https://repo1.dso.mil/platform-one/big-bang/apps/core/kiali"],
    [
        "submodules/cluster-auditor",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/cluster-auditor",
    ],
    [
        "submodules/policy",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/policy",
    ],
    [
        "submodules/kyverno",
        "https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno",
    ],
    [
        "submodules/elasticsearch-kibana",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/elasticsearch-kibana",
    ],
    [
        "submodules/eck-operator",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/eck-operator",
    ],
    [
        "submodules/fluentbit",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/fluentbit",
    ],
    [
        "submodules/promtail",
        "https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/promtail",
    ],
    [
        "submodules/loki",
        "https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/loki",
    ],
    [
        "submodules/tempo",
        "https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/tempo",
    ],
    [
        "submodules/monitoring",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/monitoring",
    ],
    [
        "submodules/twistlock",
        "https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock",
    ],
    [
        "submodules/argocd",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/argocd",
    ],
    [
        "submodules/authservice",
        "https://repo1.dso.mil/platform-one/big-bang/apps/core/authservice",
    ],
    [
        "submodules/minio-operator",
        "https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio-operator",
    ],
    [
        "submodules/minio",
        "https://repo1.dso.mil/platform-one/big-bang/apps/application-utilities/minio",
    ],
    [
        "submodules/gitlab",
        "https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab",
    ],
    [
        "submodules/gitlab-runner",
        "https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner",
    ],
    [
        "submodules/nexus",
        "https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus",
    ],
    [
        "submodules/sonarqube",
        "https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/sonarqube",
    ],
    [
        "submodules/haproxy",
        "https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/haproxy",
    ],
    [
        "submodules/anchore-enterprise",
        "https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/anchore-enterprise",
    ],
    [
        "submodules/mattermost-operator",
        "https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost-operator",
    ],
    [
        "submodules/mattermost",
        "https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost",
    ],
    [
        "submodules/velero",
        "https://repo1.dso.mil/platform-one/big-bang/apps/cluster-utilities/velero",
    ],
    [
        "submodules/keycloak",
        "https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/keycloak",
    ],
    [
        "submodules/vault",
        "https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/vault",
    ],
    [
        "submodules/kyverno-policies",
        "https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/kyverno-policies",
    ],
    [
        "submodules/metrics-server",
        "https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/metrics-server.git",
    ],
]

from git import Submodule as sub
import git


def add_submodule(pkg):
    repo = git.Repo(".")
    print(pkg[1])
    # sub.add(
    #     repo,
    #     pkg[1],
    #     path=pkg[0],
    # )


for pkg in pkgs:
    # add_submodule(pkg)
    import subprocess as sp
    import os

    sp.run(
        [
            "git",
            "submodule",
            "add",
            pkg[1],
            pkg[0],
        ],
        cwd=os.getcwd(),
        capture_output=True,
        encoding="utf-8",
    )
