#!/bin/sh
# jffs-restore.sh
# Save jffs directory for restore after factory reset
# Supports OEM and Merlin firmware ONLY
#Version=30.3.0
############################################################################################Martineau Hack ######################################
# shellcheck disable=SC2034 # Ignore "color appears unused" msgs
# shellcheck disable=SC2012 # disable as the find version needed is on entware and does not work after factory reset. Use find instead of ls to better handle non-alphanumeric filenames.
# shellcheck disable=SC1001  # SC1001: This \/ will be a regular '/' in this context.
###########################################################################################################################################
# Changelog
#------------------------------------------------
# Version 30.3			  18-January-2020
# - Xentrk POSIX Updates
#
# Version 30.1			  xx-xxxxxxxxx-20xx
# - Martineau Hacks
#
# Version 26.1			  15-September-2017
# - query on mac mismatch
#
# Version 26.0			  31-August-2017
# - version update only
#
# Version 25			  8-August-2017
# - fix run log formatting
#
# Version 24			  2-May-2016
# - version update only
#
# Version 23			  3-April-2016
# - version update only
#
# Version 22			  27-October-2015
# - version variable name update
#
# Version 21			  6-August-2015
# - version update only
#
# Version 20			  3-August-2015
# - enable running script from other than current directory
#
# Version 19			  16-June-2015
# - version update only for ini
#
# Version 18			  14-June-2015
# - added exit for no restore directory found
#
# Version 17			  29-April-2015
# - version update only for ini
#
# Version 16			  16-April-2015
# - use last run for restore if none specified
#
# Version 15			  25-February-2015
# - version update only
#
# Version 14			  7-February-2015
# - log results to syslog
#
# Version 12			  1-February-2015
# - do not hardcode jffs restore directory parent
#
# Version 11                      29-January-2015
# - no change
#
# Version 10 - first package release
# - restore /jffs directory       18-January-2015
#
#------------------------------------------------
#################################################################################Martineau hack###############################
ANSIColours() {

  cRESET="\e[0m"
  cBLA="\e[30m"
  cRED="\e[31m"
  cGRE="\e[32m"
  cYEL="\e[33m"
  cBLU="\e[34m"
  cMAG="\e[35m"
  cCYA="\e[36m"
  cGRA="\e[37m"
  cBGRA="\e[90m"
  cBRED="\e[91m"
  cBGRE="\e[92m"
  cBYEL="\e[93m"
  cBBLU="\e[94m"
  cBMAG="\e[95m"
  cBCYA="\e[96m"
  cBWHT="\e[97m"
  aBOLD="\e[1m"
  aDIM="\e[2m"
  aUNDER="\e[4m"
  aBLINK="\e[5m"
  aREVERSE="\e[7m"
  cRED_="\e[41m"
  cGRE_="\e[42m"

}

ANSIColours
VERSION=30.3.0
########################################################################################################################
jffs_version=$1
if [ "$(echo "$jffs_version" | awk '{ string=substr($0, 1, 4); print string; }')" = "jffs" ]; then
  jffs_dir=$jffs_version
  jffs_version=$(echo "$jffs_version" | awk '{ string=substr($0, 6, 13); print string; }')
else
  jffs_dir="jffs-"$jffs_version
fi
scr_name=$(basename "$0")
NSRU_LOCATION="$(grep -ow "NSRU_LOCATION.*" /mnt/NSRU_LOCATION 2>/dev/null | grep -vE "^#" | awk '{print $1}' | cut -c 15-)"
#cwd=$(pwd)
cwd="$(dirname "$(readlink -f "$0")")"
if [ -d "$cwd/backup" ]; then
  dwd=$cwd/backup
else
  dwd=$cwd
fi
runlog="$cwd/nvram-util.log"

echo ""
if [ "$jffs_version" = "" ]; then
  macid=$(nvram get "et0macaddr")
  if [ "$macid" = "" ] || [ "$macid" = "00:00:00:00:00:00" ]; then
    macid=$(nvram get "et1macaddr")
    if [ "$macid" = "" ] || [ "$macid" = "00:00:00:00:00:00" ]; then
      # Xentrk noticed MACID is all 0"
      macid=$(nvram get "et2macaddr")
    fi
  fi
  macid=$(echo "$macid" | cut -d':' -f 5,6 | tr -d ':' | tr '[:upper:]' '[:lower:]')
  jffs_version=$(grep "jffs-save" "$runlog" | grep "$macid" | tail -1 | awk -F' ' '{print $2}')
  if [ "$jffs_version" = "" ]; then
    echo "No saved jffs directory found for MAC: $macid"
    echo "Exiting - Restore aborted"
    exit 2
  fi
  macsave=$(printf '%s' "$jffs_version" | tail -c 4)

  if [ "$macsave" != "$macid" ]; then
    echo "Last jffs save (jffs-$jffs_version.sh)"
    echo "WARNING: Last jffs-save MAC address ($macsave)"
    echo "  does not match current router MAC  ($macid)!"
    echo "This may be valid if you are migrating settings from one router to another"
    echo ""
    printf '%s' "Do you want to proceed [Y/N]? "
    read -r "input"
    while true; do
      case "$input" in
      "Y" | "y")
        #continue
        break
        ;;
      *)
        echo ""
        echo "Exiting - Restore aborted"
        echo ""
        exit 2
        ;;
      esac
    done
    echo ""
  fi

  jffs_dir="jffs-"$jffs_version
  #echo "If you wish to use a different restore file, answer N and specify the"
  #echo "  saved directory file id on the command line in the form"
  #echo "  yyyymmddhhmm-mmmm"

  #echo ""
  #################################################################################Martineau hack###############################
  #read -p "Restore last saved directory ($jffs_dir) [Y/N]?" input
  spaces="   "
  logger -t "$scr_name" "JFFS Restore Utility - Version $VERSION"
  printf '%s\n\n' "  $scr_name JFFS Restore Utility - Version $VERSION"
  #ls -F --color | grep / | awk '{print NR".\t"$0}'
  #ls -d --color -- */ | awk '{print NR".\t"$0}'
  #ls -d --color -- ./backup/*jffs-* | awk '{ printf("%3d : %s\n", NR, $0) }'
  # | sed 's|./backup/||'
  I=1
  DIR_LISTING=$(ls -d -- "$dwd"/*jffs-*) #| awk '{ printf("%3d : %s\n", NR, $0) }'
  FILE_NAME=$(echo "$DIR_LISTING" | sed 's|'"${dwd}"\/'||')
  printf '%b%s%b%s\n\n' "$cBBLU" "  JFFS Restore File Directory: " "$cBWHT" "$dwd"
  for ITEM in $FILE_NAME; do
    printf '%b%6d : %b%s\n' "$cBWHT" "$I" "$cBBLU" "$ITEM"
    I=$((I + 1))
  done
  #  ls -Fd --color -- ./backup/*jffs-* | awk '{ printf("%3d : %s\n", NR, $0) }'

  #/usr/bin/find . -maxdepth 1 -type d | sort | awk -v b="$cBBLU" -v w="$cRESET" '{print NR".\t"b$0w}'

  # POSIX update
  #echo -en "$cBWHT""\n\tRestore last saved /jffs/ ? (${aBOLD}${cBYEL}$jffs_dir$cBWHT) "
  printf '%b\n%s%b%s%b%s\n' "$cBWHT" "  Restore last saved /jffs/ ? (" "${aBOLD}${cBYEL}" "$jffs_dir" "$cBWHT" ") "
  #read -p "{ n | Y } (or press ENTER to ABORT) > " input
  printf '%s' "  { n | Y } (or press ENTER to ABORT) > "
  # echo -en "$cRESET"
  printf '%b' "$cRESET"
  read -r "input"
  ########################################################################################################################
  while true; do
    case "$input" in
    "Y" | "y")
      break
      ;;
      #################################################################################Martineau hack###############################
      #*)
    "N" | "n")
      printf '%b\n\t%s%b\n\n' "$cBYEL" "Restore aborted" "$cRESET"
      exit 1
      ;;
      #################################################################################Martineau hack###############################
    *)
      # Abort if invalid option
      #if [ -n "$(echo "$input" | grep -E "^[1-9]")" ]; then
      #  LISTNUM=1
      #  jffs_dir=
      #Xentrk POSIX update
      #  for ITEM in $(ls -F | grep / | grep -oE "20.*\/" | awk '{print $0}'); do
      #for ITEM in $(find . -maxdepth 1 -type d | grep -oE "20.*"); do
      #    if [ "$LISTNUM" -eq "$input" ]; then
      #      jffs_dir="jffs-"${ITEM%%/}
      #      break
      #    fi
      #    LISTNUM=$((LISTNUM + 1))
      #  done
      #else
      #echo -e "$cBYEL""\n\tRestore aborted""\n""$cRESET"
      printf '%b\n\t%s%b\n' "$cBYEL" "Restore aborted" "$cRESET"
      exit 0
      #fi
      ;;
      ########################################################################################################################
    esac
  done
fi
#############################################################################Martineau hack###################################
#echo ""
########################################################################################################################
if [ ! -d "$dwd/$jffs_dir" ]; then
  echo "Directory $jffs_dir does not exist. Exiting."
  echo ""
  exit 1
else
  #########################################################################Martineau hack FIX###############################
  #logger -s -t $scr_name "JFFS Restore Utility - Version "$VERSION
  #logger -s -t $scr_name "Restoring /jffs directory:  "$jffs_dir
  #echo -en "$cBWHT""\tRestoring saved    /jffs/ (${aBOLD}${cBYEL}${jffs_dir}$cBWHT)\n"
  printf '%b\t%s%b%s%b%s\n' "$cBWHT" "Restoring saved /jffs/ (" "${aBOLD}${cBYEL}" "$jffs_dir" "$cBWHT" ")"
  ################################################################################################################

fi
#################################################################################Martineau hack###############################
#echo ""
#echo "WARNING:  This will overwrite/replace the current contents of your /jffs directory"
# POSIX update
#echo -en "$cBRED""\n\tWARNING: This will overwrite/replace the current contents of your /jffs directory! ""$cBWHT"
printf '%b\n\t%s%b\n' "$cBRED" "WARNING: This will overwrite/replace the current contents of your /jffs directory! " "$cBWHT"
########################################################################################################################
printf '\t%s' "Do you want to continue [Y/N] ? "
read -r "input"
case "$input" in
"Y" | "y")
  printf '\n%s\n' "Deleting current contents of /jffs"
  rm -r /jffs/*
  echo "Restoring /jffs"
  cp -af "$dwd/$jffs_dir/." /jffs
  logger -s -t "$scr_name" "/jffs restored from ""$dwd""/""$jffs_dir"
  echo ""
  ;;
*)
  #################################################################################Martineau hack###############################
  #echo ""
  #logger -s -t $scr_name  "Exiting - Restore aborted"
  #echo ""
  #echo -e "$cBYEL""\n\tRestore aborted""\n""$cRESET"
  printf '%b\n\t%s%b\n\n' "$cBYEL" "Restore aborted" "$cRESET"
  ########################################################################################################################
  exit 1
  ;;
esac

echo "$(printf "%-20s" "$scr_name")$(printf "%-20s" "$jffs_version")$(date)" >>"$runlog"

echo "Please reboot manually"
echo ""
exit 0
