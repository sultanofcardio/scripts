#!/usr/bin/env bash

set -e

mkdir -p /var/www/html/scripts

cp -r bash /var/www/html/scripts

## Nginx and certbot configuration

echo "-------------------------------------------------------------------------"
echo "Setting up nginx and certbot"
echo "-------------------------------------------------------------------------"

./deploy/certify.sh

echo "-------------------------------------------------------------------------"
echo "Deployment complete"
echo "-------------------------------------------------------------------------"
