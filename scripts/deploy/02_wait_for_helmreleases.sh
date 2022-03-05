#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

## Array of core HRs
CORE_HELMRELEASES=("gatekeeper" "istio-operator" "istio" "monitoring" "eck-operator" "ek" "fluent-bit" "twistlock" "cluster-auditor" "jaeger" "kiali")

## Array of addon HRs
ADD_ON_HELMRELEASES=("argocd" "authservice" "gitlab" "gitlab-runner" "keycloak" "anchore" "sonarqube" "minio-operator" "minio" "mattermost-operator" "mattermost" "nexus-repository-manager" "velero" "vault" "loki" "promtail" "kyverno" "kyvernopolicies" "tempo")

## Map of values-keys/labels to HRs: Only needed if HR name =/= label name
declare -A ADD_ON_HELMRELEASES_MAP
ADD_ON_HELMRELEASES_MAP["haproxy"]="haproxy-sso"
ADD_ON_HELMRELEASES_MAP["gitlabRunner"]="gitlab-runner"
ADD_ON_HELMRELEASES_MAP["minioOperator"]="minio-operator"
ADD_ON_HELMRELEASES_MAP["mattermostoperator"]="mattermost-operator"
ADD_ON_HELMRELEASES_MAP["nexus"]="nexus-repository-manager"

## Function to test an array contains an element
## Args:
## $1: array to search
## $2: element to search for
function array_contains() {
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in ${!array}; do
        if [[ $element == "$seeking" ]]; then
            in=0
            break
        fi
    done
    return $in
}

## Function to check/wait on HR existence
function check_if_hr_exist() {
    timeElapsed=0
    if [ $1 == "ek" ]; then
      check_package="logging"
    elif [ $1 == "fluent-bit" ]; then
      check_package="fluentbit"
    elif [ $1 == "cluster-auditor" ]; then
      check_package="clusterAuditor"
    elif [ $1 == "eck-operator" ]; then
      check_package="eckoperator"
    elif [ $1 == "gitlab-runner" ]; then
      check_package="gitlabRunner"
    elif [ $1 == "minio-operator" ]; then
      check_package="minioOperator"
    elif [ $1 == "mattermost-operator" ]; then
      check_package="mattermostoperator"
    elif [ $1 == "nexus-repository-manager" ]; then
      check_package="nexus"
    else
      check_package=$1
    fi
    echo "⏳ Checking if $1 HR is enabled"
    if [[ "$(yq e ".${check_package}.enabled" $CI_VALUES_FILE)" == "false" ]] || [[ "$(yq e ".addons.${check_package}.enabled" $CI_VALUES_FILE)" == "false" ]]; then
      echo "$1 HR not enabled, skipping..."
    else
      echo "$1 HR is enabled, waiting..."
      until kubectl get hr -n bigbang $1 &> /dev/null; do
        sleep 5
        timeElapsed=$(($timeElapsed+5))
        if [[ $timeElapsed -ge 60 ]]; then
           echo "❌ Timed out while waiting for $1 HR to exist"
           exit 1
        fi
      done
    fi
}

## Function to wait on all HRs
function wait_all_hr() {
    timeElapsed=0
    while true; do
        hrstatus=$(kubectl get hr -n bigbang -o jsonpath='{.items[*].status.conditions[0].reason}')
        hrready=$(kubectl get hr -n bigbang -o jsonpath='{.items[*].status.conditions[0].status}')
        # HR ArtifactFailed, retry
        artifactfailedcounter=0
        while [[ $artifactfailedcounter -lt 3 ]]; do
            if [[ ! "$hrstatus" =~ ArtifactFailed ]]; then
              break
            else
              artifactfailedcounter=$(($artifactfailedcounter+1))
              echo "⏳ Helm Artifact Failed, waiting 5 seconds."
              sleep 5
              hrstatus=$(kubectl get hr -n bigbang -o jsonpath='{.items[*].status.conditions[0].reason}')
            fi
        done
        # HR *Failed, exit
        if [[ "$hrstatus" =~ Failed ]]; then
            state=$(kubectl get hr -A -o go-template='{{range $items,$contents := .items}}{{printf "HR %s" $contents.metadata.name}}{{printf " status is %s\n" (index $contents.status.conditions 0).reason}}{{end}}')
            failed=$(echo "${state}" | grep "Failed")
            echo "❌ Found failed Helm Release(s). Exiting now."
            echo "❌ ${failed}"
            failed_hrs=$(echo "{$failed}" | awk  '{print $2}')
            for hr in $failed_hrs; do
                kubectl describe hr -n bigbang $hr
            done
            exit 1
        fi
        if [[ "$hrready" != *Unknown* ]]; then
            if [[ "$hrready" != *False* ]]; then
                echo "✅ All HR's deployed"
                break
            fi
        fi
        sleep 5
        timeElapsed=$(($timeElapsed+5))
        if [[ $timeElapsed -ge 3600 ]]; then
            echo "❌ Timed out while waiting for hr's to be ready."
            exit 1
        fi
    done
}

## Function to wait on all statefulsets
function wait_sts() {
   timeElapsed=0
   while true; do
      sts=$(kubectl get sts -A -o jsonpath='{.items[*].status.replicas}' | xargs)
      totalSum=$(echo $sts | awk '{for (i=1; i<=NF; i++) c+=$i} {print c}')
      readySts=$(kubectl get sts -A -o jsonpath='{.items[*].status.readyReplicas}' | xargs)
      readySum=$(echo $readySts | awk '{for (i=1; i<=NF; i++) c+=$i} {print c}')
      if [[ $totalSum -eq $readySum ]]; then
         break
      fi
      sleep 5
      timeElapsed=$(($timeElapsed+5))
      if [[ $timeElapsed -ge 600 ]]; then
         echo "❌ Timed out while waiting for stateful sets to be ready."
         exit 1
      fi
   done
}

## Function to wait on all daemonsets
function wait_daemonset(){
   timeElapsed=0
   while true; do
      dmnset=$(kubectl get daemonset -A -o jsonpath='{.items[*].status.desiredNumberScheduled}' | xargs)
      totalSum=$(echo $dmnset | awk '{for (i=1; i<=NF; i++) c+=$i} {print c}')
      readyDmnset=$(kubectl get daemonset -A -o jsonpath='{.items[*].status.numberReady}' | xargs)
      readySum=$(echo $readyDmnset | awk '{for (i=1; i<=NF; i++) c+=$i} {print c}')
      if [[ $totalSum -eq $readySum ]]; then
         break
      fi
      sleep 5
      timeElapsed=$(($timeElapsed+5))
      if [[ $timeElapsed -ge 600 ]]; then
         echo "❌ Timed out while waiting for daemon sets to be ready."
         exit 1
      fi
   done
}

# Check for and run the wait_project function within <repo>/tests/wait.sh to wait for custom resources
function wait_crd(){
  IFS=$'\n'
  for gitrepo in $(kubectl get gitrepository -n bigbang -o name | grep -v secrets); do
    repourl=$(kubectl get $gitrepo -n bigbang -o jsonpath='{.spec.url}')
    version=$(kubectl get $gitrepo -n bigbang -o jsonpath='{.spec.ref.tag}')
    package=$(kubectl get $gitrepo -n bigbang -o jsonpath='{.metadata.name}')
    if [[ -z "$version" || "$version" == "null" ]]; then
      version=$(kubectl get $gitrepo -n bigbang -o jsonpath='{.spec.ref.branch}')
    fi
    if [[ -z "$version" || "$version" == "null" ]]; then
      continue
    fi
    printf "Checking for tests/wait.sh in %s:%s... " ${package} ${version}
    if curl -f "${repourl%.git}/-/raw/${version}/tests/wait.sh?inline=false" 1>${package}.wait.sh 2>/dev/null; then
      printf "found, running\n"
      . ./${package}.wait.sh
      wait_project
    else
      printf "not found\n"
    fi
  done
  IFS=","
}

## Append all add-ons to hr list if "all-packages" or default branch/tag. Else, add specific ci labels to hr list.
HELMRELEASES=(${CORE_HELMRELEASES[@]})
if [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ "${CI_DEPLOY_LABELS[*]}" =~ "all-packages" ]]; then
    HELMRELEASES+=(${ADD_ON_HELMRELEASES[@]})
    echo "🌌 All helmreleases enabled: all-packages label enabled, or on default branch or tag."
elif [[ ! -z "$CI_DEPLOY_LABELS" ]]; then
    IFS=","
    for package in $CI_DEPLOY_LABELS; do
        # Check if package is in addons
        if array_contains ADD_ON_HELMRELEASES "$package"; then
            HELMRELEASES+=("$package")
        # Check to see if there is a mapping from label -> HR
        elif [ ${ADD_ON_HELMRELEASES_MAP[$package]+_} ]; then
            package="${ADD_ON_HELMRELEASES_MAP[$package]}"
            # Safeguard to doublecheck new package name is valid HR name
            if array_contains ADD_ON_HELMRELEASES "$package"; then
                HELMRELEASES+=("$package")
            fi
        fi
    done
    echo "✅ Found enabled helmreleases: ${HELMRELEASES[@]}"
fi

echo "⏳ Waiting on GitRepositories"
kubectl wait --for=condition=Ready --timeout 180s gitrepositories -n bigbang --all

for package in "${HELMRELEASES[@]}";
do
    check_if_hr_exist "$package"
done

echo "⏳ Waiting on helm releases..."
wait_all_hr
echo "⏳ Waiting for custom resources..."
wait_crd

kubectl get helmreleases,gitrepositories -A

# In case some helm releases are marked as ready before all objects are live...
echo "⏳ Waiting on all jobs, deployments, statefulsets, and daemonsets"
kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
wait_sts
wait_daemonset
if kubectl get job -A -o jsonpath='{.items[].metadata.name}' &> /dev/null; then
  kubectl wait --for=condition=complete --timeout 300s -A job --all > /dev/null
fi
