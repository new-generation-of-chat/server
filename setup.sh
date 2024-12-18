
#!/bin/bash

# Logging aktivieren
LOGFILE="/var/log/setup_panel.log"
exec > >(tee -a "$LOGFILE") 2>&1

SCRIPT_DIR="./setup_scripts"
ZIP_FILE="setup_scripts.zip"
ZIP_URL="https://raw.githubusercontent.com/new-generation-of-chat/server/main/$ZIP_FILE"

echo "===================================="
echo "          SETUP-PANEL               "
echo "===================================="

# System vorbereiten
echo "### Vorbereitung: System aktualisieren und wget sowie unzip installieren ###"
sudo apt update && sudo apt upgrade -y
sudo apt install wget unzip -y

# Überprüfen, ob die ZIP-Datei bereits existiert
if [ -f "$ZIP_FILE" ]; then
    echo "Die ZIP-Datei $ZIP_FILE existiert bereits. Sie wird nicht erneut heruntergeladen."
else
    echo "### ZIP-Datei wird heruntergeladen ###"
    wget -O "$ZIP_FILE" "$ZIP_URL"
    if [ $? -ne 0 ]; then
        echo "Fehler beim Herunterladen der ZIP-Datei. Bitte überprüfen Sie die URL."
        exit 1
    fi
fi

# ZIP-Datei entpacken
echo "### Entpacken der ZIP-Datei in $SCRIPT_DIR ###"
mkdir -p "$SCRIPT_DIR"
unzip -o "$ZIP_FILE" -d "$SCRIPT_DIR"
if [ $? -ne 0 ]; then
    echo "Fehler beim Entpacken der ZIP-Datei."
    exit 1
fi

# Skripte ausführbar machen
chmod +x $SCRIPT_DIR/*

# Menü anzeigen
while true; do
    echo ""
    echo "Wählen Sie eine Option:"
    echo "1) Homepage einrichten"
    echo "2) Domain-Konfiguration ausführen"
    echo "3) Firewall einrichten"
    echo "4) Antivirus einrichten"
    echo "5) Beenden und aufräumen"
    echo ""
    read -p "Ihre Auswahl: " CHOICE

    case $CHOICE in
        1)
            echo "### Homepage Setup gestartet... ###"
            sudo $SCRIPT_DIR/homepage.sh
            echo "### Homepage Setup abgeschlossen! ###"
            ;;
        2)
            echo "### Domain-Setup gestartet ###"
            sudo $SCRIPT_DIR/domain.sh
            echo "### Domain Setup abgeschlossen! ###"
            ;;
        3)
            echo "### Firewall-Setup gestartet ###"
            sudo $SCRIPT_DIR/firewall.sh
            echo "### Firewall-Setup abgeschlossen! ###"
            ;;
        4)
            echo "### Antivirus-Setup gestartet ###"
            sudo $SCRIPT_DIR/antivirus.sh
            echo "### Antivirus-Setup abgeschlossen! ###"
            ;;    
        5)
            echo "### Aufräumen und Beenden ###"
            read -p "Sind Sie sicher, dass Sie alle temporären Dateien löschen möchten? (y/n): " CONFIRM
            if [ "$CONFIRM" != "y" ]; then
                echo "Alle temporären Dateien wurden nicht entfernt."
                echo "Setup-Panel beendet. Auf Wiedersehen!"
                exit 0
            fi
            rm -rf "$SCRIPT_DIR" "$ZIP_FILE"
            echo "Der Ordner $SCRIPT_DIR und die ZIP-Datei $ZIP_FILE wurden entfernt."
            echo "Setup-Panel beendet. Auf Wiedersehen!"
            exit 0
            ;;
        *)
            echo "Ungültige Auswahl. Bitte versuchen Sie es erneut."
            ;;
    esac
done
