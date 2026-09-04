#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "${test_dir}"' EXIT
mkdir -p "${test_dir}/bin"

cat >"${test_dir}/bin/docker" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"${DOCKER_LOG}"
EOF
chmod +x "${test_dir}/bin/docker"

export PATH="${test_dir}/bin:${PATH}"
export DOCKER_LOG="${test_dir}/docker.log"
export K3D_DEV_POSTGRES_DATABASES="gitlabhq_production,mattermost"
export K3D_DEV_GARAGE_BUCKETS="extra-app"

"${script_dir}/manage.sh" up >/dev/null

[[ $(grep -c '^run -d' "${DOCKER_LOG}") -eq 3 ]]
grep -q 'createdb -U ci -O ci mattermost' "${DOCKER_LOG}"
grep -q 'bucket allow --key .* --read --write --owner ci-gitlab-lfs' "${DOCKER_LOG}"
grep -q 'bucket allow --key .* --read --write --owner extra-app' "${DOCKER_LOG}"
grep -q 'valkey-server .* --appendonly yes' "${DOCKER_LOG}"

echo "developer dependency stack self-check passed"
