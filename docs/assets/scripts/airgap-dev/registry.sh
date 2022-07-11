#!/usr/bin/env bash
set -e
trap 'echo exit at ${0}:${LINENO}, command was: ${BASH_COMMAND} 1>&2' ERR

# Installs/Configures:
#  - Docker Registy Container with self-signed cert
#
# Tested on Ubuntu 14.04.1

# Must be executed with elevated privilages
if [ "$(id -u)" != "0" ]; then
  printf "This script must be ran as root or sudo!\n"
  exit 1
fi

# prompt helper function
function prompt () {
  if [ -z ${!1} ]; then
    local response=""
    while [[ ${response} = "" ]]; do
      read -p "$2: " response
    done
    eval $1=${response}
  fi
}

# collect required information
# - C   Country
# - ST  State
# - L    Location
# - O    Organization
# - OU   Organizational Unit
# - CN   Common Name
echo -e "\nRequired information:"
prompt BITS "Enter bit size for certs (Ex. 4096)"
prompt DAYS "Enter number of days to sign the certs with (Ex. 3650)"
prompt COUNTRY "Enter the 'Country' for the cert (Ex. US)"
prompt STATE "Enter the 'State' for the cert (Ex. CO)"
prompt LOCATION "Enter the 'Location' for the cert (Ex. ColoradoSprings)"
prompt ORGANIZATION "Enter the 'Organization' for the cert (Ex. PlatformOne)"
prompt OUNIT "Enter the 'Organizational Unit' for the cert (Ex. Bigbang)"
prompt COMMON  "Enter the 'Common Name' for the cert (Must be a FQDN (at least one period character) E.g. host.k3d.internal"
prompt ALTNAMES  "Enter the 'Subject Alternative Names' for the cert E.g. DNS:host.k3d.internal,IP:PRIVATEIP)"

# ... Certs ...
# ~~~~~~~~~~~~~

# ... prep certs ...

echo -e "\nGenerating certs ..."
mkdir -p certs
cd certs
# Generate a root key
openssl genrsa -out rootCA.key ${BITS}

# Generate a root certificate
openssl req -x509 -new -nodes -key rootCA.key -days ${DAYS}\
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORGANIZATION}/CN=${COMMON}" \
    -out rootCA.crt

# Generate key for host
openssl genrsa -out ${COMMON}.key ${BITS}

# Generate CSR
openssl req -new -key ${COMMON}.key \
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORGANIZATION}/CN=${COMMON}" \
    -out ${COMMON}.csr

# Sign certificate request
echo subjectAltName = DNS:${COMMON},${ALTNAMES} > extfile.cnf
openssl x509 -req -in ${COMMON}.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -days ${DAYS} \
-out ${COMMON}.crt -extfile extfile.cnf


openssl rsa -in ${COMMON}.key -text > ${COMMON}.private.pem
openssl x509 -inform PEM -in ${COMMON}.crt > ${COMMON}.public.pem

mkdir -p /certs/${COMMON}
cp rootCA.crt /certs/${COMMON}/ca.crt


# ... launch registry ...
# ~~~~~~~~~~~~~~~~~~~~~~~

echo -e "\nLaunching our private registry ..."
cd ..
docker run -d -p 5443:5000 --restart=always --name bigbang_registry \
    -v `pwd`/certs:/certs \
    -v `pwd`/var/lib/registry:/var/lib/registry \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/${COMMON}.crt \
    -e REGISTRY_HTTP_TLS_KEY=/certs/${COMMON}.key \
    registry:2


# Instructions
echo -e "\nInstallation finished ...

Notes
=====

To see images in the registry;

=========================
For example, 
  curl https://host.k3d.internal:5443/v2/_catalog -k
=========================

"