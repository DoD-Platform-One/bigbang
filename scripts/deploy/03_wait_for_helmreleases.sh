#!/usr/bin/env bash

set -e
source ${PIPELINE_REPO_DESTINATION}/library/templates.sh

## Function to check/wait on HR existence
function check_if_hr_exist() {
  timeElapsed=0
  map_values_key_to_hr $1
  until kubectl get hr -n bigbang $hrName &> /dev/null; do
    sleep 5
    timeElapsed=$(($timeElapsed+5))
    if [[ $timeElapsed -ge 60 ]]; then
        echo "❌ Timed out while waiting for $hrName HR to exist"
        exit 1
    fi
  done
}

## Function to wait on all HRs
function wait_all_hr() {
    timeElapsed=0
    while true; do
        hrstatus=$(kubectl get hr -n bigbang -o jsonpath='{.items[*].status.conditions[0].reason}')
        hrready=$(kubectl get hr -n bigbang -o jsonpath='{.items[*].status.conditions[0].status}')
        # HR ArtifactFailed, retry
        artifactfailedcounter=0
        while [[ $artifactfailedcounter -lt 75 ]]; do
            if [[ ! "$hrstatus" =~ ArtifactFailed ]]; then
              break
            else
              artifactfailedcounter=$(($artifactfailedcounter+1))
              echo "⏳ Helm Artifact Failed, waiting 10 seconds."
              sleep 10
              hrstatus=$(kubectl get hr -n bigbang -o jsonpath='{.items[*].status.conditions[0].reason}')
            fi
        done
        # HR *Failed, exit
        if [[ "$hrstatus" =~ Failed ]]; then
            state=$(kubectl get hr -A -o go-template='{{range $items,$contents := .items}}{{printf "HR %s" $contents.metadata.name}}{{printf " status is %s\n" (index $contents.status.conditions 0).reason}}{{end}}')
            failed=$(echo "${state}" | grep "Failed")
            echo "❌ Found FAILED Helm Release(s). Exiting now."
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
    if curl -Lf "${repourl%.git}/-/raw/${version}/tests/wait.sh?inline=false" 1>${package}.wait.sh 2>/dev/null; then
      printf "found, running\n"
      . ./${package}.wait.sh
      wait_project
    else
      printf "not found\n"
    fi
  done
  IFS=","
}

# Get a list of all enabled packages based on CI/default values file
PACKAGE_LIST=($(get_packages))
ENABLED_LIST=( )
for package in "${PACKAGE_LIST[@]}"; do
  # Check if package is enabled via CI values file override
  if [[ "$(yq e ".${package}.enabled" $CI_VALUES_FILE)" == "true" ]] || [[ "$(yq e ".addons.${package}.enabled" $CI_VALUES_FILE)" == "true" ]]; then
    ENABLED_LIST+=("$package")
  # Check if package is disabled via CI values file override
  elif [[ "$(yq e ".${package}.enabled" $CI_VALUES_FILE)" == "false" ]] || [[ "$(yq e ".addons.${package}.enabled" $CI_VALUES_FILE)" == "false" ]]; then
    echo "$package is disabled, skipping..."
  # Check if package will be enabled by default values
  elif [[ "$(yq e ".${package}.enabled" $VALUES_FILE)" == "true" ]] || [[ "$(yq e ".addons.${package}.enabled" $VALUES_FILE)" == "true" ]]; then
    ENABLED_LIST+=("$package")
  # Catchall for packages that no override exists for, which are disabled by default
  else
    echo "$package is disabled by default, skipping..."
  fi
done

echo -n "Checking for git repos to wait on..."
if [[ -n $(kubectl get GitRepository -A) ]]; then
  echo "found, ⏳ Waiting on GitRepositories"
  kubectl wait --for=condition=Ready --timeout 180s gitrepositories -n bigbang --all
fi

echo -n "Checking for helm repos to wait on..."
if [[ -n $(kubectl get HelmRepository -A) ]]; then
  echo "found, ⏳ Waiting on HelmRepositories"
  kubectl wait --for=condition=Ready --timeout 180s HelmRepository -n bigbang --all
fi

for package in "${ENABLED_LIST[@]}";
do
  check_if_hr_exist "$package"
done

echo "⏳ Waiting on helm releases..."
wait_all_hr
echo "⏳ Waiting for custom resources..."
wait_crd

# In case some helm releases are marked as ready before all objects are live...
echo "⏳ Waiting on all jobs, deployments, statefulsets, and daemonsets"
kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
wait_sts
wait_daemonset
if kubectl get job -A -o jsonpath='{.items[].metadata.name}' &> /dev/null; then
  kubectl wait --for=condition=complete --timeout 300s -A job --all > /dev/null
fi
