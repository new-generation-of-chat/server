
#!/bin/bash

# System aktualisieren
echo "### Schritt 1: System wird aktualisiert ###"
sudo apt update && sudo apt upgrade -y

# Installation der benötigten Pakete
echo "### Schritt 2: Installation der benötigten Pakete ###"
sudo apt install nginx php-fpm php-mysqli php-curl php-xml php-mbstring php-intl certbot python3-certbot-nginx proftpd-basic phpmyadmin mariadb-server -y

# NGINX starten und aktivieren
echo "### Schritt 3: NGINX wird gestartet und aktiviert ###"
sudo systemctl start nginx
sudo systemctl enable nginx

# PHP-FPM starten und aktivieren
echo "### Schritt 4: PHP-FPM wird gestartet und aktiviert ###"
sudo systemctl start php8.2-fpm
sudo systemctl enable php8.2-fpm

# MariaDB installieren und sichern
echo "### Schritt 5: MariaDB wird gestartet und konfiguriert ###"
sudo systemctl start mariadb
sudo systemctl enable mariadb

# MySQL-Root-Passwort aus phpMyAdmin-Konfiguration verwenden oder generieren
echo "### Schritt 6: MySQL wird gesichert ###"
MYSQL_ROOT_PASSWORD=$(sudo debconf-show phpmyadmin | grep 'phpmyadmin/reconfigure' -A1 | grep 'Value:' | awk '{print $2}')
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
    echo "Generiertes MySQL-Root-Passwort: $MYSQL_ROOT_PASSWORD"
fi

# Automatisierte MySQL-Sicherung durchführen
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';" # Anonyme Benutzer entfernen
sudo mysql -e "DROP DATABASE IF EXISTS test;" # Testdatenbank entfernen
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
sudo mysql -e "FLUSH PRIVILEGES;" # Änderungen übernehmen


