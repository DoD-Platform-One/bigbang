#!/bin/bash


for hr in `kubectl get hr --no-headers -n bigbang | awk '{ print $1 }'`
do
    flux reconcile hr -n bigbang --with-source $hr
done
