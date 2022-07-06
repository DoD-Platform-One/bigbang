pkgs = [
    "istio-controlplane",
    "istio-operator",
    "jaeger",
    "kiali",
    "cluster-auditor",
    "policy",
    "kyverno",
    "elasticsearch-kibana",
    "eck-operator",
    "fluentbit",
    "promtail",
    "loki",
    "tempo",
    "monitoring",
    "twistlock",
    "argocd",
    "authservice",
    "minio-operator",
    "minio",
    "gitlab",
    "gitlab-runner",
    "nexus",
    "sonarqube",
    "haproxy",
    "anchore-enterprise",
    "mattermost-operator",
    "mattermost",
    "velero",
    "keycloak",
    "vault",
    "kyverno-policies",
    "metrics-server",
]

for pkg in pkgs:
    import subprocess as sp
    import os

    sp.run(
        [
            "mkdir",
            "-p",
            f"base/packages/{pkg}",
        ],
        cwd=os.getcwd(),
        capture_output=True,
        encoding="utf-8",
    )

    sp.run(
        [
            "touch",
            f"base/packages/{pkg}/config.yaml",
        ],
        cwd=os.getcwd(),
        capture_output=True,
        encoding="utf-8",
    )
