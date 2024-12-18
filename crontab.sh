#!/bin/bash

# Funktion zum Hinzufügen von Crontab-Einträgen
add_crontab() {
    local CRON_JOB="$1"

    # Prüfen, ob der Crontab-Eintrag bereits existiert
    (crontab -l 2>/dev/null | grep -F "$CRON_JOB") && echo "Crontab-Eintrag existiert bereits: $CRON_JOB" && return

    # Wenn der Eintrag nicht existiert, hinzufügen
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Crontab-Eintrag wurde hinzugefügt: $CRON_JOB"
}
