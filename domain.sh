
#!/bin/bash

# Funktion zur Überprüfung der Domain
is_valid_domain() {
    if [[ "$1" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Abfrage der Domain mit Validierung
for i in 1 2; do
    echo "Bitte geben Sie den Domain-Namen ein (z.B. meinehomepage.com):"
    read DOMAIN

    if is_valid_domain "$DOMAIN"; then
        echo "Verwendete Domain: $DOMAIN"
        break
    else
        echo "Ungültige Domain. Bitte versuchen Sie es erneut."
        if [ $i -eq 2 ]; then
            echo "Fehler: Domain wurde zweimal ungültig eingegeben. Das Skript wird beendet."
            exit 1
        fi
    fi
done

# Extrahiere den Domainnamen ohne TLD
DOMAIN_NAME=$(echo "$DOMAIN" | cut -d'.' -f1)

# Ordner für die Domain erstellen
if [ ! -d "/var/www/$DOMAIN_NAME" ]; then
    mkdir -p /var/www/$DOMAIN_NAME
fi
sudo chown -R ftpuser:www-data /var/www/$DOMAIN_NAME
sudo chmod -R 755 /var/www/$DOMAIN_NAME

# NGINX-Konfiguration für die eingegebene Domain
sudo tee /etc/nginx/sites-available/$DOMAIN_NAME <<EOF
# HTTP-Weiterleitung von www.$DOMAIN und $DOMAIN auf HTTPS
server {
    if (\$host ~* ^(www\.)?$DOMAIN\$) {
        return 301 https://$DOMAIN\$request_uri;
    }

    listen 80;
    server_name www.$DOMAIN $DOMAIN;
    return 301 https://$DOMAIN\$request_uri;
}

# HTTPS-Weiterleitung von www.$DOMAIN auf $DOMAIN
server {
    listen 443 ssl;
    server_name www.$DOMAIN;
    return 301 https://$DOMAIN\$request_uri;
}

# Hauptkonfiguration für $DOMAIN
server {

    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header Content-Security-Policy "default-src * data: 'unsafe-inline' 'unsafe-eval'; frame-src 'self';" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Set-Cookie "letsencrypt=true; Path=/; Secure; HttpOnly; SameSite=Strict";

    root /var/www/$DOMAIN_NAME;
    index index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Site aktivieren und NGINX neu laden
sudo ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Let's Encrypt-Zertifikat mit Certbot abrufen
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN

# Utility-Funktionen einbinden
SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR/crontab.sh"

add_crontab "0 0 * * * certbot renew --quiet" # Certbot automatische Zertifikatserneuerung
