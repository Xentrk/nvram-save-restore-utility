#!/bin/sh
#Version=30.3.0
# nvram-excp-merlin.sh
# Adjust nvram parameters for code specific issues
# Supports OEM and Merlin firmware ONLY
# Changelog
#------------------------------------------------
# Version 30.3		  1-January-2020
# - version only update
#
# Version 26.1			  15-September-2017
# - version only update
#
# Version 26.0			  31-August-2017
# - add vpn client accept dns changes
#
# Version 25			  8-August-2017
# - sync with 380.67 Merlin and V27 fork
# - add ssh enable changes
# - refactor and comment code
#
# Version 24			  2-May-2016
# - set qos_type if moving from early code level
#
# Version 23			  3-April-2016
# - handle mac_list differences between fw levels
# - auto correct bad wl_band vars
# - some changes dependent on not in migration mode
# - remove code to delete unused vars (use clean restore instead)
# - fixes not applied if ASUS OEM code detected
# - ensure do not enable scripts in migration mode

# Version 22			  27-October-2015
# - version variable name update
# - update Merlin/Fork unique variables
#
# Version 21			  6-August-2015
# - fix bug in setting jffs options moving from <378 to 378.55
# - add syslog entry for exception processing
#
# Version 20			  3-August-2015
# - update Merlin/Fork unique variables
#
# Version 19			  16-June-2015
# - version update only for ini
#
# Version 18			  14-June-2015
# - add more Merlin/Fork unique variables
# - remove code to remove vars on downlevel
#   (use '-clean' option instead)
# - force media dirs on upgrade
#
# Version 17			  29-April-2015
# - version update only for ini
#
# Version 16			  16-April-2015
# update fork specific vars for removal
# update (^378) vars for removal
#
# Version 15a			  6-March-2015
# add check for numeric extendno for ASUS OEM code
#
# Version 15			  25-February-2015
# - remove SNMP vars if not supported
# - update fork specific vars for removal
# - add version string for consistency check
#
# Version 14			  7-February-2015
# - update script name to include codename
# - update fork variables for delete
# - force jffs on for move to 378 code if off
#	if jffs already active, turn on scripts
# - use new vpn_server var for move to 378 code
#
# Version 12                      1-February-2015
# - use previous code in determining actions
#
# Version 11                      29-January-2015
# - Initial release into overall package
# - (378)  single maclist for filtering
# - (^378) delete Merlin specific variables
# - (^374) delete fork specific variables
#
#------------------------------------------------
VERSION=26.1
scr_name=nvram-excp-merlin
logger -s -t $scr_name "NVRAM Exception Processing - Version $VERSION"

# Get current code level
buildno=$(nvram get buildno)
major=$(echo "$buildno" | awk -F"." '{ print $1; }')
minor=$(echo "$buildno" | awk -F"." '{ print $2; }' | awk -F"-" '{ print $1; }')
if [ "$minor" = "" ]; then
  minor=0
fi

# Get previous code level
buildno_org=$(nvram get buildno_org)
major_org=$(echo "$buildno_org" | awk -F"." '{ print $1; }')
minor_org=$(echo "$buildno_org" | awk -F"." '{ print $2; }' | awk -F"-" '{ print $1; }')
if [ "$minor_org" = "" ]; then
  minor_org=0
fi

# Check for numeric extendno (ASUS release)
asusno=$(nvram get extendno)
if ! [ "$asusno" -eq "$asusno" ] 2>/dev/null; then
  asusno=0
fi

# Update nvram based on code level specifics

update_maclist() {
  # Update mac filter lists
  OLDIFS=$IFS
  IFS="<"

  tmpmac=""
  tmpmac_x=""
  for ENTRY in $(nvram get "$1_x"); do
    if [ "$ENTRY" = "" ]; then
      continue
    fi

    mac=$(echo "$ENTRY" | cut -d ">" -f 1)
    tmpmac="$tmpmac $mac"
    tmpmac_x="$tmpmac_x<$mac"
  done
  IFS=$OLDIFS

  nvram set "$1"="$tmpmac"
  nvram set "$1"_x="$tmpmac_x"
}

if [ $asusno -ne 0 ]; then
  # Only process exceptions for Merlin builds
  logger -s -t $scr_name "NVRAM Exception Processing - skipped for ASUS OEM Firmware"
  exit 1
fi # end asusno

if [ "$major" -eq "$major_org" ] && [ "$minor" -eq "$minor_org" ]; then
  # No need for exception processing if no change in firmware level
  logger -s -t $scr_name "NVRAM Exception Processing - skipped for no change in firmware level"
  exit 2
fi

######## start of exceptions ########

# MAC Filter ######## upgrade exceptions ########
if [ "$major" -eq 378 ] && [ "$minor" -le 55 ] && [ "$major_org" -lt 378 ]; then
  # No longer separate maclist filters per radio
  wla_maclist_x=$(nvram get wl0_maclist_x | sed 's/</\n/g' | grep ":" | awk -F">" '{ print $1">"$2; }')
  wla_maclist_x=$wla_maclist_x"\n"$(nvram get wl1_maclist_x | sed 's/</\n/g' | grep ":" | awk -F">" '{ print $1">"$2; }')
  # Xentrk POSIX update
  #wla_maclist_x=$(echo -e "$wla_maclist_x" | sort -u | awk -F">" '{ print $1">"$2; }')
  wla_maclist_x=$(printf '%s' "$wla_maclist_x" | sort -u | awk -F">" '{ print $1">"$2; }')
  # Xentrk POSIX update
  #wla_maclist_x=$(echo -e "$wla_maclist_x" | sed 's/^/</g' | tr -d '\n')
  wla_maclist_x=$(printf '%s' "$wla_maclist_x" | sed 's/^/</g' | tr -d '\n')
  nvram set wl0_maclist_x="$wla_maclist_x"
  nvram set wl1_maclist_x="$wla_maclist_x"
  logger -s -t $scr_name "NVRAM Exception Processing - MAC Filter list has been combined"
fi
if [ "$major" -ge 378 ] && [ "$minor" -gt 55 ] && [ "$major_org" -lt 378 ] || [ "$minor_org" -le 55 ]; then
  # Strip names from maclist for later levels
  update_maclist "wl0_maclist"
  update_maclist "wl1_maclist"
  update_maclist "wl2_maclist"
  update_maclist "wl0.1_maclist"
  update_maclist "wl0.2_maclist"
  update_maclist "wl0.3_maclist"
  update_maclist "wl1.1_maclist"
  update_maclist "wl1.2_maclist"
  update_maclist "wl1.3_maclist"
  logger -s -t $scr_name "NVRAM Exception Processing - MAC Filter list format has been updated"
fi

# jffs control ######## upgrade exceptions ########
if [ "$major" -ge 378 ] && [ "$major_org" -lt 378 ]; then
  # Force jffs on
  if [ "$minor" -lt 55 ]; then
    nvram set jffs2_on="1"
  else
    nvram set jffs_enable="1"
    nvram set jffs2_format="1"
    nvram set jffs2_scripts="0"
    logger -s -t $scr_name "NVRAM Exception Processing - JFFS enabled and set for format at next boot"
  fi
  # jffs already on, enable scripts
  if [ "$1" != "MIGR" ]; then
    nvram set jffs2_scripts="1"
    logger -s -t $scr_name "NVRAM Exception Processing - JFFS script processing enabled"
  fi
fi

if [ "$major" -ge 378 ] && [ "$major_org" -lt 378 ]; then
  # Misc var changes ######## upgrade exceptions ########
  # New vpn server var
  nvram set vpn_serverx_start="$(nvram get vpn_serverx_eas)"

  # New neighbor solication var
  nvram set ipv6_ns_drop=0

  # Force display of media dirs
  nvram set dms_dir_manual=1

  logger -s -t $scr_name "NVRAM Exception Processing - Updated misc variable changes"
fi

# nband bug ######## upgrade exceptions ########
if [ "$major" -ge 376 ]; then
  # Fix bad radio settings
  if [ "$(nvram get wl0_nband)" != "2" ] || [ "$(nvram get wl1_nband)" != "1" ]; then
    nvram set wl0_nband="2"
    nvram set wl1_nband="1"
    logger -s -t $scr_name "NVRAM Exception Processing - Fixed wireless nband bug"
  fi
fi

# ssh enable ######## upgrade exceptions ########
if [ "$major_org" -le 380 ] && [ "$minor_org" -lt 59 ] && [ "$major" -ge 380 ] && [ "$minor" -ge 59 ]; then
  case $(nvram get sshd_wan) in
  "0")
    if [ "$(nvram get sshd_enable)" -eq 0 ]; then
      nvram set sshd_enable="0"
    else
      nvram set sshd_enable="2"
    fi
    ;;
  "1")
    if [ "$(nvram get sshd_enable)" -eq 0 ]; then
      nvram set sshd_enable="0"
    else
      nvram set sshd_enable="1"
    fi
    ;;
  *)
    nvram set sshd_enable="0"
    ;;
  esac
  nvram unset sshd_wan
  logger -s -t $scr_name "NVRAM Exception Processing - SSHD enable converted to new format"
fi

# vpn adns ######## upgrade exceptions ########
if [ "$major_org" -eq 374 ] && [ "$major" -ge 376 ]; then
  # Remove custom fork vpn dns options
  if [ "$(nvram get vpn_client1_adns)" -gt 3 ]; then
    nvram set vpn_client1_adns="3"
  fi
  if [ "$(nvram get vpn_client2_adns)" -gt 3 ]; then
    nvram set vpn_client1_adns="3"
  fi
fi

# MAC Filter ######## downlevel exceptions ########
if [ "$major" -le 378 ] && [ "$minor" -lt 55 ] && [ "$major_org" -ge 378 ] || [ "$minor_org" -ge 55 ]; then
  # Rest maclist since too many changes to fix
  nvram unset wl0_maclist
  nvram unset wl1_maclist
  nvram unset wl2_maclist
  nvram unset wl0.1_maclist
  nvram unset wl0.2_maclist
  nvram unset wl0.3_maclist
  nvram unset wl1.1_maclist
  nvram unset wl1.2_maclist
  nvram unset wl1.3_maclist
  logger -s -t $scr_name "NVRAM Exception Processing - MAC Filter list has been reset, please reconfigure"
fi

# jffs control ######## downlevel exceptions ########
if [ "$major" -ge 378 ] && [ "$major_org" -lt 378 ]; then
  # Force jffs on
  if [ "$(nvram get jffs2_on)" = "0" ]; then
    nvram set jffs2_on="1"
    nvram set jffs2_format="1"
    nvram set jffs2_scripts="1"
    logger -s -t $scr_name "NVRAM Exception Processing - JFFS has been enabled and set to format at next boot"
  else
    # jffs already on, enable scripts
    nvram set jffs2_scripts="1"
    logger -s -t $scr_name "NVRAM Exception Processing - JFFS script processing has been enabled"
  fi
fi

# QOS ######## downlevel exceptions ########
if [ "$major_org" -ge 376 ] && [ "$major" -lt 376 ]; then
  # Set traditional qos and disable
  if [ "$(nvram get qos_type)" = "1" ]; then
    nvram set qos_type="0"
    nvram set qos_enable="0"
    logger -s -t $scr_name "NVRAM Exception Processing - QOS type has been set to Traditional QOS and disabled"
  fi
fi

# ssh enable ######## downlevel exceptions ########
if [ "$major_org" -ge 380 ] && [ "$minor_org" -ge 59 ] && [ "$major" -le 380 ] || [ "$minor" -lt 59 ]; then
  case $(nvram get sshd_enable) in
  "0")
    nvram set sshd_wan="0"
    ;;
  "1")
    nvram set sshd_wan="1"
    ;;
  "2")
    nvram set sshd_enable="1"
    nvram set sshd_wan="0"
    ;;
  *)
    nvram set sshd_enable="0"
    nvram set sshd_wan="0"
    ;;
  esac
  logger -s -t $scr_name "NVRAM Exception Processing - SSHD enable converted to old format"
fi

######## end of exceptions ########

exit 0
