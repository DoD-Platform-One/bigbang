#!/bin/bash
set -e

## Adds all the vs hostnames and LB IP to /etc/hosts
## Get the LB Hostname
INGRESS_LB_Hostname=$(kubectl get svc -n istio-system public-ingressgateway -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
## Get IP address from Hostname
INGRESS_LB_IP=$(dig $INGRESS_LB_Hostname +search +short | head -1)

## Get a list of all the vs in cluster
VIRTUAL_SERVICES=$(kubectl get vs -A -o jsonpath={..spec.hosts[0]})

## For each vs put it in /etc/hosts
for vs in $VIRTUAL_SERVICES;
do echo "$INGRESS_LB_IP $vs" >> /etc/hosts
done

##Cat out the file to see what we've done
cat /etc/hosts
