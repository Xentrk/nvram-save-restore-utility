#!/bin/sh

# save-mynvram.sh
# Save specified nvram user variables for restore

# Changelog
#------------------------------------------------
# Version 1			    16-April-2016     - initial release
# Version 1.0.1     16-February-2020  - update for /jffs/nvram variables
#
#------------------------------------------------
# variable definitions
#version=1.0.1
# shellcheck disable=SC2016 # ignore warning about using single quotes when searcing for \` char

setstring="nvram set"
#cmdopts="$*"
#scr_name=$(basename "$0")
cwd="$(dirname "$(readlink -f "$0")")"
outfile="$cwd/restore-mynvram.sh"
tmpfile="$outfile.tmp"
count=0
zcount=0

# initialize the restore script
echo "#!/bin/sh" >"$tmpfile"

if [ $# -eq 0 ]; then
  echo "Usage:  save-mynvram.sh var1 var2 var3 ..."
  printf '\t%s\n' " where var1 var2 var3 ... are the names of the NVRAM vars to save"
  echo ""
  exit 0
fi

echo ""

while [ $# -gt 0 ]; do
  var=$1

  # Special processing for HND routers that also store some nvram vars in /jffs/nvram
  if [ -f "/jffs/nvram/${var}" ]; then
    nvram_value=$(cat /jffs/nvram/"${var}")
    zcount=$((zcount + 1))
    echo "Saving /jffs/nvram/$var"
    echo "echo \"Restoring /jffs/nvram/$var\"" >>"$tmpfile"
    printf '%s\n' "printf '%s\n' \"$nvram_value\" > /jffs/nvram/${var}" >>"$tmpfile"
  fi

  value=$(nvram get "$var")
  #lval=$(echo ${#value})
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
    echo "Skipping $var (empty or does not exist)"
    shift
    continue
  fi
  count=$((count + 1))
  echo "Saving NVRAM variable $var"
  echo "echo \"Restoring $var\"" >>"$tmpfile"
  if [ "$esc" -gt 0 ]; then
    ####valuex=${value//$'\r'/}     # remove cr
    valuex=$(echo "$value" | sed -e 's/[\r]//g') # remove cr
    #####valuex=${valuex//$'\n'/\\n} # convert lf to escape sequence
    valuex=$(echo "$valuex" | sed 's/\n/\\n/g') # convert lf to escape sequence
    echo "$setstring $var=\"\$(echo -e \"$valuex\")\"" >>"$tmpfile"
  else
    echo "$setstring $var=\"$value\"" >>"$tmpfile"
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
    echo "echo \"/jffs/nvram restore complete - $zcount NVRAM variable(s)\""
    echo "echo \"NVRAM restore complete - $count NVRAM variable(s)\""
    echo "echo \"Enter 'nvram commit' then reboot to activate your restored settings\""
  } >>"$tmpfile"
  cp -f "$outfile".tmp "$outfile"
  chmod a+rx "$outfile"
  rm "$outfile".tmp
  echo ""
  echo "Saved $zcount /jffs/nvram variable(s)"
  echo "Saved $count NVRAM variable(s)"
  echo "Run $outfile to restore your saved settings"
  echo ""
fi

exit 0
