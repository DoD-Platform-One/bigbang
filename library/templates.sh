#!/bin/sh
#
#-----------------------------------------------------------------------------------------------------------------------
#
# Shell environment settings for verbosity and debugging
#
#-----------------------------------------------------------------------------------------------------------------------

# prevent it from being run standalone, which would do nothing
if [[ $BASH_SOURCE == $0 ]]; then
  echo "$0 is used to set env variables in the current shell and must be sourced to work"
  echo "examples: . $0" 
  echo "          source $0"
  exit 1 
fi

if [[ $DEBUG_ENABLED == "true" || "$CI_MERGE_REQUEST_TITLE" == *"DEBUG"*  ]]; then
  echo "DEBUG_ENABLED is set to true, setting -x in bash"
  set -x
fi

trap 'echo ❌ exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR

#-----------------------------------------------------------------------------------------------------------------------
#
# Wait Functions
#
#-----------------------------------------------------------------------------------------------------------------------

wait_sts() {
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
         echo "Timed out while waiting for stateful sets to be ready."
         exit 1
      fi
   done
}

wait_daemonset(){
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
         echo "Timed out while waiting for daemon sets to be ready."
         exit 1
      fi
   done
}

#-----------------------------------------------------------------------------------------------------------------------
#
# Bigbang Functions
#
#-----------------------------------------------------------------------------------------------------------------------
check_changes() {
   # only run on MR events
   if [[ $CI_PIPELINE_SOURCE != "merge_request_event" ]]; then
     exit 0
   fi

   echo -e "\e[0Ksection_start:`date +%s`:check_changes[collapsed=true]\r\e[0K\e[33;1mCheck Changes\e[37m"
   
   ## Array of addon packages
   CHECK_PACKAGES=($(yq e '(.*.git | select(. != null) | (path | .[-2]), .addons.*.git | select(. != null) | (path | .[-2])' "${VALUES_FILE}"))

   ## Array of templates
   TEMPLATES=($(find chart/templates -type d | cut -b 17-))

   ## Collect package configurations on the target (master) branch
   git fetch &>/dev/null && git checkout ${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}
   mkdir -p target-branch/values
   mkdir -p target-branch/templates
   cp -R chart/templates/* target-branch/templates
   for package in "${CHECK_PACKAGES[@]}"; do
        # Save all top-level package configs to their own file
        if [[ $(yq e '(.*.git | select(. != null) | (path | .[-2])' "${VALUES_FILE}") =~ "${package}" ]]; then
              yq e ".$package" "${VALUES_FILE}" > target-branch/values/$package.yaml
        # Save all package configs in .addons to their own file
        elif [[ $(yq e '(.addons.*.git | select(. != null) | (path | .[-2])' "${VALUES_FILE}") =~ "${package}" ]]; then
              yq e ".addons.$package" "${VALUES_FILE}" > target-branch/values/$package.yaml
        fi 
   done

   ## Collect package configurations on the source branch
   git fetch &>/dev/null && git checkout ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}
   git config user.email "checkchange@function.com"
   git config user.name "checkchange"
   git merge origin/${CI_MERGE_REQUEST_TARGET_BRANCH_NAME} --no-commit || (echo -e "\e[31mError: Source branch, ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}, has conflicts with target branch, ${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}. Please rebase your branch and re-run the pipeline.\e[0m" && exit 1)
   mkdir -p source-branch/values
   mkdir -p source-branch/templates
   cp -R chart/templates/* source-branch/templates
   for package in "${CHECK_PACKAGES[@]}"; do
        # Save all top-level package configs to their own file
        if [[ $(yq e '(.*.git | select(. != null) | (path | .[-2])' "${VALUES_FILE}") =~ "${package}" ]]; then
              yq e ".$package" "${VALUES_FILE}" > source-branch/values/$package.yaml
        # Save all package configs in .addons to their own file
        elif [[ $(yq e '(.addons.*.git | select(. != null) | (path | .[-2])' "${VALUES_FILE}") =~ "${package}" ]]; then
              yq e ".addons.$package" "${VALUES_FILE}" > source-branch/values/$package.yaml
        fi 
   done
  
   ## Check for package changes in chart/values.yaml
   for package in "${CHECK_PACKAGES[@]}"; do
        if [[ $(diff target-branch/values/$package.yaml source-branch/values/$package.yaml) ]]; then
              CHANGED_PACKAGES+=("$package")
        fi
   done

   ## Check for package changes in chart/templates
   for package in "${TEMPLATES[@]}"; do
        if [[ $(diff -r target-branch/templates/$package source-branch/templates/$package) ]]; then
              # Rename packages in chart/templates to match chart/values.yaml and handle subdirectories
              if [[ "$package" == "gitlab-runner" ]]; then
                      package="gitlabRunner"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "nexus-repository-manager" ]]; then
                      package="nexus"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "kyverno/policies" ]]; then
                      package="kyvernopolicies"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "logging/elasticsearch-kibana" ]]; then
                      package="logging"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "logging/eck-operator" ]]; then
                      package="eckoperator"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "logging/fluentbit" ]]; then
                      package="fluentbit"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "logging/loki" ]]; then
                      package="loki"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "logging/promtail" ]]; then
                      package="promtail"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "mattermost/mattermost" ]]; then
                      package="mattermost"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "mattermost/operator" ]]; then
                      package="mattermostoperator"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "minio/minio" ]]; then
                      package="minio"
                      CHANGED_PACKAGES+=("$package")
              elif [[ "$package" == "minio/minio-operator" ]]; then
                      package="minioOperator"
                      CHANGED_PACKAGES+=("$package")
              else
                      CHANGED_PACKAGES+=("$package")
              fi 
        fi
   done 

   if [[ -z "$CHANGED_PACKAGES" ]]; then
        echo "✅ No changes have been made to any packages"
   else
        echo "✅ Changes have been made to these packages: ${CHANGED_PACKAGES[@]}"
   fi

   echo -e "\e[0Ksection_end:`date +%s`:check_changes\r\e[0K"
}

label_check() {
   set -e
   # only run on MR events
   if [[ $CI_PIPELINE_SOURCE != "merge_request_event" ]]; then
     exit 0
   fi
   echo -e "\e[0Ksection_start:`date +%s`:label_check[collapsed=true]\r\e[0K\e[33;1mLabel Check\e[37m"
   ## Show current labels
   OLD_IFS=$IFS
   IFS=","
   LABEL_CHECK_DEPLOY_LABELS+=("${CI_MERGE_REQUEST_LABELS[*]}")

   for package in ${CHANGED_PACKAGES[*]}; do
      if [[ ! "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "${package}" ]]; then
         LABEL_CHECK_DEPLOY_LABELS+=("${package}")
         echo "    Added "${package}"" 
      else 
         echo "    "${package}" already enabled"
      fi
   done

   if [[ "${CI_COMMIT_BRANCH}" == "${CI_DEFAULT_BRANCH}" ]] || [[ ! -z "$CI_COMMIT_TAG" ]] || [[ ${CI_MERGE_REQUEST_LABELS[*]} =~ "all-packages" ]]; then
      echo "🌌 all-packages label enabled, or on default branch or tag, enabling all addons"
      LABEL_CHECK_DEPLOY_LABELS+=( "${CI_MERGE_REQUEST_LABELS[*]}" )
   else
      LABEL_CHECK_DEPLOY_LABELS+=( "${CI_MERGE_REQUEST_LABELS[*]}" )
      echo "Initial MR labels: ${LABEL_CHECK_DEPLOY_LABELS[*]} "
      echo "Evaluating package dependencies..."
      if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "mattermost" ]]; then
         echo "  Checking mattermost"
         if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "mattermostoperator" ]]; then
            echo "    mattermostoperator already enabled"
         else 
            LABEL_CHECK_DEPLOY_LABELS+=("mattermostoperator")
            echo "    Added mattermostoperator"
         fi
         if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "minioOperator" ]]; then
            echo "    minioOperator already enabled"
         else 
            LABEL_CHECK_DEPLOY_LABELS+=("minioOperator")
            echo "    Added minioOperator"
         fi
      fi
      if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "promtail" ]]; then
         echo "  Checking promtail"
         if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "loki" ]]; then
            echo "    loki already enabled"
         else 
            LABEL_CHECK_DEPLOY_LABELS+=("loki")
            echo "    Added loki"
         fi
      fi
      if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "loki" ]]; then
         echo "  Checking loki"
         if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "minioOperator" ]]; then
            echo "    minioOperator already enabled"
         else 
            LABEL_CHECK_DEPLOY_LABELS+=("minioOperator")
            echo "    Added minioOperator"
         fi
      fi
      if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ (^|,)"minio"(,|$) ]]; then
         echo "  Checking minio"
         if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "minioOperator" ]]; then
            echo "    minioOperator already enabled"
         else 
            LABEL_CHECK_DEPLOY_LABELS+=("minioOperator")
            echo "    Added minioOperator"
         fi
      fi
      if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ (^|,)"gitlabRunner"(,|$) ]]; then
         echo "  Checking gitlabRunner"
         if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ (^|,)"gitlab"(,|$) ]]; then
            echo "    gitlab already enabled"
         else 
            LABEL_CHECK_DEPLOY_LABELS+=("gitlab")
            echo "    Added gitlab"
         fi
      fi
      if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "velero" ]]; then
         echo "  Checking velero"
         if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ (^|,)"minio"(,|$) ]]; then
            echo "    minio already enabled"
         else 
            LABEL_CHECK_DEPLOY_LABELS+=("minio")
            echo "    Added minio"
         fi
         if [[ "${LABEL_CHECK_DEPLOY_LABELS[*]}" =~ "minioOperator" ]]; then
            echo "    minioOperator already enabled"
         else 
            LABEL_CHECK_DEPLOY_LABELS+=("minioOperator")
            echo "    Added minioOperator"
         fi
      fi
   fi

   # Remove empty array elements    
   NEW=()
   for i in "${LABEL_CHECK_DEPLOY_LABELS[@]}"; do
      if [ -z "$i" ]; then
        continue
      fi
      NEW+=("${i}")
   done
   LABEL_CHECK_DEPLOY_LABELS=(${NEW[@]})

   echo "CI_DEPLOY_LABELS=${LABEL_CHECK_DEPLOY_LABELS[*]}" >> variables.env
   CI_TEMP_OUT=( "${LABEL_CHECK_DEPLOY_LABELS[*]}" )
   IFS=$OLD_IFS
   echo "Labels after check: ${CI_TEMP_OUT[*]}"
   echo -e "\e[0Ksection_end:`date +%s`:label_check\r\e[0K"
}

deploy_bigbang() {
   set -e
   for deploy_script in $(find ./${PIPELINE_REPO_DESTINATION}/scripts/deploy -type f -name '*.sh' | sort); do
     chmod +x ${deploy_script}
     echo -e "\e[0Ksection_start:`date +%s`:${deploy_script##*/}[collapsed=true]\r\e[0K\e[33;1m${deploy_script##*/}\e[37m"  
     ./${deploy_script}
     echo -e "\e[0Ksection_end:`date +%s`:${deploy_script##*/}\r\e[0K"
   done
}

test_bigbang() {
   set -e
   for test_script in $(find ./${PIPELINE_REPO_DESTINATION}/scripts/tests -type f -name '*.sh' | sort); do
     echo -e "\e[0Ksection_start:`date +%s`:${test_script##*/}[collapsed=true]\r\e[0K\e[33;1m${test_script##*/}\e[37m"        
     chmod +x ${test_script}
     echo "Executing ${test_script}..."
     ./${test_script} && export EXIT_CODE=$? || export EXIT_CODE=$?
     if [[ ${EXIT_CODE} -ne 0 ]]; then
       if [[ ${EXIT_CODE} -ne 123 ]]; then
         echo -e "\e[31m❌ ${test_script} failed, see log output above and cluster debug.\e[0m"
         exit ${EXIT_CODE}
       fi
       # 123 error codes are allowed to continue
       echo -e "\e[31m⚠️ ${test_script} failed but was allowed to continue, see log output above and cluster debug.\e[0m"
       EXIT_FLAG=1
     fi
     echo -e "\e[0Ksection_end:`date +%s`:${test_script##*/}\r\e[0K"
   done
   if [[ -n "$EXIT_FLAG" ]]; then
     echo -e "\e[31m⚠️ WARNING: One or more BB tests failed but were allowed to continue. See output of scripts above for details.\e[0m"
   fi
}

pre_vars() {
   # Create the TF_VAR_env variable
   echo "TF_VAR_env=$(echo $CI_COMMIT_REF_SLUG | cut -c 1-7)-$(echo $CI_COMMIT_SHA | cut -c 1-7)" >> variables.env
   # Calculate a unique cidr range for vpc
   if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]] && [[ "$CI_COMMIT_BRANCH" == "master" ]] || [[ "$CI_MERGE_REQUEST_LABELS" = *"test-ci::infra"* ]]; then
     echo "TF_VAR_vpc_cidr=$(python3 ${PIPELINE_REPO_DESTINATION}/infrastructure/aws/dependencies/get-vpc.py | tr -d '\n' | tr -d '\r')" >> variables.env
   fi
   cat variables.env
}

bigbang_additional_images() {
    echo -e "\e[0Ksection_start:`date +%s`:additional_images[collapsed=true]\r\e[0K\e[33;1mAdditional Images from Packages\e[37m"
    # Fetch list of all package level images in `tests/images.txt`
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
      if curl -f "${repourl%.git}/-/raw/${version}/tests/images.txt?inline=false" 1>${package}.images.txt 2>/dev/null; then
        cat ${package}.images.txt | sed -e '$a\' >> images.txt
      fi
    done
    sort -u -o images.txt images.txt
    echo -e "\e[0Ksection_end:`date +%s`:additional_images\r\e[0K"
}

bigbang_package_repos() {
   set -e
   echo -e "\e[0Ksection_start:`date +%s`:package_repos[collapsed=true]\r\e[0K\e[33;1mPackage Repos\e[37m"
   trap 'echo ❌ exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR
   mkdir -p repos/
   # "Package" ourselves
   # Do it this way on purpose (instead of cp or rsync) to ensure this never includes any unwanted "build" artifacts
   git -C repos/ clone -b ${CI_COMMIT_REF_NAME} ${CI_PROJECT_URL}
   # Clone core
   yq e ".*.git.repo | select(. != null) | path | .[-3] " "${VALUES_FILE}" | while IFS= read -r package; do
     git -C repos/ clone --no-checkout $(yq e ".${package}.git.repo" "${VALUES_FILE}")
   done
   # Clone addons
   yq e ".addons.*.git.repo | select(. != null) | path | .[-3]" "${VALUES_FILE}" | while IFS= read -r package; do
     git -C repos/ clone --no-checkout $(yq e ".addons.${package}.git.repo" "${VALUES_FILE}")
   done
   tar -czf $REPOS_PKG repos/
   echo -e "\e[0Ksection_end:`date +%s`:package_repos\r\e[0K"
}

bigbang_prep(){
   echo -e "\e[0Ksection_start:`date +%s`:bb_prep[collapsed=true]\r\e[0K\e[33;1mPrep\e[37m"
   mkdir -p release
   mv $IMAGE_LIST $IMAGE_PKG $REPOS_PKG $PACKAGE_IMAGE_FILE release/
   echo -e "\e[0Ksection_end:`date +%s`:bb_prep\r\e[0K"
}

bigbang_publish() {
   echo -e "\e[0Ksection_start:`date +%s`:bb_publish[collapsed=true]\r\e[0K\e[33;1mPublish\e[37m"
   if [ -z $CI_COMMIT_TAG ]; then
     aws s3 sync --quiet release/ s3://umbrella-bigbang-releases/tests/${CI_COMMIT_SHA}
   else
     aws s3 sync --quiet release/ s3://umbrella-bigbang-releases/umbrella/${CI_COMMIT_TAG}
   fi
   echo -e "\e[0Ksection_end:`date +%s`:bb_publish\r\e[0K"
}

bigbang_release() {
   echo -e "\e[0Ksection_start:`date +%s`:bb_release[collapsed=true]\r\e[0K\e[33;1mRelease\e[37m"
   if [ -z $CI_COMMIT_TAG ]; then
     RELEASE_ENDPOINT="https://${RELEASE_BUCKET}.s3-${AWS_DEFAULT_REGION}.amazonaws.com/tests/${CI_COMMIT_SHA}"
     printf "Release will run: \n\
       release-cli create --name \"Big Bang \${CI_COMMIT_TAG}\" --tag-name \${CI_COMMIT_TAG} \n\
       --description \"Automated release notes are a WIP.\" \n\
       --assets-link \"{\"name\":\"${IMAGE_LIST}\",\"url\":\"${RELEASE_ENDPOINT}/${IMAGE_LIST}\"}\" \n\
       --assets-link \"{\"name\":\"${PACKAGE_IMAGE_FILE}\",\"url\":\"${RELEASE_ENDPOINT}/${PACKAGE_IMAGE_FILE}\"}\" \n\
       --assets-link \"{\"name\":\"${IMAGE_PKG}\",\"url\":\"${RELEASE_ENDPOINT}/${IMAGE_PKG}\"}\" \n\
       --assets-link \"{\"name\":\"${REPOS_PKG}\",\"url\":\"${RELEASE_ENDPOINT}/${REPOS_PKG}\"}\"\n"
   else
     release-cli create --name "Big Bang ${CI_COMMIT_TAG}" --tag-name ${CI_COMMIT_TAG} \
       --description "Automated release notes are a WIP." \
       --assets-link "{\"name\":\"${IMAGE_LIST}\",\"url\":\"${RELEASE_ENDPOINT}/${IMAGE_LIST}\"}" \
       --assets-link "{\"name\":\"${PACKAGE_IMAGE_FILE}\",\"url\":\"${RELEASE_ENDPOINT}/${PACKAGE_IMAGE_FILE}\"}" \
       --assets-link "{\"name\":\"${IMAGE_PKG}\",\"url\":\"${RELEASE_ENDPOINT}/${IMAGE_PKG}\"}" \
       --assets-link "{\"name\":\"${REPOS_PKG}\",\"url\":\"${RELEASE_ENDPOINT}/${REPOS_PKG}\"}"
   fi
   echo -e "\e[0Ksection_end:`date +%s`:bb_release\r\e[0K"
}

clone_bigbang_and_merge_templates() {
   echo -e "\e[0Ksection_start:`date +%s`:clone_and_checkout_bigbang[collapsed=true]\r\e[0K\e[33;1mClone Big Bang and Merge\e[37m"
   git clone ${BB_REPO} ${BB_REPO_DESTINATION}
   cd ${BB_REPO_DESTINATION}
   if [[ $BB_VERSION != "latest" ]]; then
     git checkout ${BB_VERSION}
   elif [[ $(yq e '. | has("bb-version")' ../tests/test-values.yaml) == "true" ]]; then 
     git checkout $(yq e '.bb-version' ../tests/test-values.yaml)
   else
     git checkout $(git describe --tags $(git rev-list --tags --max-count=1))
   fi
   cp -r ../bigbang/templates/* ./chart/templates/
   PIPELINE_REPO_DESTINATION="../pipeline-repo"
   package=$(yq e '. | keys | .[0]' ../bigbang/values.yaml)
   if [[ $(yq ".${package}.git | has(\"tag\")" ../bigbang/values.yaml) == "true" ]]; then
     yq e -i "del(.${package}.git.tag)" ../bigbang/values.yaml
   fi
   if [[ ! -z ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME} ]]; then
     yq e -i ".${package}.git.branch = \"${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}\"" ../bigbang/values.yaml
   else
     yq e -i ".${package}.git.branch = \"${CI_DEFAULT_BRANCH}\"" ../bigbang/values.yaml
   fi 
   
   yq eval-all 'select(fileIndex == 0) * select(filename == "../bigbang/values.yaml")' ${CI_VALUES_FILE} ../bigbang/values.yaml > tmpfile && mv tmpfile ${CI_VALUES_FILE} 
   echo -e "\e[0Ksection_end:`date +%s`:clone_and_checkout_bigbang\r\e[0K"
}

#-----------------------------------------------------------------------------------------------------------------------
#
# Package Functions
#
#-----------------------------------------------------------------------------------------------------------------------
dependency_install() {
   echo -e "\e[0Ksection_start:`date +%s`:dependency_install[collapsed=true]\r\e[0KDependency Install"
   if [ -f "tests/dependencies.yaml" ]; then
     yq e ".*.git | path | .[-2]" "tests/dependencies.yaml" | while IFS= read -r i; do
       dep_name=$i
       dep_repo=$(yq e ".${i}.git.repo" "tests/dependencies.yaml")
       if [[ -z ${dep_repo} || ${dep_repo} == "null" ]]; then
         dep_repo=$(yq e ".${i}.git" "tests/dependencies.yaml")
         if [[ -z ${dep_repo} || ${dep_repo} == "null" ]]; then
           continue
         fi
       fi
       dep_branch=$(yq e ".${i}.git.tag" "tests/dependencies.yaml")
       if [[ -z ${dep_branch} || ${dep_branch} == "null" ]]; then
         dep_branch=$(yq e ".${i}.branch" "tests/dependencies.yaml")
       fi
       dep_namespace=$(yq e ".${i}.namespace" "tests/dependencies.yaml")
       if [[ -z ${dep_namespace} || ${dep_namespace} == "null" ]]; then
         dep_namespace=$dep_name
       fi
       dep_helm_name=$(yq e ".${i}.package-name" "tests/dependencies.yaml")
       if [[ -z ${dep_helm_name} || ${dep_helm_name} == "null" ]]; then
         dep_helm_name=$dep_name
       fi
       dep_ns_label=$(yq e ".${i}.namespace-label" "tests/dependencies.yaml")
       if [[ -z ${dep_ns_label} || ${dep_ns_label} == "null" ]]; then
         dep_ns_label=$dep_helm_name
       fi
       if [[ -d ${dep_branch} || ${dep_branch} == "null" ]]; then
         if [[ -d "repos/${dep_name}" ]]; then
           echo "Checking out default branch from ${dep_repo}"
           cd repos/${dep_name}
           git reset --hard && git clean -fd
           git checkout $(git remote show origin | awk '/HEAD branch/ {print $NF}')
           cd ../../
         else
           echo "Cloning default branch from ${dep_repo}"
           git clone ${dep_repo} repos/${dep_name}
         fi
       else
         if [[ -d "repos/${dep_name}" ]]; then
           echo "Checking out ${dep_branch} from ${dep_repo}"
           cd repos/${dep_name}
           git reset --hard && git clean -fd
           git checkout ${dep_branch}
           cd ../../
         else
           echo "Cloning ${dep_branch} from ${dep_repo}"
           git clone -b ${dep_branch} ${dep_repo} repos/${dep_name}
         fi
       fi
       echo "Installing dependency: repos/${dep_name} into ${dep_namespace} namespace"
       if ! kubectl get namespace ${dep_namespace} 2> /dev/null; then
         kubectl create namespace ${dep_namespace}
         kubectl label namespace ${dep_namespace} app.kubernetes.io/name=${dep_ns_label} --overwrite=true
       fi
       if ! kubectl get secret -n ${dep_namespace} private-registry 2> /dev/null; then
         kubectl create -n ${dep_namespace} secret docker-registry private-registry --docker-server="https://registry1.dso.mil" --docker-username="${REGISTRY1_USER}" --docker-password="${REGISTRY1_PASSWORD}"
       fi
       if [ $(ls -1 repos/${dep_name}/tests/test-values.y*ml 2>/dev/null | wc -l) -gt 0 ]; then
         echo "Helm installing repos/${dep_name}/chart into ${dep_namespace} namespace using repos/${dep_name}/tests/test-values.yaml for values"
         helm upgrade -i --wait --timeout 600s ${dep_helm_name} repos/${dep_name}/chart -n ${dep_namespace} -f repos/${dep_name}/tests/test-values.y*ml --set istio.enabled=false
       else
         echo "Helm installing repos/${dep_name}/chart into ${dep_namespace} namespace using default values"
         helm upgrade -i --wait --timeout 600s ${dep_helm_name} repos/${dep_name}/chart -n ${dep_namespace} --set istio.enabled=false
       fi
     done
   fi
   echo -e "\e[0Ksection_end:`date +%s`:dependency_install\r\e[0K"
}

dependency_wait() {
   echo -e "\e[0Ksection_start:`date +%s`:dependency_wait[collapsed=true]\r\e[0KDependency Wait"
   if [ -f "tests/dependencies.yaml" ]; then
     sleep 10
     echo -n "Waiting on CRDS ... "
     kubectl wait --for=condition=established --timeout 60s -A crd --all > /dev/null
     echo "done."
     if [ -f tests/dependencies.yaml ]; then
       yq e ".*.git | path | .[-2]" "tests/dependencies.yaml" | while IFS= read -r i; do
         dep_name=$i
         if [ -f repos/${dep_name}/tests/wait.sh ]; then
           source repos/${dep_name}/tests/wait.sh
           echo -n "Waiting on dependency resources ... "
           wait_project
           echo "done."
         fi
       done
     fi
     echo -n "Waiting on stateful sets ... "
     wait_sts
     echo "done."
     echo -n "Waiting on daemon sets ... "
     wait_daemonset
     echo "done."
     echo -n "Waiting on deployments ... "
     kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
     echo "done."
     echo -n "Waiting on terminating pods ... "
     readarray -t DELPODS < <(kubectl get pods -A -o jsonpath='{range .items[?(@.metadata.deletionTimestamp)]}{@.metadata.namespace}{" "}{@.metadata.name}{"\n"}{end}')
     for DELPOD in "${DELPODS[@]}"; do
       if kubectl get pod -n $DELPOD &> /dev/null; then
         kubectl wait --for=delete --timeout 60s pod -n $DELPOD > /dev/null
       fi
     done
     echo "done."
     echo -n "Waiting on running pods to be ready ... "
     kubectl wait --for=condition=ready --timeout 600s -A pods --all --field-selector status.phase=Running > /dev/null
     echo "done."
   fi
   echo -e "\e[0Ksection_end:`date +%s`:dependency_wait\r\e[0K"
}

package_install() {
  echo -e "\e[0Ksection_start:`date +%s`:package_install[collapsed=true]\r\e[0KPackage Install"
  if [ ! -z ${PROJECT_NAME} ]; then
    if [ ${PACKAGE_HELM_NAME} == ${CI_PROJECT_NAME} ]; then
      PACKAGE_HELM_NAME=${PROJECT_NAME}
    fi
  fi
  if ! kubectl get namespace ${PACKAGE_NAMESPACE} 2> /dev/null; then
    kubectl create namespace ${PACKAGE_NAMESPACE}
    if [ ! -z ${PACKAGE_NS_LABEL} ]; then
      kubectl label namespace ${PACKAGE_NAMESPACE} app.kubernetes.io/name=${PACKAGE_NS_LABEL} --overwrite=true
    else
      kubectl label namespace ${PACKAGE_NAMESPACE} app.kubernetes.io/name=${PACKAGE_HELM_NAME} --overwrite=true
    fi
  fi
  if ! kubectl get secret -n ${PACKAGE_NAMESPACE} private-registry 2> /dev/null; then
    kubectl create -n ${PACKAGE_NAMESPACE} secret docker-registry private-registry --docker-server="https://registry1.dso.mil" --docker-username="${REGISTRY1_USER}" --docker-password="${REGISTRY1_PASSWORD}"
  fi
  if [[ $DISABLE_HELM_UPGRADE_WAIT =~ ("true"|"1") ]]; then
    echo "DISABLE_HELM_UPGRADE_WAIT has been set to true, not passing the --wait argument to helm"
    helmarg=""
  else
    helmarg="--wait"
  fi
  if [ $(ls -1 tests/test-values.y*ml 2>/dev/null | wc -l) -gt 0 ]; then
    echo "Helm installing ${CI_PROJECT_NAME}/chart into ${PACKAGE_NAMESPACE} namespace using ${CI_PROJECT_NAME}/tests/test-values.yaml for values"
    helm upgrade -i ${helmarg} --timeout 600s ${PACKAGE_HELM_NAME} chart -n ${PACKAGE_NAMESPACE} -f tests/test-values.y*ml --set istio.enabled=false
  else
    echo "Helm installing ${CI_PROJECT_NAME}/chart into ${PACKAGE_NAMESPACE} namespace using default values"
    helm upgrade -i ${helmarg} --timeout 600s ${PACKAGE_HELM_NAME} chart -n ${PACKAGE_NAMESPACE} --set istio.enabled=false
  fi
  echo -e "\e[0Ksection_end:`date +%s`:package_install\r\e[0K"
}

package_wait() {
   echo -e "\e[0Ksection_start:`date +%s`:package_wait[collapsed=true]\r\e[0KPackage Wait"
   sleep 10
   echo -n "Waiting on CRDs ... "
   kubectl wait --for=condition=established --timeout 60s -A crd --all > /dev/null
   echo "done."
   if [ -f tests/wait.sh ]; then
     source tests/wait.sh
     echo -n "Waiting on project resources ... "
     wait_project
     echo "done."
   fi
   echo -n "Waiting on stateful sets ... "
   wait_sts
   echo "done."
   echo -n "Waiting on daemon sets ... "
   wait_daemonset
   echo "done."
   echo -n "Waiting on deployments ... "
   kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
   echo "done."
   echo -n "Waiting on terminating pods ... "
   readarray -t DELPODS < <(kubectl get pods -A -o jsonpath='{range .items[?(@.metadata.deletionTimestamp)]}{@.metadata.namespace}{" "}{@.metadata.name}{"\n"}{end}')
   for DELPOD in "${DELPODS[@]}"; do
     if kubectl get pod -n $DELPOD &> /dev/null; then
       kubectl wait --for=delete --timeout 60s pod -n $DELPOD > /dev/null
     fi
   done
   echo "done."
   echo -n "Waiting on running pods to be ready ... "
   kubectl wait --for=condition=ready --timeout 600s -A pods --all --field-selector status.phase=Running > /dev/null
   echo "done."
   echo -e "\e[0Ksection_end:`date +%s`:package_wait\r\e[0K"
}

post_install_packages() {
   echo -e "\e[0Ksection_start:`date +%s`:post_install_packages[collapsed=true]\r\e[0KPost Install Packages"
   if [ -f "tests/post-install-packages.yaml" ]; then
     yq e ".*.git | path | .[-2]" "tests/post-install-packages.yaml" | while IFS= read -r i; do
       post_name=$i
       post_repo=$(yq e ".${i}.git.repo" "tests/post-install-packages.yaml")
       if [[ -z ${post_repo} || ${post_repo} == "null" ]]; then
         post_repo=$(yq e ".${i}.git" "tests/post-install-packages.yaml")
         if [[ -z ${post_repo} || ${post_repo} == "null" ]]; then
           continue
         fi
       fi
       post_branch=$(yq e ".${i}.git.tag" "tests/post-install-packages.yaml")
       if [[ -z ${post_branch} || ${post_branch} == "null" ]]; then
         post_branch=$(yq e ".${i}.branch" "tests/post-install-packages.yaml")
       fi
       post_namespace=$(yq e ".${i}.namespace" "tests/post-install-packages.yaml")
       if [[ -z ${post_namespace} || ${post_namespace} == "null" ]]; then
         post_namespace=$post_name
       fi
       post_helm_name=$(yq e ".${i}.package-name" "tests/post-install-packages.yaml")
       if [[ -z ${post_helm_name} || ${post_helm_name} == "null" ]]; then
         post_helm_name=$post_name
       fi
       post_ns_label=$(yq e ".${i}.namespace-label" "tests/post-install-packages.yaml")
       if [[ -z ${post_ns_label} || ${post_ns_label} == "null" ]]; then
         post_ns_label=$post_helm_name
       fi
       if [[ -d ${post_branch} || ${post_branch} == "null" ]]; then
         if [[ -d "repos/${post_name}" ]]; then
           echo "Checking out default branch from ${post_repo}"
           cd repos/${post_name}
           git reset --hard && git clean -fd
           git checkout $(git remote show origin | awk '/HEAD branch/ {print $NF}')
           cd ../../
         else
           echo "Cloning default branch from ${post_repo}"
           git clone ${post_repo} repos/${post_name}
         fi
       else
         if [[ -d "repos/${post_name}" ]]; then
           echo "Checking out ${post_branch} from ${post_repo}"
           cd repos/${post_name}
           git reset --hard && git clean -fd
           git checkout ${post_branch}
           cd ../../
         else
           echo "Cloning ${post_branch} from ${post_repo}"
           git clone -b ${post_branch} ${post_repo} repos/${post_name}
         fi
       fi
       echo "Installing post install package: repos/${post_name} into ${post_namespace} namespace"
       if ! kubectl get namespace ${post_namespace} 2> /dev/null; then
         kubectl create namespace ${post_namespace}
         kubectl label namespace ${post_namespace} app.kubernetes.io/name=${post_ns_label} --overwrite=true
       fi
       if ! kubectl get secret -n ${post_namespace} private-registry 2> /dev/null; then
         kubectl create -n ${post_namespace} secret docker-registry private-registry --docker-server="https://registry1.dso.mil" --docker-username="${REGISTRY1_USER}" --docker-password="${REGISTRY1_PASSWORD}"
       fi
       if [ $(ls -1 repos/${post_name}/tests/test-values.y*ml 2>/dev/null | wc -l) -gt 0 ]; then
         echo "Helm installing repos/${post_name}/chart into ${post_namespace} namespace using repos/${post_name}/tests/test-values.yaml for values"
         helm upgrade -i --wait --timeout 600s ${post_helm_name} repos/${post_name}/chart -n ${post_namespace} -f repos/${post_name}/tests/test-values.y*ml --set istio.enabled=false
       else
         echo "Helm installing repos/${post_name}/chart into ${post_namespace} namespace using default values"
         helm upgrade -i --wait --timeout 600s ${post_helm_name} repos/${post_name}/chart -n ${post_namespace} --set istio.enabled=false
       fi
     done
   fi
   echo -e "\e[0Ksection_end:`date +%s`:post_install_packages\r\e[0K"
}

post_install_wait() {
   echo -e "\e[0Ksection_start:`date +%s`:post_install_wait[collapsed=true]\r\e[0KPost Install Wait"
   if [ -f "tests/post-install-packages.yaml" ]; then
     sleep 10
     echo -n "Waiting on CRDS ... "
     kubectl wait --for=condition=established --timeout 60s -A crd --all > /dev/null
     echo "done."
     if [ -f tests/post-install-packages.yaml ]; then
       yq e ".*.git | path | .[-2]" "tests/post-install-packages.yaml" | while IFS= read -r i; do
         post_name=$i
         if [ -f repos/${post_name}/tests/wait.sh ]; then
           source repos/${post_name}/tests/wait.sh
           echo -n "Waiting on post install resources ... "
           wait_project
           echo "done."
         fi
       done
     fi
     echo -n "Waiting on stateful sets ... "
     wait_sts
     echo "done."
     echo -n "Waiting on daemon sets ... "
     wait_daemonset
     echo "done."
     echo -n "Waiting on deployments ... "
     kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
     echo "done."
     echo -n "Waiting on terminating pods ... "
     readarray -t DELPODS < <(kubectl get pods -A -o jsonpath='{range .items[?(@.metadata.deletionTimestamp)]}{@.metadata.namespace}{" "}{@.metadata.name}{"\n"}{end}')
     for DELPOD in "${DELPODS[@]}"; do
       if kubectl get pod -n $DELPOD &> /dev/null; then
         kubectl wait --for=delete --timeout 60s pod -n $DELPOD > /dev/null
       fi
     done
     echo "done."
     echo -n "Waiting on running pods to be ready ... "
     kubectl wait --for=condition=ready --timeout 600s -A pods --all --field-selector status.phase=Running > /dev/null
     echo "done."
   fi
   echo -e "\e[0Ksection_end:`date +%s`:post_install_wait\r\e[0K"
}

package_test() {
   echo -e "\e[0Ksection_start:`date +%s`:package_test[collapsed=true]\r\e[0KPackage Test"
   if [ -d "chart/templates/tests" ]; then
     helm test -n ${PACKAGE_NAMESPACE} ${PACKAGE_HELM_NAME} && export EXIT_CODE=$? || export EXIT_CODE=$?
     echo "***** Start Helm Test Logs *****"
     kubectl logs --all-containers=true --tail=-1 -n ${PACKAGE_NAMESPACE} -l helm-test=enabled
     echo "***** End Helm Test Logs *****"
     if [[ -n `ls /cypress/screenshots/${PACKAGE_NAMESPACE}/* 2>/dev/null` ]]; then
       mkdir -p cypress-artifacts/screenshots
       mv /cypress/screenshots/${PACKAGE_NAMESPACE}/* ./cypress-artifacts/screenshots
     fi
     if [[ -n `ls /cypress/videos/${PACKAGE_NAMESPACE}/* 2>/dev/null` ]]; then
       mkdir -p cypress-artifacts/videos
       mv /cypress/videos/${PACKAGE_NAMESPACE}/* ./cypress-artifacts/videos
     fi
     #### Begin backwards compatibility for configmap videos (gluon 0.2.5 and earlier) ####
     if kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-screenshots &>/dev/null; then
       kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-screenshots -o jsonpath='{.data.cypress-screenshots\.tar\.gz\.b64}' > cypress-screenshots.tar.gz.b64
       cat cypress-screenshots.tar.gz.b64 | base64 -d > cypress-screenshots.tar.gz
       mkdir -p cypress-artifacts
       tar -zxf cypress-screenshots.tar.gz --strip-components=2 -C cypress-artifacts
     fi
     if kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-videos &>/dev/null; then
       kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-videos -o jsonpath='{.data.cypress-videos\.tar\.gz\.b64}' > cypress-videos.tar.gz.b64
       cat cypress-videos.tar.gz.b64 | base64 -d > cypress-videos.tar.gz
       mkdir -p cypress-artifacts
       tar -zxf cypress-videos.tar.gz --strip-components=2 -C cypress-artifacts
     fi
     #### End backwards compatibility for configmap videos  (gluon 0.2.5 and earlier) ####
     if [[ ${EXIT_CODE} -ne 0 ]]; then
       exit ${EXIT_CODE}
     fi
   fi
   echo -e "\e[0Ksection_end:`date +%s`:package_test\r\e[0K"
}

# Note: This section is temporarily duplicated to allow upgrade testing to fail if tests were not built to handle subsuquent runs
# Due to some of the quirks with Gitlab CI "script blocks" this is the easiest solution
# This block should be removed in the future and line 397 updated to just call `package_test`
package_upgrade_test() {
   echo -e "\e[0Ksection_start:`date +%s`:package_test2[collapsed=true]\r\e[0KPackage Re-Test"
   if [ -d "chart/templates/tests" ]; then
     rm -rf /cypress/screenshots
     rm -rf /cypress/videos
     rm -rf ./cypress-artifacts/screenshots
     rm -rf ./cypress-artifacts/videos
     helm test -n ${PACKAGE_NAMESPACE} ${PACKAGE_HELM_NAME} && export EXIT_CODE=$? || export EXIT_CODE=$?
     echo "***** Start Helm Test Logs *****"
     kubectl logs --all-containers=true --tail=-1 -n ${PACKAGE_NAMESPACE} -l helm-test=enabled
     echo "***** End Helm Test Logs *****"
     if [[ -n `ls /cypress/screenshots/${PACKAGE_NAMESPACE}/* 2>/dev/null` ]]; then
       mkdir -p cypress-artifacts/screenshots
       mv /cypress/screenshots/${PACKAGE_NAMESPACE}/* ./cypress-artifacts/screenshots
     fi
     if [[ -n `ls /cypress/videos/${PACKAGE_NAMESPACE}/* 2>/dev/null` ]]; then
       mkdir -p cypress-artifacts/videos
       mv /cypress/videos/${PACKAGE_NAMESPACE}/* ./cypress-artifacts/videos
     fi

     #### Begin backwards compatibility for configmap videos (gluon 0.2.5 and earlier) ####
     if kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-screenshots &>/dev/null; then
       kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-screenshots -o jsonpath='{.data.cypress-screenshots\.tar\.gz\.b64}' > cypress-screenshots.tar.gz.b64
       cat cypress-screenshots.tar.gz.b64 | base64 -d > cypress-screenshots.tar.gz
       mkdir -p cypress-artifacts
       tar -zxf cypress-screenshots.tar.gz --strip-components=2 -C cypress-artifacts
     fi
     if kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-videos &>/dev/null; then
       kubectl get configmap -n ${PACKAGE_NAMESPACE} cypress-videos -o jsonpath='{.data.cypress-videos\.tar\.gz\.b64}' > cypress-videos.tar.gz.b64
       cat cypress-videos.tar.gz.b64 | base64 -d > cypress-videos.tar.gz
       mkdir -p cypress-artifacts
       tar -zxf cypress-videos.tar.gz --strip-components=2 -C cypress-artifacts
     fi
     #### End backwards compatibility for configmap videos (gluon 0.2.5 and earlier) ####

     if [[ ${EXIT_CODE} -ne 0 ]]; then
       echo -e "\e[31mNOTICE to MR creators/reviewers: There were errors on upgrade testing. If this package's tests are expected to fail when run twice in a row, please open a ticket to resolve this for the future.\e[0m"
       echo -e "\e[31mOtherwise, take note of artifacts and testing results and ensure that the upgrade path is functional before approving/merging.\e[0m"
       exit 123
     fi
   fi
   echo -e "\e[0Ksection_end:`date +%s`:package_test2\r\e[0K"
}

package_structure() {
    echo -e "\e[0Ksection_start:`date +%s`:package_tree[collapsed=true]\r\e[0KPackage Directory Structure"
    tree .
    echo -e "\e[0Ksection_end:`date +%s`:package_tree\r\e[0K"
}

global_policy_tests() {
   echo -e "\e[0Ksection_start:`date +%s`:generic_policy_tests[collapsed=true]\r\e[0KGlobal Policy Tests"
   if [ $(ls -1 tests/test-values.y*ml 2>/dev/null | wc -l) -gt 0 ]; then
     echo "Checking test values..."
     helm conftest chart --policy ${GENERIC_POLICY_PATH} -f tests/test-values.y*ml
     echo "Checking chart values..."
     helm conftest chart --policy ${GENERIC_POLICY_PATH}
   else
     helm conftest chart --policy ${GENERIC_POLICY_PATH}
   fi
   echo -e "\e[0Ksection_end:`date +%s`:generic_policy_tests\r\e[0K"
}

package_policy_tests() {
   echo -e "\e[0Ksection_start:`date +%s`:package_specific_tests[collapsed=true]\r\e[0KPackage Specific Tests"
   if [ -d "tests/policy" ]; then
     echo "App specific configuration validation tests:"
     if [ $(ls -1 tests/test-values.y*ml 2>/dev/null | wc -l) -gt 0 ]; then
       echo "Checking test values..."
       helm conftest chart --policy tests/policy -f tests/test-values.y*ml
       echo "Checking chart values..."
       helm conftest chart --policy tests/policy
     else
       helm conftest chart --policy tests/policy
     fi
   fi
   echo -e "\e[0Ksection_end:`date +%s`:package_specific_tests\r\e[0K"
}

package_deprecation_check() {
   echo -e "\e[0Ksection_start:`date +%s`:package_deprecation_check[collapsed=true]\r\e[0KPackage API Deprecation Check"
   API_EXIT_CODE=0
   helm template ${PACKAGE_HELM_NAME} chart -n ${PACKAGE_NAMESPACE} --set monitoring.enabled=true --set istio.enabled=true --set networkPolicies.enabled=true -f tests/test-values.y*ml | pluto detect -owide - && export API_EXIT_CODE=$? || export API_EXIT_CODE=$?
   if [[ ${API_EXIT_CODE} -eq 2 ]]; then
     echo -e "\e[31mNOTICE: A deprecated apiVersion has been found.\e[0m"
   elif [[ ${API_EXIT_CODE} -eq 3 ]]; then
     echo -e "\e[31mNOTICE: A removed apiVersion has been found.\e[0m"
   fi
   echo -e "\e[0Ksection_end:`date +%s`:package_deprecation_check\r\e[0K"
}

package_oscal_validate() {
   if [[ -f "oscal-component.yaml" ]]; then
   echo -e "\e[0Ksection_start:`date +%s`:package_oscal_validate[collapsed=true]\r\e[0KPackage OSCAL validation check"
   OSCAL_EXIT_CODE=0
   echo -n "oscal-component.yaml found, validating... "
   yq eval oscal-component.yaml -o=json > tmp_oscal-component.json
   jsonschema -i tmp_oscal-component.json ${PIPELINE_REPO_DESTINATION}/oscal/oscal_component_schema.json -o pretty || export OSCAL_EXIT_CODE=$?
   if [[ ${OSCAL_EXIT_CODE} -ne 0 ]]; then
     echo "OSCAL is not valid."
     OSCAL_EXIT_CODE=4
   else
     echo "OSCAL is valid."
   fi
   echo -e "\e[0Ksection_end:`date +%s`:package_oscal_validate\r\e[0K"
   fi
}

changelog_format_check() {
  firstLine=1
  hasAtLeastOneVersion=0
  hasAtLeastOneTypeOfChange=0
  hasAtLeastOneComment=0
  exitFlag=0
  hasComment=1
  hasTypeOfChange=1
  nonstandardHeader=0

  # Adds a new line to end of changelog for proper parsing
  if [ "$(tail -c 1 ./CHANGELOG.md)" != "" ]; then
    echo "" >> ./CHANGELOG.md
    echo -e "\e[31mError: Changelog must end with a new line.\e[0m"
    exitFlag=1
  fi

  while IFS= read -r line; do
    if [[ $firstLine == 1 ]]; then
      # ensure first line says changelog
      if [[ ! "$line"  =~ ^\#[[:space:]]Changelog ]]; then
        echo -e "\e[31mError: Changelog must start with '# Changelog'. For correct formatting, see https://keepachangelog.com/en/1.0.0/ \e[0m"
        exitFlag=1
      fi
      firstLine=0
    fi
    # Check for version/section header
    if [[ "$line" =~ ^\#\#[[:space:]].+ ]]; then
      if [[ "$line" =~ ^\#\#[[:space:]]\[[[0-9]+\.[0-9]+\.[0-9]+.*\].* ]]; then
        # version header
        if [[ $hasTypeOfChange == 0 ]]; then
          echo -e "\e[31mError: Changelog - version $prevVersion is missing a changetype header. For correct formatting, see https://keepachangelog.com/en/1.0.0/ \e[0m"
          exitFlag=1
        fi
        hasTypeOfChange=0
        hasAtLeastOneVersion=1
        if [[ $nonstandardHeader == 0 ]]; then
          prevVersion=$line
        else
          # we had been ignoring the lines above this (IE malformed version) -- keep prevVersion the same
          nonstandardHeader=0
        fi
      elif [[ "$line" =~ ^\#\#[[:space:]]\[[a-zA-Z]+\] ]]; then
        # section header
        # don't want to count anything below section title
        nonstandardHeader=1
      else
        echo -e "\e[31mError: Changelog header $line is in the wrong format. For correct formatting, see https://keepachangelog.com/en/1.0.0/ \e[0m"
        exitFlag=1
        # malformed header, set to make sure we don't count anything that comes after it
        nonstandardHeader=1
      fi
    fi
    # Check for changetype
    if [[ "$line" =~ ^\#\#\#[[:space:]]+ && $nonstandardHeader == 0 ]]; then
      hasAtLeastOneTypeOfChange=1
      hasTypeOfChange=1
      if [[ $hasComment == 0 ]]; then
        echo -e "\e[31mError: Changelog - version $prevVersion is missing a comment for the [$prevChangetype] changetype. For correct formatting, see https://keepachangelog.com/en/1.0.0/ \e[0m"
        exitFlag=1
      fi
      hasComment=0
      prevChangetype=$line
    fi
    # Check for comment
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]] && $nonstandardHeader == 0 ]]; then
      hasAtLeastOneComment=1
      hasComment=1
    fi
  done < ./CHANGELOG.md
  # check final section format
  if [[ $hasComment == 0 ]]; then
    echo -e "\e[31mError: Changelog - version $prevVersion is missing a comment. For correct formatting, see https://keepachangelog.com/en/1.0.0/ \e[0m"
    exitFlag=1
  fi
  if [[ $hasTypeOfChange == 0 ]]; then
    echo -e "\e[31mError: Changelog - version $prevVersion is missing a changetype header. For correct formatting, see https://keepachangelog.com/en/1.0.0/ \e[0m"
    exitFlag=1
  fi
  # check globally if sections are missing
  if [[ $hasAtLeastOneVersion == 0 ]]; then
    echo -e "\e[31mError: Changelog is missing the app version (IE '## [1.0.0]') or is formatted incorrectly. For correct formatting, see https://keepachangelog.com/en/1.0.0/ \e[0m"
    exitFlag=1
  fi
  if [[ $hasAtLeastOneTypeOfChange == 0 ]]; then
    echo -e "\e[31mError: Changelog is missing the changetype (IE '### Added' or '### Changed') or is formatted incorrectly. For correct formatting, see https://keepachangelog.com/en/1.0.0/ \e[0m"
    exitFlag=1
  fi
  if [[ $hasAtLeastOneComment == 0 ]]; then
    echo -e "\e[31mError: Changelog is missing comments or they are formatted incorrectly. For correct formatting, see https://keepachangelog.com/en/1.0.0/ \e[0m"
    exitFlag=1
  fi
  if [[ $exitFlag == 1 ]]; then
    exit 1
  else
    echo -e "Changelog is valid"
  fi
}

chart_update_check() {
   # change to target branch and check if Chart.yaml or Changelog missing. If so, check source.
   echo -e "\e[0Ksection_start:`date +%s`:chart_changelog_checks[collapsed=true]\r\e[0KChecking for Chart.yaml/CHANGELOG updates"
   git fetch && git checkout ${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}
   if [ ! -f "chart/Chart.yaml" ] || [ ! -f "CHANGELOG.md" ]; then
     # change to source branch and check if Chart.yaml or Changelog missing. If one or both are missing, fail.
     git fetch && git checkout ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}
     if [ ! -f "chart/Chart.yaml" ] || [ ! -f "CHANGELOG.md" ]; then
       echo -e "\e[0Ksection_end:`date +%s`:chart_changelog_checks\r\e[0K"
       echo -e "\e[31mFAIL: Package must have chart/Chart.yaml and CHANGELOG.md\e[0m"
       exit 1
     else
       # target branch is missing Chart.yaml or Changelog. Exit with notice.
       echo -e "\e[0Ksection_end:`date +%s`:chart_changelog_checks\r\e[0K"
       echo -e "\e[31mNOTICE: Chart.yaml or Changelog not found in ${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}, skipping update check\e[0m"
       exit 0
     fi
     # return to target branch
     git fetch && git checkout ${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}
   fi
   cp CHANGELOG.md /tmp/CHANGELOG.md
   echo -e "\e[0Ksection_end:`date +%s`:chart_changelog_checks\r\e[0K"
   DEFAULT_BRANCH_VERSION=$(yq e '.version' chart/Chart.yaml)
   echo "Old Chart Version:$DEFAULT_BRANCH_VERSION"
   echo -e "\e[0Ksection_start:`date +%s`:package_checkout2[collapsed=true]\r\e[0KPackage MR Checkout"
   git reset --hard && git clean -fd
   git checkout ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}
   echo -e "\e[0Ksection_end:`date +%s`:package_checkout2\r\e[0K"
   MR_BRANCH_VERSION=$(yq e '.version' chart/Chart.yaml)
   echo "New Chart Version:$MR_BRANCH_VERSION"
   README_BRANCH_MATCH=$(cat README.md | grep "Version:\s${MR_BRANCH_VERSION}" || true)
   if [ "$MR_BRANCH_VERSION" == "$DEFAULT_BRANCH_VERSION" ]; then
     echo -e "\e[31mNOTICE: You need to bump chart version in Chart.yaml\e[0m"
     EXIT="true"
   fi
   if [ -z "$README_BRANCH_MATCH" ]; then
        echo -e "\e[31mNOTICE: You need to re-generate the README.md - for template and instructions, see: https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-package-readme.md\e[0m"
        EXIT="true"
   fi
   if [ "$(cat /tmp/CHANGELOG.md)" == "$(cat CHANGELOG.md)" ]; then
     echo -e "\e[31mNOTICE: You need to update CHANGELOG.md\e[0m"
     EXIT="true"
   fi
   if [ "$EXIT" == "true" ]; then
     exit 1
   fi
}

dependency_images() {
   echo -e "\e[0Ksection_start:`date +%s`:dep_images[collapsed=true]\r\e[0KGetting List of Dependency Images"
   deps=$(timeout 65 bash -c "until docker exec -i k3d-${CI_JOB_ID}-server-0 crictl images -o json; do sleep 10; done;")
   echo $deps | jq -r '.images[].repoTags[0] | select(. != null)' | tee dependencies.txt
   echo -e "\e[0Ksection_end:`date +%s`:dep_images\r\e[0K"
}

installed_images() {
   echo -e "\e[0Ksection_start:`date +%s`:inst_images[collapsed=true]\r\e[0KGetting List of Installed Images"
   images=$(timeout 65 bash -c "until docker exec -i k3d-${CI_JOB_ID}-server-0 crictl images -o json; do sleep 10; done;")
   echo $images | jq -r '.images[].repoTags[0] | select(. != null)' | tee full-list.txt
   echo -e "\e[0Ksection_end:`date +%s`:inst_images\r\e[0K"
}

image_list_creation() {
   echo -e "\e[0Ksection_start:`date +%s`:image_fetch[collapsed=true]\r\e[0KImage List Creation"
   (grep -Fxvf dependencies.txt full-list.txt || true) | tee images.txt
   sed -i '/docker.io\/rancher\//d' images.txt
   if [ -f tests/images.txt ]; then
     cat tests/images.txt >> images.txt
   fi
   echo -e "\e[0Ksection_end:`date +%s`:image_fetch\r\e[0K"
}

synker_pull() {
   echo -e "\e[0Ksection_start:`date +%s`:synker[collapsed=true]\r\e[0KRunning Synker and Tar"
   cp ${PIPELINE_REPO_DESTINATION}/synker/synker.yaml ./synker.yaml
   for image in $(cat images.txt); do
     yq -i e "(.source.images |= . + \"${image}\")" "./synker.yaml"
   done
   synker pull -b=1
   cp /usr/local/bin/synker synker.yaml /var/lib/registry/
   tar -czvf $IMAGE_PKG /var/lib/registry
   echo -e "\e[0Ksection_end:`date +%s`:synker\r\e[0K"
}

package_repos() {
   echo -e "\e[0Ksection_start:`date +%s`:repos[collapsed=true]\r\e[0KPacking up Repos"
   mkdir -p repos/
   if [ -z ${CI_COMMIT_TAG} ]; then
     git -C repos/ clone -b ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME} ${CI_REPOSITORY_URL}
   else
     git -C repos/ clone -b ${CI_COMMIT_TAG} ${CI_REPOSITORY_URL}
   fi
   tar -czf $REPOS_PKG repos/
   echo -e "\e[0Ksection_end:`date +%s`:repos\r\e[0K"
}

package_prep() {
   echo -e "\e[0Ksection_start:`date +%s`:prep[collapsed=true]\r\e[0KFinal Prep"
   mkdir -p release
   mv $IMAGE_LIST $IMAGE_PKG $REPOS_PKG release/
   echo -e "\e[0Ksection_end:`date +%s`:prep\r\e[0K"
}

package_publish() {
   echo -e "\e[0Ksection_start:`date +%s`:publish[collapsed=true]\r\e[0KPublishing"
   if [ -z $CI_COMMIT_TAG ]; then
     aws configure set aws_region ${TEST_AWS_DEFAULT_REGION}
     aws configure set aws_access_key_id ${TEST_AWS_ACCESS_KEY_ID}
     aws configure set aws_secret_access_key ${TEST_AWS_SECRET_ACCESS_KEY}
     aws s3 cp --quiet release/${IMAGE_LIST} s3://${RELEASE_BUCKET}/tests/${CI_PROJECT_NAME}/${CI_COMMIT_SHA}/
     aws s3 cp --quiet release/${IMAGE_PKG} s3://${RELEASE_BUCKET}/tests/${CI_PROJECT_NAME}/${CI_COMMIT_SHA}/
     aws s3 cp --quiet release/${REPOS_PKG} s3://${RELEASE_BUCKET}/tests/${CI_PROJECT_NAME}/${CI_COMMIT_SHA}/
   else
     aws s3 sync --quiet release/ s3://${RELEASE_BUCKET}/packages/${CI_PROJECT_NAME}/${CI_COMMIT_TAG}
   fi
   echo -e "\e[0Ksection_end:`date +%s`:publish\r\e[0K"
}

package_release_notes() {
   echo -e "\e[0Ksection_start:`date +%s`:notes[collapsed=true]\r\e[0KGenerating Release Notes"
   echo "# RELEASE NOTES:" >> release_notes.txt
   if [ -z $CI_COMMIT_TAG ]; then
     echo "Please see the repo [documentation](${CI_PROJECT_URL}/-/tree/${CI_COMMIT_SHA}/docs) for additional info on this package." >> release_notes.txt
   else
     echo "Please see the repo [documentation](${CI_PROJECT_URL}/-/tree/${CI_COMMIT_TAG}/docs) for additional info on this package." >> release_notes.txt
   fi
   release_notes=$(cat CHANGELOG.md | sed  "1,/## \[${CI_COMMIT_TAG}]/d;/## \[/Q")
   if [[ -z $release_notes ]]; then
     printf "\n" >> release_notes.txt;
     echo "NO ENTRY IN CHANGELOG FOR THIS TAG, ADD RELEASE NOTES HERE" >> release_notes.txt;
   else
     printf "\n" >> release_notes.txt;
     echo "${release_notes}" >> release_notes.txt;
   fi
   echo -e "\e[31mNOTICE: Release notes saved to artifact release_notes.txt\e[0m"
   echo -e "\e[0Ksection_end:`date +%s`:notes\r\e[0K"
   echo -e "\e[0Ksection_start:`date +%s`:reqDependencies[collapsed=true]\r\e[0KRequired Dependencies"
   if [[ -f tests/dependencies.yaml ]]; then
      printf "\nIf you are using the artifacts from this release, please note that you may need to install some dependencies. It is recommended to check the architecture document for this package under [Big Bang's charter](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/charter/packages) for the most accurate info about what may be required. The dependencies used in CI are:\n" >> release_notes.txt
      echo "Dependencies found:"
      keys=$(yq e 'keys' ./tests/dependencies.yaml)
      while read line; do
          key=$(echo "$line" | yq e '.[]' -)
          repo=$(yq e ".$key.git.repo" ./tests/dependencies.yaml)
          if [[ -z "$repo" ]]; then
              # in case yaml file doesn't actually have a repo member.
              repo=$(yq e ".$key.git" ./tests/dependencies.yaml)
          fi
          printf "\55 %-20s %20s\n" "$key" "$repo" >> release_notes.txt
          printf "\55 %-20s %20s\n" "$key" "$repo"
      done <<< "$keys"
   else
    echo "No dependencies to report."
   fi
   echo -e "\e[0Ksection_end:`date +%s`:reqDependencies\r\e[0K"
}

package_release() {
   echo -e "\e[0Ksection_start:`date +%s`:release[collapsed=true]\r\e[0KCreating Release"
   if [ -z $CI_COMMIT_TAG ]; then
     RELEASE_ENDPOINT="https://${RELEASE_BUCKET}.s3-${TEST_AWS_DEFAULT_REGION}.amazonaws.com/tests/${CI_PROJECT_NAME}/${CI_COMMIT_SHA}"
     printf "Release will run: \n\
       release-cli create --name \"\${RELEASE_NAME} \${CI_COMMIT_SHA}\" --tag-name \${CI_COMMIT_SHA} \n\
         --description \"\$(cat release_notes.txt)\" \n\
         --assets-link \"{\"name\":\"${IMAGE_LIST}\",\"url\":\"${RELEASE_ENDPOINT}/${IMAGE_LIST}\"}\" \n\
         --assets-link \"{\"name\":\"${IMAGE_PKG}\",\"url\":\"${RELEASE_ENDPOINT}/${IMAGE_PKG}\"}\" \n\
         --assets-link \"{\"name\":\"${REPOS_PKG}\",\"url\":\"${RELEASE_ENDPOINT}/${REPOS_PKG}\"}\"\n"
   else
     release-cli create --name "${RELEASE_NAME} ${CI_COMMIT_TAG}" --tag-name ${CI_COMMIT_TAG} \
       --description "$(cat release_notes.txt)" \
       --assets-link "{\"name\":\"${IMAGE_LIST}\",\"url\":\"${RELEASE_ENDPOINT}/${IMAGE_LIST}\"}" \
       --assets-link "{\"name\":\"${IMAGE_PKG}\",\"url\":\"${RELEASE_ENDPOINT}/${IMAGE_PKG}\"}" \
       --assets-link "{\"name\":\"${REPOS_PKG}\",\"url\":\"${RELEASE_ENDPOINT}/${REPOS_PKG}\"}"
   fi
   echo -e "\e[0Ksection_end:`date +%s`:release\r\e[0K"
}

get_chart_version() {
   # change to target branch and check if Chart.yaml or Changelog missing. If so, check source.
   echo -e "\e[0Ksection_start:`date +%s`:get_chart_version[collapsed=true]\r\e[0KGetting Chart Version"
   if [ ! -f "chart/Chart.yaml" ]; then
     echo -e "\e[31mFAIL: Package must have chart/Chart.yaml\e[0m"
     echo -e "\e[0Ksection_end:`date +%s`:get_chart_version\r\e[0K"
     exit 1
   else
     CHART_VERSION=$(yq e '.version' chart/Chart.yaml)
     echo "Using Chart version: ${CHART_VERSION}"
   fi
   echo -e "\e[0Ksection_end:`date +%s`:get_chart_version\r\e[0K"
}

create_tag() {
   echo -e "\e[0Ksection_start:`date +%s`:create_tag[collapsed=true]\r\e[0KCreating Tag"
   echo "Running tag create command..."
   tag_output=$(curl --request POST --header "PRIVATE-TOKEN: ${TOKEN_TAG}" "https://repo1.dso.mil/api/v4/projects/${CI_PROJECT_ID}/repository/tags?tag_name=${CHART_VERSION}&ref=${CI_DEFAULT_BRANCH}" 2>/dev/null)
   if [[ $(echo $tag_output | jq -r '.name') == "${CHART_VERSION}" ]]; then
     echo "Tag ${CHART_VERSION} created successfully."
     echo -e "\e[0Ksection_end:`date +%s`:create_tag\r\e[0K"
   elif [[ $(echo $tag_output | jq -r '.message') =~ "already exists" ]]; then
     echo -e "\e[31mNOTICE: Tag Exists. If this change does not require a new package release this is OK. Otherwise this needs to be looked at further\e[0m"
     echo -e "\e[0Ksection_end:`date +%s`:create_tag\r\e[0K"
     exit 201
   else
     echo -e "\e[31mFAILED: Tag Not Created: \e[0m"
     echo $tag_output
     echo -e "\e[0Ksection_end:`date +%s`:create_tag\r\e[0K"
     exit 1
   fi
}

create_bigbang_merge_request() {
    echo -e "\e[0Ksection_start:`date +%s`:create_bigbang_merge_request[collapsed=true]\r\e[0KCreating Big Bang Merge Request"
    ## If MR contains "skip-bb-mr" dont create Big Bang merge request
    GITLAB_PROJECTS_API_ENDPOINT="https://repo1.dso.mil/api/v4/projects"
    BB_MR_ID=$(curl -s "${GITLAB_PROJECTS_API_ENDPOINT}/${CI_PROJECT_ID}/merge_requests?state=merged" | jq '.[] | "\(.iid) \(.merged_at)"' | sort -t ' ' -k2.1,2.4nr -k2.6,2.7nr -k2.9,2.10nr -k2.12,2.13nr -k2.15,2.16nr -k2.18,2.19nr -k2.21,2.23nr | head -1 | tr -d '"' |cut -d' ' -f1)
    MR_LABELS=$(curl "${GITLAB_PROJECTS_API_ENDPOINT}/${CI_PROJECT_ID}/merge_requests/${BB_MR_ID}" | jq '"\(.labels)"')
    if [[ "${MR_LABELS}" == *"skip-bb-mr"* ]]; then
      echo "Skipping auto Big Bang merge request."
      exit
    fi

    echo "Creating new Big Bang merge request..."
    ## Determine which package needs to be updated in the Big Bang chart

    # Account for packages that have a different name in Big Bang's values file vs the name of the package repo
    # The package name is needed to edit the Big Bang chart/values.yaml
    if [[ ${CI_PROJECT_NAME} == "istio-controlplane" ]]; then
        package="istio"
    elif [[ ${CI_PROJECT_NAME} == "istio-operator" ]]; then 
        packgage="istiooperator"
    elif [[ ${CI_PROJECT_NAME} == "cluster-auditor" ]]; then 
        package="clusterAuditor"
    elif [[ ${CI_PROJECT_NAME} == "policy" ]]; then 
        package="gatekeeper"
    elif [[ ${CI_PROJECT_NAME} == "kyverno-policies" ]]; then 
        package="kyvernopolicies"
    elif [[ ${CI_PROJECT_NAME} == "elasticsearch-kibana" ]]; then 
        package="logging"
    elif [[ ${CI_PROJECT_NAME} == "eck-operator" ]]; then 
        package="eckoperator"
    elif [[ ${CI_PROJECT_NAME} == "minio-operator" ]]; then 
        package="minioOperator"
    elif [[ ${CI_PROJECT_NAME} == "gitlab-runner" ]]; then 
        package="gitlabRunner"
    elif [[ ${CI_PROJECT_NAME} == "anchore-enterprise" ]]; then 
        package="anchore"
    elif [[ ${CI_PROJECT_NAME} == "mattermost-operator" ]]; then 
        package="mattermostoperator"
    else
        package="${CI_PROJECT_NAME}"
    fi 

    ## GitLab API endpoint used to interact with project-level resources
    GITLAB_PROJECTS_API_ENDPOINT="https://repo1.dso.mil/api/v4/projects"

    ## Data that will be used to create Big Bang MRs

    # The latest git tag for the Big Bang package repo
    LATEST_GIT_TAG=$(curl "${GITLAB_PROJECTS_API_ENDPOINT}/${CI_PROJECT_ID}/repository/tags" | jq '.[].name' | head -1 | sed 's/\"//g')

    # Get the URL of the latest CHANGELOG.md file
    CHANGELOG_URL=$(curl ${GITLAB_PROJECTS_API_ENDPOINT}/${CI_PROJECT_ID} | jq '.web_url' | sed 's/"//g')/-/blob/${LATEST_GIT_TAG}/CHANGELOG.md

    # Get the URL of the relevant package MR
    PACKAGE_MR_URL=$(curl -s "${GITLAB_PROJECTS_API_ENDPOINT}/${CI_PROJECT_ID}/merge_requests?state=merged" | jq '.[] | "\(.web_url) \(.merged_at)"' | sort -t ' ' -k2.1,2.4nr -k2.6,2.7nr -k2.9,2.10nr -k2.12,2.13nr -k2.15,2.16nr -k2.18,2.19nr -k2.21,2.23nr | head -1 | tr -d '"' |cut -d' ' -f1)
    
    # GitLab usernames of Big Bang codeowners that will be assigned as MR reviewers
    BB_MR_REVIEWER_NAMES=( "micah.nagel" "BrandenCobb" "ryan.j.garcia" )

    # Collect user IDs from /users API endpoint
    # Add "%2C" to the end of every user ID for URL encoding commas
    for reviewer in "${BB_MR_REVIEWER_NAMES[@]}"; do 
        BB_MR_REVIEWER_IDS+=$(curl "https://repo1.dso.mil/api/v4/users?username=${reviewer}" | jq '.[].id' | sed 's/$/%2C/')
    done 

    ## Pull down Big Bang repo, create a new branch, and configure git 
    BB_SOURCE_BRANCH=update-${CI_PROJECT_NAME}-tag-${LATEST_GIT_TAG}
    git clone "https://bb-ci:${BB_AUTO_MR_TOKEN}@repo1.dso.mil/platform-one/big-bang/bigbang.git" ${BB_REPO_DESTINATION}
    cd ${BB_REPO_DESTINATION}
    git checkout -b ${BB_SOURCE_BRANCH}
    git config user.email "mr.bot@automr.com"
    git config user.name "mr.bot"

    ## Bump git tag for updated package in Big Bang chart/values.yaml
    if [[ $(yq e '(.*.git | select(. != null) | (path | .[-2])' "${VALUES_FILE}") =~ "${package}" ]]; then
        # yq strips blank lines from YAML files
        yq e ".${package}.git.tag = \"${LATEST_GIT_TAG}\"" ${VALUES_FILE} > /tmp/updated-values.yaml
        yq e '.' ${VALUES_FILE} > /tmp/values-noblanks.yaml 

        # Adding blank lines back to values file before pushing changes
        diff --ignore-blank-lines /tmp/values-noblanks.yaml /tmp/updated-values.yaml > /tmp/patch.diff || true
        patch ${VALUES_FILE} /tmp/patch.diff || true 
        echo "Updated ${CI_PROJECT_NAME}'s git tag to: $(yq e ".${package}.git.tag" ${VALUES_FILE})"
    elif [[ $(yq e '(.addons.*.git | select(. != null) | (path | .[-2])' "${VALUES_FILE}") =~ "${package}" ]]; then
        # yq strips blank lines from YAML files
        yq e ".addons.${package}.git.tag = \"${LATEST_GIT_TAG}\"" ${VALUES_FILE} > /tmp/updated-values.yaml
        yq e '.' ${VALUES_FILE} > /tmp/values-noblanks.yaml  

        # Adding blank lines back to values file before pushing changes  
        diff --ignore-blank-lines /tmp/values-noblanks.yaml /tmp/updated-values.yaml > /tmp/patch.diff || true
        patch ${VALUES_FILE} /tmp/patch.diff || true 
        echo "Updated ${CI_PROJECT_NAME}'s git tag to: $(yq e ".addons.${package}.git.tag" ${VALUES_FILE})"
    fi 
    
    ## Push changes and create merge request
    git add ${VALUES_FILE}
    git commit -m "Updated ${CI_PROJECT_NAME} git tag"
    git push --set-upstream origin ${BB_SOURCE_BRANCH} \
      -o merge_request.create \
      -o merge_request.target=${BB_TARGET_BRANCH} \
      -o merge_request.title="Draft: Updated ${CI_PROJECT_NAME} git tag" \
      -o merge_request.label="status::review"	\
      -o merge_request.label=${package}

    ## Update merge request with reviewers and a description 

    # Get ID of the MR that was just created
    BB_MR_ID=$(curl "${GITLAB_PROJECTS_API_ENDPOINT}/${BB_PROJECT_ID}/merge_requests?source_branch=${BB_SOURCE_BRANCH}&state=opened" | jq '.[].iid' | head -1)
    
    # Get description of MR and save it to a JSON file
    JSON_DESCRIPTION_FILE="/tmp/description.json"
    curl "${GITLAB_PROJECTS_API_ENDPOINT}/${BB_PROJECT_ID}/merge_requests/${BB_MR_ID}" | jq '.description' > ${JSON_DESCRIPTION_FILE}
    
    # Edit the JSON file by adding curly brackets and "description" to make it a valid JSON request to the GitLab API
    sed -i 's|^|\{\"description\"\:|' ${JSON_DESCRIPTION_FILE}
    sed -i 's|$|\}|' ${JSON_DESCRIPTION_FILE}

    # Update description JSON file with package changes
    sed -i "s|(Describe Package changes here)|${CHANGELOG_URL}|g" ${JSON_DESCRIPTION_FILE}

    # Update description of MR with the package MR URL
    sed -i "s|(Link to Package MR here)|${PACKAGE_MR_URL}|g" ${JSON_DESCRIPTION_FILE}

    # Update description of MR with package changes from CHANGELOG.md and add reviewers
    curl --request PUT --header "Content-Type: application/json" --header "PRIVATE-TOKEN: ${BB_AUTO_MR_TOKEN}" --data "@${JSON_DESCRIPTION_FILE}" "${GITLAB_PROJECTS_API_ENDPOINT}/${BB_PROJECT_ID}/merge_requests/${BB_MR_ID}?reviewer_ids=${BB_MR_REVIEWER_IDS}"
    echo -e "\e[0Ksection_end:`date +%s`:create_bigbang_merge_request\r\e[0K"
}

#-----------------------------------------------------------------------------------------------------------------------
#
# Re-Usable Functions
#
#-----------------------------------------------------------------------------------------------------------------------
cluster_deprecation_check() {
   echo -e "\e[0Ksection_start:`date +%s`:kubent_check[collapsed=true]\r\e[0KIn Cluster Deprecation Check"
   kubent -e || export EXIT_CODE=$?
   if [ "$EXIT_CODE" == "200" ]; then 
     echo -e "\e[31mNOTICE: API deprecations or removals were found.\e[0m"
     exit 200
   fi
   echo -e "\e[0Ksection_end:`date +%s`:kubent_check\r\e[0K"
}

package_auth_setup() {
   mkdir -p /root/.docker
   jq -n '{"auths": {"registry.dso.mil": {"auth": $bb_registry_auth}, "registry1.dso.mil": {"auth": $registry1_auth}, "registry.il2.dso.mil": {"auth": $il2_registry_auth}, "docker.io": {"auth": $bb_docker_auth} } }' \
     --arg bb_registry_auth ${BB_REGISTRY_AUTH} \
     --arg registry1_auth ${REGISTRY1_AUTH} \
     --arg il2_registry_auth ${IL2_REGISTRY_AUTH} \
     --arg bb_docker_auth ${DOCKER_AUTH} > /root/.docker/config.json
}


#-----------------------------------------------------------------------------------------------------------------------
#
# Get kubernetes resources
#
#-----------------------------------------------------------------------------------------------------------------------
get_events() {
  echo -e "\e[0Ksection_start:`date +%s`:show_event_log[collapsed=true]\r\e[0K\e[33;1mCluster Event Log\e[37m"
  echo -e "\e[31mNOTICE: Cluster events can be found in artifact events.txt\e[0m"
  kubectl get events -A --sort-by=.metadata.creationTimestamp > events.txt
  echo -e "\e[0Ksection_end:`date +%s`:show_event_log\r\e[0K"
}

get_ns() {
  echo -e "\e[0Ksection_start:`date +%s`:namespaces[collapsed=true]\r\e[0K\e[33;1mNamespaces\e[37m"
  kubectl get namespace --show-labels
  echo -e "\e[0Ksection_end:`date +%s`:namespaces\r\e[0K"
}

get_all() {
  echo -e "\e[0Ksection_start:`date +%s`:all_resources[collapsed=true]\r\e[0K\e[33;1mAll Cluster Resources\e[37m"
  kubectl get all -A
  echo -e "\e[0Ksection_end:`date +%s`:all_resources\r\e[0K"
}

get_gitrepos() {
  echo -e "\e[0Ksection_start:`date +%s`:git_repos[collapsed=true]\r\e[0K\e[33;1mGitrepos\e[37m"
  kubectl get gitrepository -A || true
  echo -e "\e[0Ksection_end:`date +%s`:git_repos\r\e[0K"
}

get_hr() {
  echo -e "\e[0Ksection_start:`date +%s`:hr[collapsed=true]\r\e[0K\e[33;1mHelmreleases\e[37m"
  kubectl get helmrelease -A || true
  echo -e "\e[0Ksection_end:`date +%s`:hr\r\e[0K"
}

get_kustomize() {
  echo -e "\e[0Ksection_start:`date +%s`:kust[collapsed=true]\r\e[0K\e[33;1mKustomize\e[37m"
  kubectl get kustomizations -A || true
  echo -e "\e[0Ksection_end:`date +%s`:kust\r\e[0K"
}

get_gateways(){
  echo -e "\e[0Ksection_start:`date +%s`:gateways[collapsed=true]\r\e[0K\e[33;1mIstio Gateways\e[37m"
  kubectl get gateways -A || true
  echo -e "\e[0Ksection_end:`date +%s`:gateways\r\e[0K"
}

get_virtualservices(){
  echo -e "\e[0Ksection_start:`date +%s`:virtual_services[collapsed=true]\r\e[0K\e[33;1mVirtual Services\e[37m"
  kubectl get vs -A || true
  echo -e "\e[0Ksection_end:`date +%s`:virtual_services\r\e[0K"
}

get_hosts() {
  echo -e "\e[0Ksection_start:`date +%s`:hosts[collapsed=true]\r\e[0K\e[33;1mHosts File Contents\e[37m"
  cat /etc/hosts
  echo -e "\e[0Ksection_end:`date +%s`:hosts\r\e[0K"
}

get_opa_violations() {
  echo -e "\e[0Ksection_start:`date +%s`:opa_vio[collapsed=true]\r\e[0K\e[33;1mOPA Violations\e[37m"
  #kubectl get constraints -o json | jq '.items[] | { "Name" : .metadata.annotations."constraints.gatekeeper/name", "Kind" : .kind, "Description" : .metadata.annotations."constraints.gatekeeper/description", "Version" : .metadata.labels."app.kubernetes.io/version", "Parameters": .spec.parameters, "Source" : .metadata.annotations."constraints.gatekeeper/source", "Docs" : .metadata.annotations."constraints.gatekeeper/docs", "Related" : .metadata.annotations."constraints.gatekeeper/related", "TotalViolations" : .status.totalViolations, "Violations" : .status.violations } | with_entries( select( .value != null ) )' || true
  for i in $(kubectl get constraint | egrep -v 'NAME|^$' | awk '{print$1}'); do echo $i; kubectl get $i -o yaml | grep -B5 -i violation ; echo ;done || true
  echo -e "\e[0Ksection_end:`date +%s`:opa_vio\r\e[0K"
}

get_dns_config() {
   echo -e "\e[0Ksection_start:`date +%s`:dns[collapsed=true]\r\e[0K\e[33;1mDNS Config\e[37m"
   if kubectl get configmap -n kube-system coredns &>/dev/null; then
     kubectl get configmap -n kube-system coredns -o jsonpath='{.data.NodeHosts}'
   elif kubectl get configmap -n kube-system rke2-coredns-rke2-coredns &>/dev/null; then
     kubectl get configmap -n kube-system rke2-coredns-rke2-coredns -o jsonpath='{.data.Corefile}'
   fi
   echo -e "\e[0Ksection_end:`date +%s`:dns\r\e[0K"
}

get_log_dump(){
  echo -e "\e[0Ksection_start:`date +%s`:log_dump[collapsed=true]\r\e[0K\e[33;1mLog Dump\e[37m"
  echo -e "\e[31mNOTICE: Logs can be found in artifacts pod_logs/<namespace>/<pod_name>.txt\e[0m"
  mkdir -p pod_logs
  pods=$(kubectl get pods -A --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{"\n"}}{{end}}')
  echo "$pods" | while read -r line; do
      namespace=$(echo "$line" | awk '{print $1}')
      pod=$(echo "$line" | awk '{print $2}')
      mkdir -p "pod_logs/$namespace"
      kubectl -n "$namespace" logs --all-containers=true --prefix=true --previous=true --ignore-errors=true "$pod" > "pod_logs/$namespace/$pod.txt"
      kubectl -n "$namespace" logs --all-containers=true --prefix=true --ignore-errors=true "$pod" >> "pod_logs/$namespace/$pod.txt"
  done
  echo -e "\e[0Ksection_end:`date +%s`:log_dump\r\e[0K"
}  
      
describe_resources() {
  echo -e "\e[0Ksection_start:`date +%s`:describe_resources[collapsed=true]\r\e[0K\e[33;1mDescribe Cluster Resources\e[37m"
  echo -e "\e[31mNOTICE: Cluster resource describes can be found in artifacts kubectl_describes\e[0m"
  echo -e "Running 'kubectl describe' on all resources..."

  default_resources=$(kubectl get all -A --template '{{range .items}} {{.kind}}{{"\n"}}{{end}}' | uniq)
  custom_resources=$(kubectl get crds --template '{{range .items}} {{.status.acceptedNames.plural}} {{.spec.scope}}{{"\n"}}{{end}}')

  echo "$default_resources" | while read -r line; do
        default_resource=$(echo "$line" | awk '{print $1}')
        namespaces=$(kubectl get $default_resource -A --template '{{range .items}} {{.metadata.namespace}}{{"\n"}}{{end}}' | sort -u)
        for namespace in ${namespaces}; do
          mkdir -p "kubectl_describes/namespaces/$namespace"
          kubectl -n $namespace describe $default_resource 2>/dev/null | sed '/^$/d;/^Name:.*/i ---' > "kubectl_describes/namespaces/$namespace/"$default_resource"s.yaml"
        done 
  done

  echo "$custom_resources" | while read -r line; do
        crd=$(echo "$line" | awk '{print $1}')
        crd_scope=$(echo "$line" | awk '{print $2}')
        crd_namespaces=$(kubectl get $crd -A --template '{{range .items}}{{.metadata.namespace}}{{"\n"}}{{end}}' | sort -u)
        if [[ "$crd_scope" = "Cluster" ]]; then
             mkdir -p "kubectl_describes/cluster_resources"
             kubectl describe $crd 2>/dev/null | sed '/^$/d;/^Name:.*/i ---' > "kubectl_describes/cluster_resources/$crd.yaml"
        elif [[ "$crd_scope" = "Namespaced" ]]; then
             for namespace in ${crd_namespaces}; do
                mkdir -p "kubectl_describes/namespaces/$namespace"
                kubectl -n $namespace describe $crd 2>/dev/null | sed '/^$/d;/^Name:.*/i ---' > "kubectl_describes/namespaces/$namespace/$crd.yaml"
             done
        fi 
  done 

  find kubectl_describes/ -empty -delete

  echo -e "\e[0Ksection_end:`date +%s`:describe_resources\r\e[0K"
}

get_cluster_info_dump() {
  echo -e "\e[0Ksection_start:`date +%s`:cluster_info_dump[collapsed=true]\r\e[0K\e[33;1mCluster Info Dump\e[37m"
  echo -e "\e[31mNOTICE: cluster-info can be found in artifact cluster_info_dump.txt\e[0m"
  kubectl cluster-info dump > cluster_info_dump.txt
  echo -e "\e[0Ksection_end:`date +%s`:cluster_info_dump\r\e[0K"
}

get_debug() {
  if [[ $DEBUG_ENABLED == "true" || "$CI_MERGE_REQUEST_TITLE" == *"DEBUG"* ]]; then
    get_kustomize
    get_gateways
    get_virtualservices
    get_hosts
    get_dns_config
    get_log_dump
    get_cluster_info_dump
    describe_resources
    get_cpumem
  else
    echo "Debug not enabled, skipping"
  fi
}

bigbang_pipeline() {
  if [ $PIPELINE_TYPE == "BB" ]; then
    get_gitrepos
    get_hr
    get_opa_violations
  else
    echo "Pipeline type is not BB, skipping"
  fi
}

bigbang_package_images() {
   echo -e "\e[0Ksection_start:`date +%s`:Package-Image-List[collapsed=true]\r\e[0K\e[33;1mPackage-Image-List\e[37m"
   # Start output header
   echo "---" > ${PACKAGE_IMAGE_FILE}
   echo "package-image-list:" >> ${PACKAGE_IMAGE_FILE}

   # Generate a list of all images in all Big Bang Packages
   yq e '(.,.addons) | ... comments="" | .[] | (path | join(".")) ' "${VALUES_FILE}" | while IFS= read -r package; do
       gitrepo=$(yq e ".${package}.git.repo" "${VALUES_FILE}")
       version=$(yq e ".${package}.git.tag" "${VALUES_FILE}")
       #echo "Package: $package  Version: $version"
       # Since keys aren't always packages
       if [[ -z "$version" || "$version" == "null" ]]; then
           continue
       fi
       # Remove prefix
       gitrepo=${gitrepo#"https://repo1.dso.mil/"}
       # Remove suffix
       gitrepo=${gitrepo%".git"}
       # Replace `/` with `%2F`
       gitrepo=${gitrepo//\//%2F}
       # Curl gitlab API to get project ID
       projid=$(curl -s https://repo1.dso.mil/api/v4/projects/${gitrepo} | jq '.id')
       #echo "Project ID: $projid"
       # Curl gitlab API + S3 file to get images list
       packageinfo=$(curl -s https://repo1.dso.mil/api/v4/projects/${projid}/releases/${version})
       if [ -z "${packageinfo}" ] ; then
         echo "No package info found for ${package}" 1>&2
         echo "package info = $packageinfo" 1>&2
         continue
       fi
       repoimagelist=$(echo $packageinfo | jq -r '.assets.links[] | select(.name=="images.txt").url') && export EXIT_STATUS=$? || export EXIT_STATUS=$?
       if [ -z "${repoimagelist}" -o  ${EXIT_STATUS} -ne 0 ] ; then
         echo "No image list file found in the release for repo ${package}" 1>&2
         echo "Repo package info = $packageinfo" 1>&2
         continue
       fi
       images=$(curl -s ${repoimagelist})
       package=${package#"addons."}

       # Generate the output in JSON format
       header_done=0
       for image in $images
       do
         if [ -n "$(grep ${image} $IMAGE_LIST)" ]
         then
           if [ ${header_done} == 0 ] ; then
             echo "  ${package}: "
             echo "    version: \"${version}\""
             echo "    images:"
             header_done=1
           fi
           echo "      - \"${image}\""
         fi
       done
   done >> ${PACKAGE_IMAGE_FILE}

   cat ${PACKAGE_IMAGE_FILE}
   echo -e "\e[0Ksection_end:`date +%s`:Package-Image-List\r\e[0K"
}

get_cpumem(){
  echo -e "\e[0Ksection_start:`date +%s`:get_cpumem[collapsed=true]\r\e[0K\e[33;1mCPU and Memory usage\e[37m"
  echo -e "\e[31mNOTICE: Logs can be found in artifacts get_cpumem.txt\e[0m"
  kubectl top pods --all-namespaces --use-protocol-buffers | tee get_cpumem.txt
  echo -e "\e[0Ksection_end:`date +%s`:get_cpumem\r\e[0K"
}

renovate_download_external_deps() {
  curl -sO https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/raw/master/docs/README.md.gotmpl -o "${CI_PROJECT_DIR}"/scripts/README.md.gotmpl

  curl -sO https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/raw/master/docs/.helmdocsignore -o "${CI_PROJECT_DIR}"/scripts/.helmdocsignore

  mkdir -p "${CI_PROJECT_DIR}"/renovate
}
