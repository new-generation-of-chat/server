#!/bin/bash

# Fail2Ban installieren, falls nicht vorhanden
if ! command -v fail2ban-server &> /dev/null; then
    echo "Fail2Ban wird installiert..."
    sudo apt update && sudo apt install fail2ban -y
fi

# CSF installieren, falls nicht vorhanden
if ! command -v csf &> /dev/null; then
    echo "CSF (ConfigServer Security & Firewall) wird installiert..."
    sudo apt update && sudo apt install libwww-perl -y
    cd /usr/src/
    sudo wget https://download.configserver.com/csf.tgz
    sudo tar -xzf csf.tgz
    cd csf
    sudo sh install.sh
    cd ..
    sudo rm -rf csf csf.tgz
    echo "CSF wurde installiert."
fi

# UFW installieren, falls nicht vorhanden
if ! command -v ufw &> /dev/null; then
    echo "UFW wird installiert..."
    sudo apt update && sudo apt install ufw -y
fi
# UFW konfigurieren
echo "Konfigurieren der Firewall (UFW)..."

# Standardregeln festlegen
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Erforderliche Ports freigeben
echo "Freigeben von HTTP (Port 80) und HTTPS (Port 443)..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

echo "Freigeben von SSH (Port 22)..."
sudo ufw allow 22/tcp

# Benutzerdefinierte Ports hinzufügen (bei Bedarf)
while true; do
    read -p "Möchten Sie zusätzliche Ports freigeben? (y/n): " ADD_PORTS
    if [ "$ADD_PORTS" == "y" ]; then
        read -p "Geben Sie den Port (z. B. 8080/tcp) ein: " CUSTOM_PORT
        sudo ufw allow "$CUSTOM_PORT"
        echo "Port $CUSTOM_PORT wurde freigegeben."
    elif [ "$ADD_PORTS" == "n" ]; then
        break
    else
        echo "Ungültige Eingabe. Bitte 'y' oder 'n' eingeben."
    fi
done

# Firewall aktivieren
echo "Aktivieren der Firewall..."
sudo ufw enable

# UFW-Status anzeigen
echo "Firewall-Status (UFW):"
sudo ufw status verbose

# Fail2Ban konfigurieren
echo "Konfigurieren von Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo "Fail2Ban-Status:"
sudo fail2ban-client status

# CSF-Status anzeigen
echo "CSF-Status:"
sudo csf -e
sudo csf -l
