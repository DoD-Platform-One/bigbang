#!/bin/sh

PUBLICINTERFACE=$( route | grep '^default' | grep -o '[^ ]*$' )
iptables -I DOCKER-USER -i ${PUBLICINTERFACE} -j DROP
iptables -I DOCKER-USER -d 10.42.0.0/16 -j RETURN
iptables -I DOCKER-USER -d 10.43.0.0/16 -j RETURN
iptables -A DOCKER-USER -j RETURN