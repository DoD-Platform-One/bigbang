#!/bin/bash

set -e

hosts=`kubectl get vs -A -o jsonpath="{ .items[*].spec.hosts[*] }"`

for host in $hosts; do
    curl -vI https://$host
done