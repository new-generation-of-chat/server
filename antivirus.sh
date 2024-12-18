#!/bin/bash

# Utility-Funktionen einbinden
SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR/crontab.sh"


# Installation von ClamAV
if ! command -v clamscan &> /dev/null; then
    echo "ClamAV wird installiert..."
    sudo apt update && sudo apt install clamav clamav-daemon -y
    sudo systemctl stop clamav-freshclam
    sudo freshclam
    sudo systemctl start clamav-freshclam
    sudo systemctl enable clamav-freshclam
    echo "ClamAV wurde erfolgreich installiert und aktualisiert."
fi

# Durchführung eines Antivirus-Scans mit ClamAV
echo "Durchführen eines vollständigen Antivirus-Scans mit ClamAV..."
sudo clamscan -r --bell -i /
# Crontab-Einträge hinzufügen
add_crontab "0 */4 * * * /usr/bin/freshclam" # ClamAV

# Installation von RKHunter (Rootkit Hunter)
if ! command -v rkhunter &> /dev/null; then
    echo "Rootkit Hunter (RKHunter) wird installiert..."
    sudo apt update && sudo apt install rkhunter -y
    sudo rkhunter --update
    sudo rkhunter --propupd
    echo "RKHunter wurde erfolgreich installiert und konfiguriert."
fi

# Durchführung eines Rootkit-Scans mit RKHunter
echo "Durchführen eines Rootkit-Scans mit RKHunter..."
sudo rkhunter --check --skip-keypress
add_crontab "0 3 * * * /usr/bin/rkhunter --check --sk" # RKHunter

# Installation von Lynis (Audit- und Sicherheitsprüfung)
if ! command -v lynis &> /dev/null; then
    echo "Lynis wird installiert..."
    sudo apt update && sudo apt install lynis -y
    echo "Lynis wurde erfolgreich installiert."
fi

# Durchführung eines Sicherheitsaudits mit Lynis
echo "Durchführen eines Sicherheitsaudits mit Lynis..."
sudo lynis audit system
add_crontab "0 1 * * * sudo lynis audit system" # Lynis Sicherheits-Audit

# Installation von Maldet
if ! command -v maldet &> /dev/null; then
    echo "Linux Malware Detect (Maldet) wird installiert..."
    cd /usr/src/
    sudo wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
    sudo tar -xzf maldetect-current.tar.gz
    cd maldetect-*
    sudo ./install.sh
    cd ..
    sudo rm -rf maldetect-*
    echo "Maldet wurde erfolgreich installiert."
fi

# Durchführung eines Malware-Scans mit Maldet
echo "Durchführen eines Malware-Scans mit Maldet..."
sudo maldet -a /
add_crontab "0 2 * * * sudo maldet -a /" # Maldet Malware-Scan
