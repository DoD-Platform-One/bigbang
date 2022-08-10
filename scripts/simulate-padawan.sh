#!/usr/bin/env bash

# REQUIREMENT: docker login registry.il2.dso.mil
# REQUIREMENT: site dir exists

docker run -it --rm \
    --name=simulate-padawan \
    -p 9999:8080 \
    -v "$(pwd)"/site:/var/www/sites/bb-docs \
    -v "$(pwd)"/custom-csp.conf:/etc/nginx/conf.d/site-config/custom-csp.conf \
    registry.il2.dso.mil/platform-one/products/bullhorn/padawan/padawan-umbrella:1.0.2
