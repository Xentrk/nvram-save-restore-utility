#!/bin/sh

# User exit nvram-user.sh
# Parameters passed
# $1 save id string in "yyyymmddhhmm_MODEL-macid" format

# Sample to create a tar backup of nvram-save data

# Check if parameter passed
if [ -z "$1" ]; then
  printf '\n%s\n\n' "ERROR: Expecting user to specify save id string in yyyymmddhhmm_MODEL-macid format"
  exit 0
fi

# Get current working directory
cwd="$(dirname "$(readlink -f "$0")")"

# Check if nvram-restore file exists
if [ -f "$cwd/backup/nvram-restore-$1.sh" ]; then
  printf '\n%s\n\n' "$cwd/backup/nvram-restore-$1.sh file found"
else
  printf '\n%s\n\n' "ERROR: $cwd/backup/nvram-restore-$1.sh does not exist. No file to tar."
  exit 0
fi

# Check if jffs restore directory exists
if [ -d "$cwd/backup/jffs-$1" ]; then
  printf '\n%s\n\n' "$cwd/backup/jffs-$1 directory found"
else
  printf '\n%s\n\n' "ERROR: $cwd/backup/jffs-$1 directory does not exist. No jffs backup directory to tar."
  exit 0
fi

echo "Creating nvram-backup-$1.tar.gz"
tar -cvf "$cwd/backup/nvram-backup-$1.tar.gz" "$cwd/backup/nvram-restore-$1.sh" "$cwd/backup/jffs-$1"
