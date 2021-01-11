#!/usr/bin/env bash

# exit on error
set -e

echo "Checking "

hosts=`kubectl get vs -A -o jsonpath="{ .items[*].spec.hosts[*] }"`
for host in $hosts; do
    curl -svv https://$host/ > /dev/null
done