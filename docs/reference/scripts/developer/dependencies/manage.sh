#!/bin/bash
set -euo pipefail

POSTGRES_IMAGE="registry1.dso.mil/ironbank/opensource/postgres/postgresql:17.11"
GARAGE_IMAGE="registry1.dso.mil/ironbank/opensource/deuxfleurs-org/garage:2.3.0"
VALKEY_IMAGE="registry1.dso.mil/ironbank/afdco/valkey/valkey:9.0.4"

PASSWORD="ci-only-password"
GARAGE_ACCESS_KEY="GKbb0000000000000000000000"
GARAGE_SECRET_KEY="bb00000000000000000000000000000000000000000000000000000000000000"
DEFAULT_GARAGE_BUCKETS="ci-gitlab-lfs,ci-gitlab-artifacts,ci-gitlab-uploads,ci-gitlab-packages,ci-gitlab-mr-diffs,ci-gitlab-terraform-state,ci-gitlab-dependency-proxy,ci-gitlab-pseudo,ci-gitlab-backup,ci-gitlab-backup-tmp,ci-gitlab-registry,gitlab-uploads,mattermost"
NETWORK="k3d-dependencies"
PREFIX="bigbang-dev"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

wait_for() {
  local description=$1
  shift
  for _ in {1..60}; do
    "$@" >/dev/null 2>&1 && return
    sleep 2
  done
  echo "Timed out waiting for ${description}" >&2
  exit 1
}

start_postgres() {
  local name="${PREFIX}-postgresql"
  docker volume create "${name}-data" >/dev/null
  docker rm -f "${name}" >/dev/null 2>&1 || true
  docker run -d --name "${name}" --network "${NETWORK}" --network-alias postgresql \
    --ip 172.30.0.10 -e POSTGRES_USER=ci -e POSTGRES_PASSWORD="${PASSWORD}" \
    -v "${name}-data:/var/lib/postgresql/data" "${POSTGRES_IMAGE}" \
    -c max_connections=300 -c shared_preload_libraries=pg_stat_statements >/dev/null
  wait_for PostgreSQL docker exec "${name}" pg_isready -U ci
}

provision_databases() {
  local name="${PREFIX}-postgresql" database
  while IFS= read -r database; do
    [[ "${database}" =~ ^[a-z][a-z0-9_]*$ ]] || {
      echo "Invalid PostgreSQL database name: ${database}" >&2
      exit 1
    }
    docker exec "${name}" psql -U ci -d postgres -tAc \
      "SELECT 1 FROM pg_database WHERE datname = '${database}'" | grep -q 1 ||
      docker exec "${name}" createdb -U ci -O ci "${database}"
  done < <(printf '%s\n' "${K3D_DEV_POSTGRES_DATABASES}" | tr ',' '\n')
}

start_garage() {
  local name="${PREFIX}-garage"
  docker volume create "${name}-meta" >/dev/null
  docker volume create "${name}-data" >/dev/null
  docker rm -f "${name}" >/dev/null 2>&1 || true
  docker run -d --name "${name}" --network "${NETWORK}" --network-alias garage \
    --ip 172.30.0.11 \
    -e GARAGE_DEFAULT_ACCESS_KEY="${GARAGE_ACCESS_KEY}" \
    -e GARAGE_DEFAULT_SECRET_KEY="${GARAGE_SECRET_KEY}" \
    -e GARAGE_DEFAULT_BUCKET=ci-default \
    -v "${script_dir}/garage.toml:/etc/garage.toml:ro" \
    -v "${name}-meta:/var/lib/garage/meta" -v "${name}-data:/var/lib/garage/data" \
    "${GARAGE_IMAGE}" /garage server --single-node --default-bucket >/dev/null
  wait_for Garage docker exec "${name}" /garage status
  docker exec "${name}" /garage key allow --create-bucket "${GARAGE_ACCESS_KEY}" >/dev/null
}

provision_buckets() {
  local name="${PREFIX}-garage" bucket
  while IFS= read -r bucket; do
    [[ -z "${bucket}" ]] && continue
    [[ "${bucket}" =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]] || {
      echo "Invalid Garage bucket name: ${bucket}" >&2
      exit 1
    }
    docker exec "${name}" /garage bucket create "${bucket}" >/dev/null 2>&1 || true
    docker exec "${name}" /garage bucket allow --key "${GARAGE_ACCESS_KEY}" \
      --read --write --owner "${bucket}" >/dev/null
  done < <(printf '%s\n' "${DEFAULT_GARAGE_BUCKETS},${K3D_DEV_GARAGE_BUCKETS:-}" | tr ',' '\n')
}

start_valkey() {
  local name="${PREFIX}-valkey"
  docker volume create "${name}-data" >/dev/null
  docker rm -f "${name}" >/dev/null 2>&1 || true
  docker run -d --name "${name}" --network "${NETWORK}" --network-alias valkey \
    --ip 172.30.0.12 -v "${name}-data:/data" \
    --entrypoint valkey-server "${VALKEY_IMAGE}" \
    --requirepass "${PASSWORD}" --appendonly yes >/dev/null
  wait_for Valkey docker exec "${name}" valkey-cli -a "${PASSWORD}" ping
}

[[ "${1:-}" == "up" ]] || { echo "usage: $0 up" >&2; exit 1; }
docker network inspect "${NETWORK}" >/dev/null
start_postgres
provision_databases
start_garage
provision_buckets
start_valkey

echo "PostgreSQL: postgresql:5432 (ci / ${PASSWORD})"
echo "Garage: http://garage:3900 (${GARAGE_ACCESS_KEY} / ${GARAGE_SECRET_KEY})"
echo "Valkey: valkey:6379 (${PASSWORD})"
