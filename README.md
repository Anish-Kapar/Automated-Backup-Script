# Automated Backup System

## Overview
This project is an **Automated Backup Script** written in Bash. It provides an easy-to-use menu-driven interface (using `dialog`) to create backups of your files and directories, schedule automatic backups via cron jobs, view backup logs, and restore files from backups.

## Features
- Create manual backups with custom names.
- Schedule automatic backups (daily, weekly, monthly, or custom cron schedules).
- View backup logs to track backup history.
- Restore files from existing backup archives.
- User-friendly text-based UI using `dialog`.

## How to Use
1. Run the script:
   ```bash
   ./autobackup.sh
   ```
   or
   ```bash
   bash autobackup.sh
   ```
3. Use the menu to select your desired action.

4. For scheduling, select files and set your preferred backup frequency.

5. View logs or restore backups anytime.

## Screenshots
### Landing page after running script:
![image](https://github.com/user-attachments/assets/8ac8904c-ae0b-4e70-a97c-9bf04fb875b3)
### Main Menu to choose required operation:
![image](https://github.com/user-attachments/assets/b25ba7f9-d3cf-4161-963c-39eb0a77faf8)
### Backup Logs:
![image](https://github.com/user-attachments/assets/b04324dc-e687-4435-b533-961ae2d8f884)
### Exit:
![image](https://github.com/user-attachments/assets/3f9fb6e9-1235-444c-a0df-f31cb3f60530)

## Requirements
Linux environment with Bash shell.

dialog package installed (sudo apt install dialog on Debian/Ubuntu).

Cron service enabled for scheduling.

## Installation
Clone or download the repository.

Make the script executable:

```bash
chmod +x backup.sh
```
Run the script.
