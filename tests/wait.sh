#!/bin/bash
wait_project() {
   # interval and timeout are in seconds
   interval=5
   timeout=600
   #
   resourcename=mattermost
   counter=0
   # need to remove the default "set -e" to allow commands to return nonzero exit codes without the script failing
   set +e
   while true; do
      if kubectl get $resourcename --namespace=$resourcename -o jsonpath='{.items[0].status.state}' | \
         grep "^stable" 1>/dev/null
      then
         echo "$resourcename custom resource creation finished"
         break
      fi
      sleep $interval
      let counter++
      if [[ $(($counter * $interval)) -ge $timeout ]]; then
         echo "$resourcename timeout waiting $timeout seconds for resource creation, running describe..." 1>&2
         kubectl describe $resourcename --namespace=$resourcename 1>&2
         exit 1
      fi
   done
   set -e
}
