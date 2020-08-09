#!/usr/bin/env bash

url="${1}"

function usage() {
  echo "Usage: ${0} <server>[:port] [PEM|DER]"
  echo ""
  echo "server - IP address or host name of the target server"
  echo "port - The HTTPS port to use. Default is 443"
  echo "PEM|DER - The output file format. Defaults to X.509 PEM"
  exit 1
}

if [[ -z "${url}" ]]; then
  usage
fi

if [[ ! "$url" == *:* ]]; then
  url="${url}:443"
fi

format="${2}"

if [[ -z "${format}" ]]; then
  format="PEM"
fi

if ! [[ "${format}" =~ ^PEM|pem|DER|der$ ]]; then
  echo "Invalid format ${format}"
  usage
fi

echo "Downloading certs for ${url}"

openssl s_client -showcerts -verify 5 -connect "${url}" < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".crt"; print >out}'
for cert in *.crt; do
  newname=$(openssl x509 -noout -subject -in "${cert}" | sed -n 's/^.*CN=\(.*\)$/\1/; s/[ ,.*]/_/g; s/__/_/g; s/^_//g;p')
  mv "${cert}" "${newname}.pem"
  if [ "${format}" == "DER" ]; then
    openssl x509 -outform der -in "${newname}.pem" -out "${newname}.der"
    rm "${newname}.pem"
  fi
done
