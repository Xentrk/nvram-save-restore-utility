#!/bin/sh

# nvram-hnd-migr.sh
# Save specified nvram user variables stored in /jffs/nvram for HND routers

# Changelog
#------------------------------------------------
# Version 1.0.0			    26-January-2020
# - initial release
#------------------------------------------------
# variable definitions

# shellcheck disable=SC2016 # ignore warning about using single quotes when searcing for \` char

cwd="$(dirname "$(readlink -f "$0")")"
outfile="$cwd/restore-hnd-migr.sh"
tmpfile="$outfile.tmp"
count=0

# initialize the restore script
true >"$tmpfile"
{
  echo "#!/bin/sh"
  echo "# Clean dhcp_hostnames values populated from MIGR restore"
  echo "nvram unset dhcp_hostnames"
  echo "nvram commit"
  echo "[ ! -d \"/jffs/nvram\" ] && mkdir -p \"/jffs/nvram\""
} >>"$tmpfile"

# Process nvram values stored in /jffs/nvram dir for HND routers
for FILE in asus_device_list \
            custom_clientlist \
            dhcp_hostnames \
            dhcp_staticlist \
            keyword_sched \
            lb_skip_port \
            nc_setting_conf \
            qos_orates \
            qos_rulelist \
            sshd_authkeys \
            url_sched \
            vpn_server_ccd_val \
            wl0_maclist_x \
            wl0_rast_static_client \
            wl0_sched \
            wl1_chansps \
            wl1_maclist_x \
            wl1_rast_static_client \
            wl1_sched \
            wl_maclist_x \
            wl_rast_static_client \
            wl_sched; do
  value=$(nvram get "$FILE")
  lval=${#value}
  if [ "$lval" -gt 0 ]; then
    ####value=${value//$/\\$}            # escape $ char
    value=$(echo "$value" | sed 's/\$/\\$/g')                    # escape $ char
    ####value=${value//\"/\\\"}          # escape " char
    value=$(echo "$value" | sed 's/\"/\\"/g')                    # escape " char
    ####value=${value//\`/\\\`}          # escape ` char
    value=$(echo "$value" | sed 's/`/\\`/g')                     # escape ` char
    ####esc=$(expr index "$value" $'\n') # check for lf escape sequence
    esc=$(awk -v a="$value" -v b="\n" 'BEGIN{print index(a,b)}') # check for lf escape sequence
  else
    echo "Skipping $FILE (empty or does not exist)"
    shift
    continue
  fi
  count=$((count + 1))
  echo "Saving $FILE"
  echo "echo \"Restoring $FILE\"" >>"$tmpfile"
  if [ "$esc" -gt 0 ]; then
    ####valuex=${value//$'\r'/}     # remove cr
    valuex=$(echo "$value" | sed -e 's/[\r]//g') # remove cr
    #####valuex=${valuex//$'\n'/\\n} # convert lf to escape sequence
    valuex=$(echo "$valuex" | sed 's/\n/\\n/g') # convert lf to escape sequence
    echo "echo \"\$(echo -e \"$valuex\")\" > /jffs/nvram/$FILE" >>"$tmpfile"
  else
    echo "echo \"$value\"  > /jffs/nvram/$FILE" >>"$tmpfile"
  fi
  shift
done

if [ "$count" -gt 0 ]; then
  if [ -e "$outfile" ]; then
    echo "Backing up previous restore script to $outfile.bak"
    cp -f "$outfile" "$outfile".bak
  fi
  {
    echo "echo \"\""
    echo "echo \"Restore complete - $count NVRAM variable(s)\""
    echo "echo \"Reboot to activate your restored settings\""
  } >>"$tmpfile"
  cp -f "$outfile".tmp "$outfile"
  chmod a+rx "$outfile"
  rm "$outfile".tmp
  echo ""
  echo "Saved $count NVRAM variable(s)"
  echo "Run $outfile to restore your saved settings"
  echo ""
fi
