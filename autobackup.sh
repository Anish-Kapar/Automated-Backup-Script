#!/bin/bash


BACKUP_DIR="$HOME/backups"
LOG_FILE="$BACKUP_DIR/backup.log"
CONFIG_FILE="$HOME/.auto_backup_config"
TEMP_FILE="/tmp/backup_temp.$$"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Initialize config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "# Automated Backup Configuration" > "$CONFIG_FILE"
    echo "LAST_BACKUP=" >> "$CONFIG_FILE"
    echo "SCHEDULE=" >> "$CONFIG_FILE"
    echo "SELECTED_FILES=" >> "$CONFIG_FILE"
fi

# Source the config file
. "$CONFIG_FILE"

# Function to display banner
show_banner() {
    dialog --backtitle "Automated Backup Script" \
           --title "Welcome to Automated Backup System" \
           --msgbox "\n\nAutomated Backup Script\n\nPress any key to continue..." 12 60
}

# Function to display main menu
main_menu() {
    while true; do
        choice=$(dialog --backtitle "Automated Backup Script" \
                        --title "Main Menu" \
                        --menu "Please select an option:" 15 60 5 \
                        1 "Create New Backup" \
                        2 "Schedule Automatic Backups" \
                        3 "View Backup Logs" \
                        4 "Restore from Backup" \
                        5 "Exit" \
                        3>&1 1>&2 2>&3)

        case $choice in
            1) create_backup ;;
            2) schedule_backups ;;
            3) view_logs ;;
            4) restore_backup ;;
            5) exit_script ;;
            *) exit_script ;;
        esac
    done
}

# Function to create backup
create_backup() {
    # Let user select files/directories
    selected=$(dialog --fselect "$HOME/" 20 60 3>&1 1>&2 2>&3)

    # Get relative path (strip $HOME/)
    relative_path="${selected#$HOME/}"

    # Create backup (relative to $HOME)
    (cd "$HOME" && tar -czf "$backup_file" "$relative_path" 2>&1) | \
    dialog --progressbox "Creating backup..." 20 75


    if [ -z "$selected" ]; then
        dialog --msgbox "No selection made. Returning to main menu." 8 50
        return
    fi

    # Ask for backup name
    backup_name=$(dialog --backtitle "Automated Backup Script" \
                        --title "Backup Name" \
                        --inputbox "Enter a name for your backup (without spaces):" 10 60 \
                        3>&1 1>&2 2>&3)

    if [ -z "$backup_name" ]; then
        backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    fi

    # Create timestamp
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

    # Create backup filename
    backup_file="${BACKUP_DIR}/${backup_name}_${timestamp}.tar.gz"

    # Perform backup
    (tar -czf "$backup_file" "$selected" 2>&1) | \
    dialog --backtitle "Automated Backup Script" \
           --title "Backup in Progress" \
           --progressbox "Creating backup..." 20 75

    # Check if backup was successful
    if [ $? -eq 0 ]; then
        echo "$(date) - Backup successful: $backup_file" >> "$LOG_FILE"
        dialog --msgbox "Backup created successfully!\n\nLocation: $backup_file" 10 60

        # Update config with last backup
        sed -i "s|^LAST_BACKUP=.*|LAST_BACKUP=\"$backup_file\"|" "$CONFIG_FILE"
    else
        echo "$(date) - Backup failed for: $selected" >> "$LOG_FILE"
        dialog --msgbox "Backup failed! Check log file for details." 8 50
    fi
}

# Function to schedule backups
schedule_backups() {
    if [ -n "$SELECTED_FILES" ]; then
        current_schedule="Current schedule: $SCHEDULE\nSelected files: $SELECTED_FILES"
    else
        current_schedule="No schedule currently set"
    fi

    # Let user select files/directories
    selected=$(dialog --backtitle "Automated Backup Script" \
                     --title "Select Files/Directories to Schedule" \
                     --extra-button --extra-label "Use Last" \
                     --fselect "$HOME/" 20 60 \
                     3>&1 1>&2 2>&3)

    # If user pressed "Use Last" button
    if [ $? -eq 3 ]; then
        if [ -n "$LAST_BACKUP" ]; then
            # Extract the original files from last backup
            selected=$(tar -tf "$LAST_BACKUP" | head -1 | sed 's|/.*||')
        else
            dialog --msgbox "No previous backup found. Please select files." 8 50
  fi
    elif [ -z "$selected" ]; then
        dialog --msgbox "No selection made. Returning to main menu." 8 50
        return
    fi

    # Get schedule frequency
    frequency=$(dialog --backtitle "Automated Backup Script" \
                      --title "Schedule Frequency" \
                      --menu "$current_schedule\n\nSelect backup frequency:" 15 60 4 \
                      "daily" "Backup once per day" \
                      "weekly" "Backup once per week" \
                      "monthly" "Backup once per month" \
                      "custom" "Enter custom cron schedule" \
                      3>&1 1>&2 2>&3)

    case $frequency in
        "daily") cron_schedule="0 0 * * *" ;;
        "weekly") cron_schedule="0 0 * * 0" ;;
        "monthly") cron_schedule="0 0 1 * *" ;;
        "custom")
            cron_schedule=$(dialog --backtitle "Automated Backup Script" \
                                 --title "Custom Cron Schedule" \
                                 --inputbox "Enter cron schedule (min hour day month weekday):" 10 60 \
                                 "0 0 * * *" \
                                 3>&1 1>&2 2>&3)
            ;;
        *) return ;;
    esac

    # Update config
    sed -i "s|^SELECTED_FILES=.*|SELECTED_FILES=\"$selected\"|" "$CONFIG_FILE"
    sed -i "s|^SCHEDULE=.*|SCHEDULE=\"$cron_schedule\"|" "$CONFIG_FILE"

    # Create the cron job
    crontab -l | grep -v "$CONFIG_FILE" > "$TEMP_FILE"
    echo "$cron_schedule $0 --auto-backup" >> "$TEMP_FILE"
    crontab "$TEMP_FILE"
    rm -f "$TEMP_FILE"

    dialog --msgbox "Backup scheduled successfully!\n\nFrequency: $frequency\nSchedule: $cron_schedule\nFiles: $selected" 12 60
}

# Function to view logs
view_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        dialog --msgbox "No log file found yet." 8 50
        return
    fi

    dialog --backtitle "Automated Backup Script" \
           --title "Backup Logs" \
           --textbox "$LOG_FILE" 20 80
}

# Function to restore from backup
restore_backup() {


        (tar -xzf "$selected_backup" -C "$restore_location" 2>&1) | \
    dialog --progressbox "Restoring..." 20 75

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        dialog --msgbox "No backups found in $BACKUP_DIR" 8 50
        return
    fi

    # List backup files
    backup_list=$(ls -1t "$BACKUP_DIR"/*.tar.gz)
    counter=1
    for file in $backup_list; do
        options="$options $counter $(basename "$file")"
        counter=$((counter+1))
    done

    selected_index=$(dialog --backtitle "Automated Backup Script" \
                           --title "Select Backup to Restore" \
                           --menu "Available Backups:" 20 80 10 \
                           $options \
                           3>&1 1>&2 2>&3)

    if [ -z "$selected_index" ]; then
        return
    fi

    selected_backup=$(echo "$backup_list" | sed -n "${selected_index}p")

    # Get restore location
    restore_location=$(dialog --backtitle "Automated Backup Script" \
                             --title "Restore Location" \
                             --dselect "$HOME/" 20 60 \
                             3>&1 1>&2 2>&3)

    if [ -z "$restore_location" ]; then
        dialog --msgbox "No location selected. Restore cancelled." 8 50
        return
    fi

    # Perform restore
        (tar -xzf "$selected_backup" -C "$restore_location" --strip-components=3 2>&1) | \
        dialog --progressbox "Restoring..." 20 75

    if [ $? -eq 0 ]; then
        echo "$(date) - Restore successful: $selected_backup to $restore_location" >> "$LOG_FILE"
        dialog --msgbox "Restore completed successfully!" 8 50
    else
        echo "$(date) - Restore failed: $selected_backup" >> "$LOG_FILE"
        dialog --msgbox "Restore failed! Check log file for details." 8 50
    fi
}

# Function for automatic backup (called by cron)
auto_backup() {
    if [ -z "$SELECTED_FILES" ]; then
        echo "$(date) - Scheduled backup failed: No files selected" >> "$LOG_FILE"
        exit 1
    fi

    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    backup_file="${BACKUP_DIR}/auto_${timestamp}.tar.gz"

    tar -czf "$backup_file" $SELECTED_FILES >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        echo "$(date) - Scheduled backup successful: $backup_file" >> "$LOG_FILE"
    else
        echo "$(date) - Scheduled backup failed for: $SELECTED_FILES" >> "$LOG_FILE"
    fi
}

# Function to exit script
exit_script() {
    clear
    echo "Thank you for using the Automated Backup Script!"
    exit 0
}

# Check for auto-backup flag
if [ "$1" = "--auto-backup" ]; then
    auto_backup
    exit 0
fi

# Main script execution
clear
show_banner
main_menu
