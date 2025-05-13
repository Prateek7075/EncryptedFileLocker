#!/bin/bash

while true; do
    action=$(zenity --list --title="📦 Encrypted Backup & Restore Tool" \
        --text="Choose an action:" \
        --radiolist --column="Pick" --column="Action" TRUE "Backup folder" FALSE "Restore backup" FALSE "Exit" --width=900 --height=500)

    case "$action" in
        "Backup folder")
            folder_to_backup=$(zenity --file-selection --directory --title="Select folder to backup")
            [[ -z "$folder_to_backup" ]] && continue

            folder_name=$(basename "$folder_to_backup")
            backup_location=$(zenity --file-selection --directory --title="Select destination to save backup")
            [[ -z "$backup_location" ]] && continue

            backup_file="$backup_location/${folder_name}_backup_$(date +%Y-%m-%d_%H-%M-%S).tar.gz"

            # Create tar.gz including folder itself
            (
                cd "$(dirname "$folder_to_backup")" || exit 1
                tar -czvf "$backup_file" "$folder_name"
            ) | zenity --progress --pulsate --title="Creating Backup" --text="Please wait while the backup is being created..." --auto-close

            if [[ -f "$backup_file" ]]; then
                zenity --info --text="✅ Backup created successfully:\n$backup_file"
                notify-send "✅ Backup Complete" "Backup created at $backup_file"
            else
                zenity --error --text="❌ Backup failed. Please check permissions or paths."
                notify-send "❌ Backup Failed" "Could not create backup."
            fi
            ;;

        "Restore backup")
            backup_file=$(zenity --file-selection --title="Select .tar.gz backup file to restore")
            [[ -z "$backup_file" ]] && continue

            restore_location=$(zenity --file-selection --directory --title="Select destination to restore files")
            [[ -z "$restore_location" ]] && continue

            (
                tar -xzvf "$backup_file" -C "$restore_location"
            ) | zenity --progress --pulsate --title="Restoring Backup" --text="Please wait while the backup is being restored..." --auto-close

            if [[ $? -eq 0 ]]; then
                zenity --info --text="✅ Backup restored successfully to:\n$restore_location"
                notify-send "✅ Restore Complete" "Backup restored to $restore_location."
            else
                zenity --error --text="❌ Failed to restore backup. Please check the file and permissions."
                notify-send "❌ Restore Failed" "Could not extract backup."
            fi
            ;;

        "Exit" | *)
            break
            ;;
    esac
done