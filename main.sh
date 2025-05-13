#!/bin/bash

while true; do
    action=$(zenity --list --title="🔐 Encrypted File Locker & Backup Tool" \
        --text="Choose a module to work with:" \
        --radiolist --column="Pick" --column="Action" TRUE "Encrypted File Locker" FALSE "Backup & Recovery" FALSE "Exit" --width=900 --height=500)

    case "$action" in
        "Encrypted File Locker")
            bash encrypted_file_locker.sh
            ;;
        "Backup & Recovery")
            bash backup_and_restore.sh
            ;;
        "Exit" | "" )
            exit 0
            ;;
    esac
done
