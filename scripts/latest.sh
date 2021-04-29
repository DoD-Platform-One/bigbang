#!/bin/bash

# This script looks at all the deployed images from iron bank and identifies if the 
# currently deployed version is the latest in IronBank.  Could be used as part of CI
# or as general awareness for development

# Needs crane( https://github.com/google/go-containerregistry/tree/main/cmd/crane )
# to be configured before hand via

# crane auth login -p ${REGISTRY1_CREDENTIALS} -u ${REGISTRY1_USER} registry1.dso.mil

images=`kubectl get pods -A -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c | grep "registry1" | awk '{ print $2 }'`


for i in $images
do
    image=`echo "$i" | awk '{split($0,a,":"); print a[1] }'`
    tag=`echo "$i" | awk '{split($0,a,":"); print a[2] }'`

    upstream_tag=`crane ls $image | grep -v "latest" | sort -r | head -n1`
    
    if [[ "$tag" != "$upstream_tag" ]]
    then
        echo "Update for $image:  $tag ---->  $upstream_tag"
    fi
done