#!/bin/bash

option=$(zenity --list --title="🔐 Encrypted File Locker" \
    --text="What would you like to do?" \
    --radiolist --column="Pick" --column="Option" TRUE "Encrypt files" FALSE "Decrypt files" FALSE "Back" --width=900 --height=500)

if [[ $option == "Encrypt files" ]]; then
    files=$(zenity --file-selection --multiple --separator="|" --title="Select files to encrypt")
    method=$(zenity --list --title="Encryption Method" \
        --text="Choose encryption method:" \
        --radiolist --column="Pick" --column="Method" TRUE "GPG" FALSE "ZIP")

    password=$(zenity --password --title="Enter Password")

    IFS="|" read -ra file_array <<< "$files"
    for file in "${file_array[@]}"; do
        dir_path=$(dirname "$file")
        if [[ $method == "GPG" ]]; then
            echo "$password" | gpg --batch --yes --passphrase-fd 0 -o "$file.gpg" -c "$file"
        else
            zip -j -e "${file}.zip" "$file"
        fi
    done

    zenity --info --text="✅ Files encrypted successfully."
    notify-send "🔐 Encryption Done" "All selected files have been encrypted."

elif [[ $option == "Decrypt files" ]]; then
    files=$(zenity --file-selection --multiple --separator="|" --title="Select encrypted files to decrypt")
    password=$(zenity --password --title="Enter Password")

    IFS="|" read -ra file_array <<< "$files"
    success_count=0

    for file in "${file_array[@]}"; do
        file_dir=$(dirname "$file")

        if [[ $file == *.gpg ]]; then
            output_file="$file_dir/$(basename "${file%.gpg}")"
            echo "$password" | gpg --batch --yes --passphrase-fd 0 -o "$output_file" -d "$file" 2>/tmp/gpg_error.log

            if [[ $? -ne 0 ]]; then
                error_msg=$(< /tmp/gpg_error.log)
                zenity --error --title="Decryption Failed" \
                    --text="❌ Failed to decrypt: $(basename "$file")\n\n🔐 Reason:\n${error_msg:-Wrong password or corrupt file.}"
                notify-send "❌ Decryption Failed" "Could not decrypt $(basename "$file")."
                continue
            fi

            ((success_count++))

        elif [[ $file == *.zip ]]; then
            unzip -P "$password" "$file" -d "$file_dir" &>/tmp/zip_error.log

            if [[ $? -ne 0 ]]; then
                error_msg=$(< /tmp/zip_error.log)
                zenity --error --title="Unzip Failed" \
                    --text="❌ Failed to unzip: $(basename "$file")\n\n🔐 Reason:\n${error_msg:-Wrong password or corrupt file.}"
                notify-send "❌ Decryption Failed" "Unzip failed for $(basename "$file")."
                continue
            fi

            ((success_count++))
        fi
    done

    if [[ $success_count -gt 0 ]]; then
        zenity --info --text="🔓 Decryption completed. $success_count file(s) successfully decrypted."
        notify-send "✅ Decryption Complete" "$success_count file(s) decrypted successfully."
    fi
fi
