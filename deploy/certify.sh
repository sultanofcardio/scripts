#!/usr/bin/env bash

set -e

HOST_NAME="scripts.sultanofcardio.com"
NGINX_FILE_NAME="${HOST_NAME//\./_}"
SSL_CONFIG_FILE_NAME="ssl-$NGINX_FILE_NAME.conf"

sudo apt update

# Nginx setup
echo "-------------------------------------------------------------------------"
echo "Setting up nginx"
echo "-------------------------------------------------------------------------"
wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
sudo sh -c "echo 'deb http://nginx.org/packages/mainline/ubuntu/ '$(lsb_release -cs)' nginx' > /etc/apt/sources.list.d/nginx.list"
sudo apt update
sudo apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y install nginx=1.19.0-1~xenial

echo "-------------------------------------------------------------------------"
echo "Configuring nginx for certbot"
echo "-------------------------------------------------------------------------"

sudo cat <<EOF >/etc/nginx/sites-available/${NGINX_FILE_NAME}.nginx
server {
    listen 80;
    listen [::]:80;
    client_max_body_size 20M;
    server_name ${HOST_NAME};

    root /var/www/html/scripts;

    location ~ /.well-known {
            allow all;
    }

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        try_files \$uri \$uri/ =404;
    }
}
EOF

if [[ -f /etc/nginx/sites-enabled/default ]]; then
  sudo rm /etc/nginx/sites-enabled/default
fi
if [[ -f /etc/nginx/sites-available/default ]]; then
  sudo mv /etc/nginx/sites-available/default /etc/nginx/default.old
fi

if [[ ! -f /etc/nginx/sites-enabled/${NGINX_FILE_NAME}.nginx ]]; then
  sudo ln -s /etc/nginx/sites-available/${NGINX_FILE_NAME}.nginx /etc/nginx/sites-enabled/${NGINX_FILE_NAME}.nginx
fi
sudo systemctl restart nginx
echo "" | sudo tee -a /var/www/html/index.html

# Configure firewall
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'

# SSL cert
echo "-------------------------------------------------------------------------"
echo "Setting up certbot"
echo "-------------------------------------------------------------------------"
## Install certbot if it doesn't already exist
if ! [ -x "$(command -v certbot)" ]; then
  sudo apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y install certbot
fi
sudo apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y install python-certbot-nginx
echo "-------------------------------------------------------------------------"
echo "Certifying ${HOST_NAME}"
echo "-------------------------------------------------------------------------"

sudo certbot --agree-tos --email "${CERTBOT_ADMIN_EMAIL}" certonly --non-interactive --webroot --webroot-path=/var/www/html/scripts -d "${HOST_NAME}"

# Nginx setup
echo "-------------------------------------------------------------------------"
echo "Reconfiguring nginx for SSL"
echo "-------------------------------------------------------------------------"
echo "ssl_certificate /etc/letsencrypt/live/${HOST_NAME}/fullchain.pem;" | sudo tee "/etc/nginx/snippets/${SSL_CONFIG_FILE_NAME}"
echo "ssl_certificate_key /etc/letsencrypt/live/${HOST_NAME}/privkey.pem;" | sudo tee -a "/etc/nginx/snippets/${SSL_CONFIG_FILE_NAME}"

sudo cat <<EOF >/etc/nginx/snippets/ssl-params.conf
# from https://cipherli.st/
# and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html

ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-256-GCM-SHA384:TLS-AES-128-GCM-SHA256";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
# disable HSTS header for now
#add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;

ssl_dhparam /etc/ssl/certs/dhparam.pem;
EOF

sudo cat <<EOF >/etc/nginx/sites-available/${NGINX_FILE_NAME}.nginx

server {
    listen 80;
    listen [::]:80;
    client_max_body_size 20M;
    server_name ${HOST_NAME};
    return 301 https://\$server_name\$request_uri;
}

server {
     listen 443 ssl http2;
     listen [::]:443 ssl http2;
     client_max_body_size 20M;
     include snippets/${SSL_CONFIG_FILE_NAME};
     include snippets/ssl-params.conf;
     server_name ${HOST_NAME};

     root /var/www/html/scripts;

     location / {
        try_files \$uri \$uri/ =404;

        types {
           text/plain sh;
        }
     }

     location ~ /.well-known {
        allow all;
     }
}
EOF

if [[ ! -f /etc/ssl/certs/dhparam.pem ]]; then
  sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
fi

sudo systemctl restart nginx
