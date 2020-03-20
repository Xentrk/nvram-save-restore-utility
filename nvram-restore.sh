#!/bin/sh
# shellcheck disable=SC1001 # SC1001: This \/ will be a regular '/' in this context.
# shellcheck disable=SC2012 # Ignore Use find instead of ls to better handle non-alphanumeric filenames. Vers of find needed is only available in entware?
# shellcheck disable=SC2034 # Ignore "color appears unused" msgs
# shellcheck disable=SC2068 # Don't want to quote array $@
###########################################################################################################################################
#Version=30.3.0
VERSION=30.3.0
# nvram-restore.sh
# General front end to calling generated nvram-restore-yyyymmdd-macid scripts
# Supports OEM and Merlin firmware ONLY
#
# Changelog
#------------------------------------------------
# Version 30.3			  12-January-2020
# - Xentrk POSIX Updates
#
# Version 30.1			    xx-xxxxxxxxx-20xx
# - Martineau Hacks
# - Process list of files with options to delete one or a range of files
# see nvram-save.sh    	nvram-save.sh: WARNING: nvram-merlin.ini is mismatched version
#												nvram-save.sh: WARNING: nvram-excp-merlin.sh is mismatched version
#												nvram-save.sh: WARNING: jffs-restore.sh is mismatched version
#
# Version 26.1			    15-September-2017
# - minor prompt change
#
# Version 26.0			    16-Aug-2017
# - change version numbering
# - updates for migration and clean restore
# - alert for mac address mismatch instead of aborting
#
# Version 25			    8-Aug-2017
# - support doing a migration restore from a full save file
# - fix run log formatting
#
# Version 24			    2-May-2016
# - version update only
#
# Version 23			    3-April-2016
# - add help text for clean restore
#
# Version 22			    27-October-2015
# - add ini version to runlog
# - version variable name update
#
# Version 21			    6-August-2015
# - version update only
#
# Version 20			    3-August-2015
# - enable running script from other than current directory
#
# Version 19			     16-June-2015
# - version update only for ini
#
# Version 18			     14-June-2015
# - prompt for clean restore with file generated
#   by latest level
# - add codelevel to runlog
# - added exit for no valid restore scripts
#
# Version 17			    29-April-2015
# - version update only for ini
#
# Version 16			    16-April-2015
# - first release as part of Version 16 package
# - use last run for restore if none specified
#
############################################################################################EIC Hack ######################################

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

Parse() {

  # 	Parse		"Word1,Word2|Word3" ",|" VAR1 VAR2 REST
  #				(Effectively executes VAR1="Word1";VAR2="Word2";REST="Word3")
  OLD_IFS=$IFS
  TEXT="$1"
  IFS="$2"
  shift 2
  read -r $@ <<EOF
$TEXT
EOF
  IFS=$OLD_IFS
}

Validate_Input() {

  INPUT=$1

  Parse "$INPUT" " " INPUT ACTION
  echo "$INPUT" | grep -q "\-" && Parse "$INPUT" "- " INPUT MATCH_TO
  LISTNUM=1
  #MULTI=
  MATCH_FROM=$INPUT
  MATCH="9999"
  #if [ -n "$MATCH_TO" ] && [ -z "$(echo $MATCH_TO | grep -E "^[1-9]+$")" ];then   # Prevent accidental say 6-99 deletion when only 6-9 intended!
  ##if [ -n "$MATCH_TO" ] && [ -z "$(echo "$MATCH_TO" | grep -E "^[1-9]+[0-9]*$")" ]; then # Remove safeguard
  if [ -n "$MATCH_TO" ] && echo "$MATCH_TO" | grep -qvE "^[1-9]+[0-9]*$"; then # Remove safeguard
    MATCH_TO=$MATCH_FROM
    printf '%b\a\t%s\n\n%b' "$cBRED" "***ERROR valid number selection/range" "$cRESET" && \
    exit 96
  fi

  if [ -z "${INPUT##*[!0-9]*}" ]; then # Try and trap "8^H" where backspace is wrong!
    printf '%b\a\n\t%s\n\n%b' "$cBRED" "***ERROR Invalid number $INPUT" "$cRESET"
    exit 97
  else
    if [ "$INPUT" -gt "$(echo "$DIR_LISTING" | wc -w)" ]; then
      printf '%b\a\n\t%s%c%s%c%s\n\n%b' "$cBRED" "***ERROR selection " "'" "$INPUT" "'" " out of range" "$cRESET"
      exit 98
    fi
  fi

  if [ -z "$MATCH_TO" ]; then
    MATCH_TO=$MATCH_FROM
  fi

  for ITEM in $DIR_LISTING; do
    if [ "$ACTION" = "del" ] && [ "$LISTNUM" -ge "$MATCH_FROM" ] && [ "$LISTNUM" -le "$MATCH_TO" ]; then
      MATCH=$LISTNUM
    fi
    #echo "DEBUG From=$MATCH_FROM To=$MATCH_TO Match=$MATCH Item=$ITEM Listnum=$LISTNUM"
    if [ "$LISTNUM" -eq "$MATCH" ]; then
      restore_version=$(echo "$ITEM" | sed 's/.sh//')                       # Strip '.sh' suffix
      restore_version=$(echo "$restore_version" | sed 's/nvram-restore-//') # Strip 'nvram-restore-' prefix
      restore_version=$(echo "$restore_version" | sed "s|$dwd||;s|/||")     # strip out directory path and leading /
      if [ -z "$ACTION" ]; then
        break
      else
        if [ "$ACTION" = "del" ] || [ "$ACTION" = "delX" ]; then
          if [ "$LISTNUM" -eq "$MATCH" ] && [ "$(echo $@ | grep -c "test")" -eq 0 ]; then
            if [ "$TEST" != "testmode" ]; then
              rm "${dwd}/nvram-restore-${restore_version}.sh" 2>/dev/null
              rm "${dwd}/nvram-all-${restore_version}.txt" 2>/dev/null
              rm "${dwd}/nvram-usr-${restore_version}.txt" 2>/dev/null
              rm "${dwd}/nvram-ini-${restore_version}.txt" 2>/dev/null
              rm "${dwd}/nvram-backup-${restore_version}.tar.gz" 2>/dev/null
              # ...and the JFFS directory
              [ -d "${dwd}/jffs-${restore_version}" ] && rm -rf "${dwd}/jffs-${restore_version}"
              # ...and the log entry?
              #grep -v "${restore_version}" nvram-util.log > nvram-util.log2; mv nvram-util.log2 nvram-util.log
              sed -i "/${restore_version}/d" nvram-util.log
              printf '%b\t%s%b%s%b%s\n\n' "$cBWHT$aBOLD" "Deleted                   (" "$cRED" "*$restore_version.*" "$cBWHT" ") "
            else
              printf '%b\t%s%b%s%b%s\n\n' "$cBWHT" "Test: Deleted                   (" "$cRED" "*$restore_version.*" "$cBWHT" ") "
            fi
          fi
        else
          printf '%b\a\n\t%s%c%s%c\n\n%b' "$cBRED" "***ERROR action " "'" "$ACTION" "'" "$cRESET"
          break
        fi
      fi
    fi
    LISTNUM=$((LISTNUM + 1))
  done
  printf '%b' "$cRESET"
}

ANSIColours
#MYROUTER=$(nvram get computer_name)
#MYROUTER="$(nvram get model)"
if [ "$1" = "test" ]; then
  TEST="testmode"
  shift
fi
########################################################################################################################
restore_version=$1
opt=""
scr_name=$(basename "$0")
#cwd=$(pwd)
cwd="$(dirname "$(readlink -f "$0")")"
if [ -d "$cwd/backup" ]; then
  dwd=$cwd/backup
else
  dwd=$cwd
fi
runlog="$cwd/nvram-util.log"
space4="    "
codelevel=""

echo ""
if [ "$restore_version" = "" ] || [ "$1" = "Y" ]; then
  macid=$(nvram get "et0macaddr")
  #  if [ "$macid" = "" ]; then
  if [ "$macid" = "" ] || [ "$macid" = "00:00:00:00:00:00" ]; then
    macid=$(nvram get "et1macaddr")
    if [ "$macid" = "" ] || [ "$macid" = "00:00:00:00:00:00" ]; then
      # Xentrk noticed MACID is all 0"
      macid=$(nvram get "et2macaddr")
    fi
  fi
  macid=$(echo "$macid" | cut -d':' -f 5,6 | tr -d ':' | tr '[:upper:]' '[:lower:]')
  restore_version=$(grep "nvram-save.sh" "$runlog" | tail -1 | awk -F' ' '{print $2}')
  if [ "$restore_version" = "" ]; then
    echo "No valid nvram-save file found. Exiting."
    echo ""
    exit 3
  fi
  macsave=$(printf '%s' "$restore_version" | tail -c 4)

  if [ "$1" != "Y" ]; then
    if [ "$macsave" != "$macid" ]; then
      #################################################################################EIC hack###############################
      printf '%b' "$cRED"
      ########################################################################################################################
      echo "Last nvram save/restore (nvram-restore-$restore_version.sh)"
      echo "WARNING: Last nvram-save MAC address ($macsave)"
      echo "  does not match current router MAC  ($macid)!"
      echo "This may be valid if you are migrating settings from one router to another"
      echo ""
      echo "If you wish to use a different restore file, answer N and specify the"
      echo "  restore file id the command line in the form"
      echo "  yyyymmddhhmm-mmmm"
      #################################################################################EIC hack###############################
      printf '%b' "$cRESET"
      printf '%s' "Do you want to proceed [Y/N]? "
      read -r "INPUT"
      while true; do
        case "$INPUT" in
        "Y" | "y")
          break
          ;;
        *)
          printf '%b\n\t%s\n\n%b' "$cBYEL" "Restore aborted" "$cRESET"
          exit 2
          ;;
        esac
      done
      echo ""
    fi
    #################################################################################EIC hack###############################
    I=1
    # Only list files that were created by nvram-save (in this millenium! 20xx)
    #	i.e. ignore non standard files e.g. 'nvram-restore-OVPN.sh' etc.

    DIR_LISTING="$(ls -F -- "$dwd"/*nvram-restore-20* | sed 's/*//' 2>/dev/null)"
    FILE_NAME=$(echo "$DIR_LISTING" | sed 's|'"${dwd}"\/'||')
    #DIR_LISTING=$(/usr/bin/find . -maxdepth 1 -type f | sort | grep "nvram-restore-20" | sed 's/.\///')
    printf '\t%s\n\n' "  $scr_name NVRAM Restore Utility - Version $VERSION"
    printf '\t%b%s%b%s\n\n' "$cBBLU" "NVRAM Restore File Directory: " "$cBWHT" "$dwd"
    for ITEM in $FILE_NAME; do
      #TIMESTAMP=$(echo "$ITEM" | awk '{ string=substr($0, 37, 12); print string; }')
      TIMESTAMP=$(echo "$ITEM" | awk '{ string=substr($0, 15, 12); print string; }')
      VER=$(grep -m 1 "$TIMESTAMP" nvram-util.log | awk '{print $9" "$10}' | sed 's/ $//') # Martineau FIX Xentrk
      if [ -z "$VER" ]; then
        VER="--------"
      fi
      printf '%b%3d : %b%s%b\t%s\n' "$cBWHT" "$I" "$cBBLU" "$ITEM" "$cBCYA" "Ver=$VER"
      I=$((I + 1))
    done

    printf '%b\n\t%s%b%s%b%s\n' "$cBWHT" "Restore last NVRAM save ? (" "$aBOLD$cBYEL" "nvram-restore-$restore_version.sh" "$cBWHT" ") "
    printf '\t%s' "{ n[{-n}] [ del ] | Y } (or press ENTER to ABORT) > "
    read -r "INPUT"
    printf '%b' "$cRESET"
    ########################################################################################################################
    while true; do
      case "$INPUT" in
      "Y" | "y")
        break
        ;;
        #################################################################################EIC hack###############################
        #*)
      "N" | "n")
        printf '%b\n\t%s\n\n%b' "$cBYEL" "Restore aborted" "$cRESET"
        exit 1
        ;;
        #################################################################################EIC hack###############################
      *)
        echo "$INPUT" | grep -qE "^[1-9]" && Validate_Input "$INPUT" || printf '%b\n\t%s\n\n%b' "$cBYEL" "Restore aborted" "$cRESET" && exit 0
        if [ -z "$ACTION" ]; then
          printf '%b\t%s%b%s%b%s' "$cBWHT" "Restoring    NVRAM save (" "$aBOLD$cBGRE" "nvram-restore-$restore_version.sh" "$cBWHT" ")"
        else
          exit 0
        fi
        ;;
        ########################################################################################################################
      esac
    done
  fi
fi
restore_file="nvram-restore-$restore_version.sh"
echo ""
if [ ! -f "$dwd/$restore_file" ]; then
  echo "Script $dwd/$restore_file does not exist. Exiting."
  echo ""
  exit 1
fi

if [ "$1" = "Y" ]; then
  opt="-clean"
fi

if grep -q "Migrate restore from full restore supported" "$dwd"/"$restore_file" && [ "$macsave" != "MIGR" ]; then
  if [ "$opt" = "" ] && [ "$macsave" != "$macid" ]; then
    echo ""
    #################################################################################EIC hack###############################
    printf '%b' "$cBYEL"
    echo "A migration restore is used when transferring settings from one"
    echo "  router to another, even if they are both the same model type"
    echo "This option skips restoring some NVRAM variables which are unique"
    echo "  to a specific router, such as the Router Name, which by default is"
    echo "  based on the router MAC address."
    echo "If you are restoring to a different router from that used to generate the"
    echo "  nvram-save, you should answer Y to the migration restore prompt"
    #################################################################################EIC hack###############################
    printf '%b%s' "$cRESET" "Perform a migration restore [Y/N]? "
    read -r "INPUT"
    while true; do
      case "$INPUT" in
      "Y" | "y")
        opt="-migr"
        continue
        ;;
      *)
        opt=""
        ;;
      esac
    done
  fi
else
  if [ "$macsave" = "MIGR" ]; then
    echo "Performing a migration restore from a migration nvram-save"
    opt="-clean"
  else
    echo "Migration restore from a full nvram-save is not supported on this save file"
    echo ""
    printf '%s' "Do you want to proceed [Y/N]? "
    read -r "INPUT"
    while true; do
      case "$INPUT" in
      "Y" | "y")
        break
        ;;
      *)
        printf '%b\n\t%s\n\n%b' "$cBYEL" "Restore aborted" "$cRESET"
        exit 2
        ;;
      esac
    done
    opt=""
  fi
fi

#grep -q "Clean restore supported" $dwd/$restore_file
#if [ $? = 0 ]; then
if [ "$opt" = "" ]; then
  echo ""
  #################################################################################EIC hack###############################
  printf '%b' "$cBYEL"
  echo "A clean restore will restore only those NVRAM settings"
  echo "  which have been initialized by the router after a factory reset"
  echo "This option should by used when reverting to an earlier"
  echo "  firmware level, when updating past a single firmware release,"
  echo "  when moving betwwen OEM and Merlin firmware or"
  echo "  to ensure any special use or obsolete NVRAM variables are cleared"
  echo "If in doubt, answer Y to perform a clean restore"
  #################################################################################EIC hack###############################
  printf '\n%b%s' "$cRESET" "Perform a clean restore and remove unsed NVRAM variables [Y/N]? "
  read -r "INPUT"
  while true; do
    case "$INPUT" in
    "Y" | "y")
      opt="-clean"
      break
      ;;
    *)
      printf '%b\n\t%s\n\n%b' "$cBYEL" "Restore aborted" "$cRESET"
      exit 2
      #opt=""
      ;;
    esac
  done
fi
#################################################################################EIC hack###############################
start=$(date +%s)
########################################################################################################################
# Run the restore
sh "$dwd"/"$restore_file" "$opt"

# Update runlog
codelevel=$(grep "codelevel=" "$dwd"/"$restore_file" | awk -F'=' '{print $2}')
version=$(grep "#VERSION=" "$dwd"/"$restore_file" | awk -F'=' '{print $2}')

############################################################################################EIC Hack ######################################
end=$(date +%s)
difftime=$((end - start))
echo "$(printf '%-20s' "$scr_name")$(printf '%-30s' "$restore_version$space4$(date)$space4")$(printf '%-28s' "$codelevel") #Version=$version $((difftime / 60)) minutes and $((difftime % 60)) seconds elapsed" >>"$runlog"
printf '%b' "$cBGRE"
# List stats for this invocation
tail -1 "$runlog"
printf '%b' "$cRESET"
###########################################################################################################################################

echo ""
exit 0
