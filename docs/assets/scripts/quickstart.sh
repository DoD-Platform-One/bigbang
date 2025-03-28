#!/bin/bash

REGISTRY1_ENDPOINT=registry1.dso.mil
BIG_BANG_REPO=""
REGISTRY1_USERNAME="${REGISTRY1_USERNAME:-}"
REGISTRY1_TOKEN="${REGISTRY1_TOKEN:-}"
GITLAB_USERNAME=""
REPO1_LOCATION="${REPO1_LOCATION:-}"
KUBECONFIG="${KUBECONFIG:-}"
BB_K3D_PUBLICIP=""
BB_K3D_PRIVATEIP=""

# Configuration variables sourced from the command line
declare -g arg_host
declare -g arg_privateip
declare -g arg_username
declare -g arg_keyfile
declare -g arg_version
declare -g arg_pipeline_templates_version=master
declare -g arg_repolocation="${REPO1_LOCATION:-}"
declare -g arg_registry1_username="${REGISTRY1_USERNAME:-}"
declare -g arg_registry1_token="${REGISTRY1_TOKEN:-}"
declare -g arg_cloud_provider=aws
declare -g arg_metallb=false
declare -g arg_provision=false
declare -g arg_deploy=false
declare -g arg_wait=false
declare -g arg_destroy=false
declare -g arg_recreate_k3d=false
declare -g arg_recreate_cloud=false
declare -a arg_argv

function checkout_bigbang_repo {
    if [[ ! -d ${BIG_BANG_REPO} ]]; then
        mkdir -p ${BIG_BANG_REPO}
        git clone https://repo1.dso.mil/big-bang/bigbang.git ${BIG_BANG_REPO}
        cd ${BIG_BANG_REPO}
    else
        cd ${BIG_BANG_REPO}
    fi
    git fetch -a
    if [[ "${arg_version}" == "latest" ]]; then
        arg_version=$(git tag | sort -V | grep -v -- '-rc.' | tail -n 1)
    fi
    git checkout ${arg_version}
}

function checkout_pipeline_templates {
    PIPELINE_REPO_LOCATION=${REPO1_LOCATION}/big-bang/pipeline-templates/pipeline-templates
    if [[ ! -d ${PIPELINE_REPO_LOCATION} ]]; then
        mkdir -p ${PIPELINE_REPO_LOCATION}
        git clone https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates.git ${PIPELINE_REPO_LOCATION}
        cd ${PIPELINE_REPO_LOCATION}
    else
        cd ${PIPELINE_REPO_LOCATION}
        git reset --hard
        git clean -df
    fi
    git fetch -a
    git checkout ${arg_pipeline_templates_version}
}

function build_k3d_arguments {
    if [[ "${arg_privateip}" != "" ]]; then
        args="${args} -P ${arg_privateip}"
    fi
    if [[ "${arg_host}" != "" ]]; then
        args="${args} -H ${arg_host}"
    fi
    if [[ "${arg_username}" != "" ]]; then
        args="${args} -U ${arg_username}"
    fi
    if [[ "${arg_keyfile}" != "" ]]; then
        args="${args} -k ${arg_keyfile}"
    fi
    if [[ "${arg_metallb}" == "true" ]]; then
        args="${args} -m"
    fi
    if [[ "${arg_cloud_provider}" != "" ]]; then
        args="${args} -c ${arg_cloud_provider}"
    fi
    if [[ "${arg_recreate_k3d}" == "true" ]]; then
        args="${args} -K"
    fi
    if [[ "${arg_recreate_cloud}" == "true" ]]; then
        args="${args} -R"
    fi
    echo "${args}"   
}

function destroy_k3d_cluster {
    ${BIG_BANG_REPO}/docs/assets/scripts/developer/k3d-dev.sh \
        -t quickstart \
        $(build_k3d_arguments) \
        -d
}

function build_k3d_cluster {
    ${BIG_BANG_REPO}/docs/assets/scripts/developer/k3d-dev.sh \
        -t quickstart \
        -T \
        -q \
        $(build_k3d_arguments) \
        $@
}

function deploy_flux {
    KUBECONFIG=${KUBECONFIG} ${REPO1_LOCATION}/big-bang/bigbang/scripts/install_flux.sh \
        -u ${REGISTRY1_USERNAME} \
        -p ${REGISTRY1_TOKEN} \
        -w 900
}

function deploy_bigbang {
    cd ${BIG_BANG_REPO} &&
        helm upgrade -i bigbang \
            ${BIG_BANG_REPO}/chart \
            -n bigbang \
            --create-namespace \
            --set registryCredentials.username=${REGISTRY1_USERNAME} \
            --set registryCredentials.password=${REGISTRY1_TOKEN} \
            $@ \
            -f ${BIG_BANG_REPO}/chart/ingress-certs.yaml \
            -f ${BIG_BANG_REPO}/docs/assets/configs/example/dev-sso-values.yaml \
            -f ${BIG_BANG_REPO}/docs/assets/configs/example/policy-overrides-k3d.yaml
}

function check_for_tools {
    missing=0
    for tool in jq yq kubectl helm git sed awk; do
        if [[ ! -x $(which ${tool} 2>/dev/null) ]]; then
            missing=1
            echo "Required tool ${tool} missing, please fix and run again" >&2
        fi
    done
    if [[ $missing -gt 0 ]]; then
        exit 1
    fi
}

function usage {
    cat <<EOF
quickstart.sh (C) 2025 : PlatformOne Big Bang team

PlatformOne Big Bang quickstart : Quickly deploy a development bigbang cluster on a VM

Optional Arguments:
    -H,--host v : String. IP or Hostname of the VM to operate on 
    -P,--privateip v : String. If your VM has a separate private IP in addition to the public host, provide it here 
    -U,--username v : String. Username to use when SSHing into the target VM 
    -K,--keyfile v : String. SSH Key file to use when SSHing into the target VM 
    -V,--version v : String. Big Bang version to deploy (Default "latest")
    -v,--pipeline-templates-version v : String. Version of the bigbang pipeline-templates to use (Default "master")
    -R,--repolocation v : String. Location on your host filesystem where bigbang should be checked out (Default "${arg_repolocation}")
    -u,--registry1-username v : String. Username for your account on registry1.dso.mil (Default "${arg_registry1_username}")
    -c,--cloud-provider v : String. If using cloud provisioning, which cloud provider should be used (Default "aws")
    -t,--registry1-token v : String. Access token for your account on registry1.dso.mil (Default "${arg_registry1_token}")
    -m,--metallb : Boolean. Deploy a MetalLB on k3d 
    -p,--provision : Boolean. Provision the k3d cluster (implied) 
    -d,--deploy : Boolean. Deploy bigbang (implied) 
    -w,--wait : Boolean. Wait for bigbang (implied by --deploy) 
    -D,--destroy : Boolean. Destroy any previously created quickstart instance(s) created by this tool. (Disables -p, -d, -w)
    -k,--recreate-k3d : Boolean. Recreate the K3D cluster on the instance from scratch. (implies -p)
    -C,--recreate-cloud : Boolean. When provisioning with a cloud provider, destroy and rebuild the instance. (implies -p)

EOF
}

function parse_arguments {
    while [ -n "$1" ]; do # while loop starts

        case "$1" in
        "-h") ;&
        "--help")
            usage
            exit 1
            ;;
        "-k") ;&
        "--recreate-k3d")
            arg_recreate_k3d=true
            arg_provision=true
            ;;
        "-C") ;&
        "--recreate-cloud")
            arg_recreate_cloud=true
            arg_provision=true
            ;;
        "-H") ;&
        "--host")
            shift
            arg_host=$1
            ;;
        "-P") ;&
        "--privateip")
            shift
            arg_privateip=$1
            ;;
        "-U") ;&
        "--username")
            shift
            arg_username=$1
            ;;
        "-V") ;&
        "--version")
            shift
            arg_version=$1
            ;;
        "-v") ;&
        "--pipeline-templates-version")
            shift
            arg_pipeline_templates_version=$1
            ;;
        "-R") ;&
        "--repolocation")
            shift
            arg_repolocation=$1
            ;;
        "-u") ;&
        "--registry1-username")
            shift
            arg_registry1_username=$1
            ;;
        "-t") ;&
        "--registry1-token")
            shift
            arg_registry1_token=$1
            ;;
        "-c") ;&
        "--cloud-provider")
            shift
            arg_cloud_provider=$1
            ;;
        "-K") ;&
        "--keyfile")
            shift
            arg_keyfile=${1}
            ;;
        "-m") ;&
        "--metallb")
            arg_metallb=true
            ;;
        "-p") ;&
        "--provision")
            arg_provision=true
            ;;
        "-d") ;&
        "--deploy")
            arg_deploy=true
            ;;
        "-w") ;&
        "--wait")
            arg_wait=true
            ;;
        "-D") ;&
        "--destroy")
            arg_destroy=true
            ;;
        "--")
            shift
            arg_argv=("${@}")
            return
            ;;
        *) 
            echo "Option $1 not recognized" 
            exit 1
            ;;

        esac
        shift
    done
}

function main {
    set -e
    parse_arguments $@

    if [[ ! -z "${arg_keyfile}" ]] && [[ ! -e ${arg_keyfile} ]] ; then
        echo "SSH key file ${arg_keyfile} does not exist" >&2
        exit 1
    fi

    actions="provision deploy wait"
    user_actions=""
    if [[ "${arg_provision}" == "true" ]]; then
        user_actions="provision"
    fi

    if [[ "${arg_deploy}" == "true" ]]; then
        user_actions="${user_actions} deploy"
        # --deploy implies --wait
        arg_wait="true"
    fi

    if [[ "${arg_wait}" == "true" ]]; then
        user_actions="${user_actions} wait"
    fi

    if [[ "${arg_destroy}" == "true" ]]; then
        user_actions="destroy"
    fi

    if [[ "$user_actions" != "" ]]; then
        actions="$user_actions"
    fi

    export REPO1_LOCATION=${arg_repolocation}
    export BIG_BANG_REPO=${REPO1_LOCATION}/big-bang/bigbang
    export REGISTRY1_TOKEN=${arg_registry1_token}
    export REGISTRY1_USERNAME=${arg_registry1_username}

    checkout_bigbang_repo
    checkout_pipeline_templates

    if [[ "${actions}" =~ "destroy" ]]; then
        destroy_k3d_cluster
        return
    elif [[ "${actions}" =~ "provision" ]]; then
        build_k3d_cluster
    fi

    if [[ "${arg_host}" != "" ]]; then
        export KUBECONFIG=~/.kube/${arg_host}-dev-quickstart-config
    else
        AWSUSERNAME=$(aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/')
        export KUBECONFIG=~/.kube/${AWSUSERNAME}-dev-quickstart-config
        instanceid=$(aws ec2 describe-instances \
            --output text \
            --query "Reservations[].Instances[].InstanceId" \
            --filters "Name=tag:Name,Values=${AWSUSERNAME}-dev" "Name=tag:Project,Values=quickstart" "Name=instance-state-name,Values=running")
        arg_host=$(aws ec2 describe-instances --output text --no-cli-pager --instance-id ${instanceid} --query "Reservations[].Instances[].PublicIpAddress")
        arg_privateip=$(aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${instanceid} | jq -r '.Reservations[0].Instances[0].PrivateIpAddress')
        arg_keyfile="~/.ssh/${AWSUSERNAME}-dev-quickstart.pem"
        arg_username="ubuntu"
    fi

    if [[ "${actions}" =~ "deploy" ]]; then
        deploy_flux

        deploy_bigbang ${arg_argv}
    fi

    if [[ "${actions}" =~ "wait" ]]; then
        export PIPELINE_REPO_DESTINATION=${REPO1_LOCATION}/big-bang/pipeline-templates/pipeline-templates
        export CI_VALUES_FILE=${BIG_BANG_REPO}/chart/values.yaml
        export VALUES_FILE=${BIG_BANG_REPO}/chart/values.yaml
        ${REPO1_LOCATION}/big-bang/pipeline-templates/pipeline-templates/scripts/deploy/03_wait_for_helmreleases.sh
    fi

    services=$(kubectl get virtualservices -A -o json 2>/dev/null | jq -r .items[].spec.hosts[0] | tr "\n" "\t")
    echo "=================================================================================="
    echo "                          INSTALLATION   COMPLETE"
    echo ""
    build_k3d_cluster --print-instructions
    echo
    echo "=================================================================================="
    set +e
}

check_for_tools

main $@
