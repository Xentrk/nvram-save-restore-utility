#!/bin/sh
# nvram-save.sh
# Save nvram user variables for restore after factory reset
# shellcheck disable=SC2034 # ignore msg about unused colors
# shellcheck disable=SC2016 # ignore warning about using single quotes when searcing for \` char
##################################################################################
###########################################################################################################################################
# Changelog
#------------------------------------------------
# see nvram-save.sh
# Version 30.3			  27-March-2020
# - Xentrk POSIX Updates
#
# Version 30.1              dd-mmmmmmmmm-20xx
# - Martineau hacks
# Version 26.2				22-September-2017
# - save copy of nvram ini file to be used during restore
#
# Version 26.1			    15-September-2017
# - add support for force save '%' and force save/restore '&' flags
# - add support for separate user variable adds via nvram.ini.add
#
# Version 26.0			    16-Aug-2017
# - change version numbering
# - updates for migration and clean restore
#
# Version 25a			    9-Aug-2017
# - change force include flag to '+' to work around busybox bug
# - check only numeric portion of version for mismatch
#
# Version 25			    8-Aug-2017
# - support doing a migration restore from a full save file
#
# Version 24			    2-May-2016
# - add hhmm to file timestamp naming
#
# Version 23			    3-April-2016
# - pass macid to exception processing
#
# Version 22			    27-October-2015
# - show version numbers with -v
# - print ini version to syslog
# - add ini version to runlog
# - only set file permissions on non-FAT format drives
#
# Version 21			    6-August-2015
# - fix call to exception processing if not running from current directory
#
# Version 20			    3-August-2015
# - enable running script from other than current directory
# - strip CR from custom strings during save
#
# Version 19			    16-June-2015
# - version update only for ini
#
# Version 18			    14-June-2015
# - add -clean option (for nvram-restore) to only
#   only restore nvram variables which exist
#   (useful if backleveling fw to clean
#   nvram variables added for new function)
# - force clean mode when generating migration script
# - add codelevel to runlog
# - remove sort for nvram-all saved text file
#
# Version 17			    29-April-2015
# - version update only for ini
#
# Version 16			    16-April-2015
# - add -nouser option to not execute user script
# - implement runlog to aid in restore operations
# - add consistency check for nvram-restore.sh
#
# Version 15			    25-February-2015
# - add help option -h
# - add print version option -v (also perform consistency chk)
# - add option to specify custom ini -i inifile
# - add -clk option to include clkfreq var
# - add -nojffs option to NOT backup jffs
# - consistency check for script/ini versions during runtime
# - save txt files of all and usr nvram variables
#
# Version 14			    7-February-2015
# - add version info to save/restore scripts
# - escape back-quote and double-quote characters
# - change handling of embedded lf chars
# - add short delay after commit before exiting script
# - changed name of inifile to indicate code family supported
# - log results of save and restore scripts to syslog
#
# Version 12			    1-February-2015
# - add nvram var for previous code level
# - add call to user exit nvram-user.sh
#
# Version 11                        29-January-2015
# - add exit for code specific updates
#
# Version 10                        18-January-2015
# - backup /jffs if it exists
#
# Version 9              	    24-December-2014
# - nvram.ini update only
#
# Version 8                         17-December-2014
# - nvram.ini update only
#
# Version 7                         12-December-2014
# - nvram.ini update only
#
# Version 6			    3-December-2014
# - handle '$' special character
#
# Version 5                         20-November-2014
# - nvram.ini update only
#
# Version 4                         03-November-2014
# - Added Backup/Migration modes (switch -M)
#
# Version 3a                        28-October-2014
# - Fix getting mac address for AC87U
#
# Version 2                         14-October-2014
# - Add last two mac address bytes
#       to output restore file name (allows saving
#       restore files from multiple routers to one
#       USB stick)
#
# Version 1                         11-Sepember-2014
# - Initial release
#
#------------------------------------------------
VERSION=30.3.0
version=30.3.0
##########Martineau Hack ######################################
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
# variable definitions
############################################################################################Martineau Hack ######################################
#version=30.1    # see nvram-restore.sh
#													nvram-save.sh: WARNING: nvram-merlin.ini is mismatched version
#													nvram-save.sh: WARNING: nvram-excp-merlin.sh is mismatched version
#													nvram-save.sh: WARNING: jffs-restore.sh is mismatched version
####################################################################################################################################
codename=merlin # Configured for asuswrt-merlin, asus-oem
buildno=$(nvram get buildno)
extendno=$(nvram get extendno)
#lval=$(echo ${#extendno})
lval=${#extendno}
if [ "$lval" -gt 0 ]; then
  codelevel="$buildno"_"$extendno"
else
  codelevel=$buildno
fi

# filename definitions
#cwd=$(pwd)
cwd=$(dirname "$(readlink -f "$0")")
if [ -d "$cwd/backup" ]; then
  dwd=$cwd/backup
else
  dwd=$cwd
fi
mntpnt=$(echo "$cwd" | awk -F'/' '{ print "/"$2"/"$3"/"$4 }')
isfat=0
isfat=0
mount | grep "$mntpnt" | grep -q "fat" && isfat=1
restorescript="nvram-restore"
nvramall="nvram-all"
nvramusr="nvram-usr"
nvramini="nvram-ini"
dash="-"
space4="    "
inifile="nvram-$codename.ini"
excfile="nvram-excp-$codename.sh"
jffsfile="jffs-restore.sh"
restfile="nvram-restore.sh"
rundate="$(date +%Y%m%d%H%M)"
migrate="0"
jffsbackup="1"
userscript="1"
clean="1"
setstring="nvram set"
skipvar="#### clkfreq"
initype="standard"
cmdopts="$*"
scr_name="$(basename "$0")"
runlog="$cwd/nvram-util.log"
############################################################################################Martineau Hack ######################################
# Xentrk: change from computer_name (e.g. RT-AC88U-8248 to model (e.g. RT-AC88U) to drop unnecessary last four digits.
#         Related change was made as my macid parm was all 0000's becuase it was missing nvram parm et2macaddr
#MYROUTER="$(nvram get computer_name)"
MYROUTER="$(nvram get model)"

ANSIColours
#set -x
START_TIME=$(date +%s)
UNDERSCORE="_"
TOTALBYTES="0"
###########################################################################################################################################

while [ $# -gt 0 ]; do
  input=$1
  case "$input" in
  "-H" | "-h")
    echo "NVRAM User Save/Restore Utility"
    echo "nvram-save.sh Version $VERSION"
    echo " Options: -h           this help msg"
    echo "          -v           Print version/perform consistency check"
    echo "          -b           Backup mode - save for restore to same router (default)"
    echo "          -m           Migration mode - transfer settings to another router"
    echo "          -i inifile   Specify custom nvram variable ini file"
    echo "          -clk         Include clkfreq/overclock setting (Backup mode only)"
    echo "          -nojffs      Skip backup of jffs storage"
    echo "          -nouser      Skip execution of user exit script"
    #		echo "          -noclean     Create old style restore script to restore all variables only"
    echo ""
    exit 0
    ;;
  "-M" | "-m")
    migrate=1
    ;;
  "-I" | "-i")
    inifile=$2
    initype="custom"
    shift
    ;;
  "-B" | "-b")
    migrate=0
    ;;
  "-V" | "-v")
    echo "NVRAM User Save/Restore Utility"
    echo "Working Directory $cwd"
    echo ""
    echo "$scr_name Version=$version" | awk '{ printf "%-30s %-20s\n", $1, $2}'
    echo "$inifile $(grep -m 1 "Version=" "$cwd"/"$inifile" | sed 's/#//')" | awk '{ printf "%-30s %-13s", $1, $2}' &&
      grep -q "Version=${version%\.*}" "$cwd/$inifile" && echo "" || echo "<<< WARNING: mismatched version"
    echo "$excfile $(grep -m 1 "Version=" "$cwd"/$excfile | sed 's/#//')" | awk '{ printf "%-30s %-13s", $1, $2}' &&
      grep -q "Version=${version%\.*}" "$cwd/$excfile" && echo "" || echo "<<< WARNING: mismatched version"
    echo "$restfile $(grep -m 1 "Version=" "$cwd"/$restfile | sed 's/#//')" | awk '{ printf "%-30s %-13s", $1, $2}' &&
      grep -q "Version=${version%\.*}" "$cwd/$restfile" && echo "" || echo "<<< WARNING: mismatched version"
    echo "$jffsfile $(grep -m 1 "Version=" "$cwd"/$jffsfile | sed 's/#//')" | awk '{ printf "%-30s %-13s", $1, $2}' &&
      grep -q "Version=${version%\.*}" "$cwd/$jffsfile" && echo "" || echo "<<< WARNING: mismatched version"
    echo ""
    exit 0
    ;;
  "-nojffs" | "-NOJFFS")
    jffsbackup=0
    ;;
  "-nouser" | "-NOUSER")
    userscript=0
    ;;
  "-clk" | "-CLK")
    #    skipvar=${skipvar//clkfreq/} # for include -clk option
    #   Special case for this since we are matching the end:
    skipvar=${skipvar%clkfreq*}
    ;;
  "-noclean" | "-NOCLEAN")
    clean=0
    ;;
  *)
    echo "Unknown option $1"
    echo "Program exit"
    echo ""
    exit 1
    ;;
  esac
  shift
done

# start of script
echo ""
############################################################################################Martineau Hack ######################################
#### Xentrk
#echo -e "$cBYEL"
printf '%b' "$cBYEL"
logger -s -t "$scr_name" "NVRAM User Save Utility - Version 30.3 POSIX Code Updates"
logger -s -t "$scr_name" "NVRAM User Save Utility - Version 30.1 Martineau Hacked for v384.xx+!!"
logger -s -t "$scr_name" "Saving $MYROUTER settings from firmware $codelevel"

FIRMWARE=$(nvram get buildno | awk 'BEGIN { FS = "." } {printf("%03d%02d",$1,$2)}')
[ "$FIRMWARE" -gt 38200 ] && V384XX=1 # Do not allow legacy options

###########################################################################################################################################
if [ "${#cmdopts}" -gt 0 ]; then
  logger -s -t "$scr_name" "Runtime options: $cmdopts"
fi

# check for ini file
if [ "$inifile" = "${inifile##*/}" ]; then
  infile=$cwd/$inifile
else
  infile=$inifile
fi
if [ ! -f "$infile" ]; then
  ############################################################################################Martineau Hack ######################################
  # Xentrk
  # echo -e "\a\n""$cBRED"  ## end chg
  printf '%b\n' "$cBRED"
  ###########################################################################################################################################
  logger -s -t "$scr_name" "NVRAM variable file not found: $inifile"
  echo "Program exit"
  ############################################################################################Martineau Hack ######################################
  #echo ""
  # Xentrk
  #echo -e "$cRESET"
  printf '%b' "$cRESET"
  ###########################################################################################################################################
  exit 2
else
  logger -s -t "$scr_name" "Using $initype NVRAM variable file: $inifile $(grep "Version=" "$infile" | sed 's/#//')"
  cp -af "$infile" /tmp/nvram.ini
  infile=/tmp/nvram.ini
  if [ -f "$cwd/nvram.ini.add" ]; then
    cat "$cwd/nvram.ini.add" >>$infile
  fi
fi

# set mode vars
#if [ $migrate -eq 0 ]; then
#  macid=$(nvram get "et0macaddr")
#  if [ "$macid" = "" ]; then
#    macid=$(nvram get "et1macaddr")
#  fi
#  macid=$(echo "$macid" | cut -d':' -f 5,6 | tr -d ':' | tr 'a-z' 'A-Z')
#  logger -s -t "$scr_name" "Running in Backup Mode"
#else
#  macid="MIGR"
#  logger -s -t "$scr_name" "Running in Migration Mode"
#fi

# Xentrk: my macid parm was all 0000's! Add check for et2macaddr ##############
if [ $migrate -eq 0 ]; then
  macid=$(nvram get "et0macaddr")
  if [ "$macid" = "" ] || [ "$macid" = "00:00:00:00:00:00" ]; then
    macid=$(nvram get "et1macaddr")
    if [ "$macid" = "" ] || [ "$macid" = "00:00:00:00:00:00" ]; then
      # Xentrk noticed MACID is all 0"
      macid=$(nvram get "et2macaddr")
    fi
  fi
  #macid=$(echo "$macid" | cut -d':' -f 5,6 | tr -d ':' | tr 'a-z' 'A-Z')
  macid=$(echo "$macid" | cut -d':' -f 5,6 | tr -d ':' | tr '[:lower:]' '[:upper:]')
  logger -s -t "$scr_name" "Running in Backup Mode"
else
  macid="MIGR"
  logger -s -t "$scr_name" "Running in Migration Mode"
fi

if [ "$initype" = "standard" ]; then
  grep -q "Version=${version%.*}" "$infile" || logger -s -t "$scr_name" "WARNING: $inifile is mismatched version"
fi
grep -q "Version=${version%\.*}" "$cwd/$excfile" || logger -s -t "$scr_name" "WARNING: $excfile is mismatched version"
grep -q "Version=${version%\.*}" "$cwd/$restfile" || logger -s -t "$scr_name" "WARNING: $restfile is mismatched version"
grep -q "Version=${version%\.*}" "$cwd/$jffsfile" || logger -s -t "$scr_name" "WARNING: $jffsfile is mismatched version"

# versioned file definitions
#if [ $clean = 1 ]; then
#	restorescript="nvram-clean-restore"
#fi
############################################################################################Martineau Hack ######################################
#outfile="$dwd/$restorescript$dash$rundate$dash$macid.sh"
#nvramallfile="$dwd/$nvramall$dash$rundate$dash$macid.txt"
#nvramusrfile="$dwd/$nvramusr$dash$rundate$dash$macid.txt"
outfile="$dwd/$restorescript$dash$rundate$UNDERSCORE$MYROUTER$dash$macid.sh"
nvramallfile="$dwd/$nvramall$dash$rundate$UNDERSCORE$MYROUTER$dash$macid.txt"
nvramusrfile="$dwd/$nvramusr$dash$rundate$UNDERSCORE$MYROUTER$dash$macid.txt"

#saveinfile="$dwd/$nvramini$dash$rundate$dash$macid.txt"
saveinfile="$dwd/$nvramini$dash$rundate$UNDERSCORE$MYROUTER$dash$macid.txt"
cp -af $infile "$saveinfile"
#echo -e "$cBBLU"
printf '%b' "$cBBLU"
##########################################################################################################################################

# generate the restore script based on ini file
true >"$outfile"
{
  echo "#!/bin/sh"
  echo
  echo "# generated script to restore user nvram settings"
  echo "#VERSION=$VERSION"
  echo "scr_name=\"nvram-restore\""
  echo "if [ ! -f $saveinfile ]; then"
  echo "  cp -af $cwd/$inifile $saveinfile"
  echo "fi"
  echo
  ############################################################################################Martineau Hack ######################################
  #echo "echo \"\"" >>$outfile
  #echo "echo -e \"$cBYEL\""
  echo "printf '%b' \"$cBYEL\""
  ###########################################################################################################################################
  echo "logger -s -t \"\$scr_name\" \"NVRAM User Restore Utility - Version $VERSION POSIX code updates.\""
  echo "logger -s -t \"\$scr_name\" \"NVRAM User Restore Utility - Version $version Martineau Hacked for v384.xx+!!\""
  echo "logger -s -t \"\$scr_name\" \"Using $initype NVRAM variable file: $inifile $(grep "Version=" $infile | sed 's/#//')\""
} >>"$outfile"
############################################################################################Martineau Hack ######################################
#echo "logger -s -t \"\$scr_name\" \"Restoring settings from firmware $codelevel $rundate$dash$macid\"" >>$outfile
if [ "$initype" != "custom" ]; then
  echo "logger -s -t \"\$scr_name\" \"Restoring $MYROUTER settings from firmware $codelevel $rundate$UNDERSCORE$MYROUTER$dash$macid\"" >>"$outfile"
else
  echo "logger -s -t \"\$scr_name\" \"Restoring custom $MYROUTER (\$(nvram get buildno)) settings from firmware $codelevel $rundate$UNDERSCORE$MYROUTER$dash${inifile%\.*}$dash$macid.sh\"" >>"$outfile"
fi
##########################################################################################################################################

echo "codelevel=$codelevel" >>"$outfile"

if [ "$macid" != "MIGR" ]; then # skip check for migratino mode
  {
    # Xentrk: Not sure what the purpose of the grep is? Value is not assigned to a parm
    #echo "\$(grep \"#Version=\" \"$saveinfile\")"

    ############################################################################################Martineau Hack #####################################

    #echo "if [ -z \"\$(echo \$(basename \"\$0\") | grep \"\$(nvram get computer_name)\")\" ]; then"
    echo "if [ -z \"\$(echo \"\$(basename \"\$0\")\" | grep \"\$(nvram get model)\")\" ]; then"
    #echo "echo -e \"$cBRED$aBLINK\""
    echo "printf '%b' \"$cBRED$aBLINK\""
    #echo "echo -e \"\n\a\tRestore Router Model MISMATCH - ABORTing\""
    printf '%s\n' "printf '\n\a\t%s' \"Restore Router Model MISMATCH - ABORTing\""
    #echo "echo -e \"$cRESET\""
    echo "printf '%b' \"$cRESET\""
    echo "exit 98"
    echo "fi"
  } >>"$outfile"
fi
exit 0

if [ "$V384XX" != "1" ]; then
  {
    echo "if [ \"\$(echo \$codelevel | cut -d'.' -f1 )\" -gt 380 ]; then"
    #echo "echo -e \"$cBRED$aBLINK\""
    printf '%s\n' "printf '%b' \"$cBRED$aBLINK\""
    #echo "echo -e \"\n\a\tNVRAM Restore NOT SAFE for Firmwares later than v380.xx - ABORTing\""
    printf '%s\n' "printf '\n\a\t%s' \"NVRAM Restore NOT SAFE for Firmwares later than v380.xx - ABORTing\""
    #echo "echo -e \"$cRESET\""
    echo "printf '%b' \"$cRESET\""
    echo "exit 99"
    echo "fi"
    echo
  } >>"$outfile"

  if [ $clean = 1 ]; then
    {
      echo "tmpfile=/tmp/nvram-clean.lst"
      echo "# Migrate restore from full restore supported"
      echo "# Clean restore supported"
    } >>"$outfile"
    if [ $migrate = 1 ]; then
      echo "op=\"-clean\"" >>"$outfile"
    else
      echo "op=\$1" >>"$outfile"
    fi
    {
      echo "if [ \"\$op\" = \"-clean\" ] || [ \"\$op\" = \"-migr\" ]; then"
      echo "nvram show 2>/dev/null | sort | awk -F\"=\" '{print \$1}' >\"\$tmpfile\""
      echo "if [ \"\$op\" = \"-clean\" ] || [ \"\$op\" = \"-migr\" ]; then"
      echo "logger -s -t \"\$scr_name\" \"Clean NVRAM option specified\""
      echo "fi"
      echo "if [ \"\$op\" = \"-migr\" ] && [ -e $saveinfile ]; then"
      echo "logger -s -t \"\$scr_name\" \"Migration option specified\""
      echo "while read line; do" ### remove migrate excludes from reference

      # Xentrk test POSIX Changes
      #echo "linetype=\${line:0:1}"
      echo "linetype=\$(echo \"\$line\" | awk  \'{ string=substr(\$0, 1, 1); print string; }\' )"

      echo "if [ \"\$linetype\" = \"@\" ]; then"
      #echo "lvar=\$(echo \${#line})"
      echo "lvar=\${#line}"
      #echo "let vlength=lvar-1"
      echo "vlength=lvar-1"

      # Xentrk test POSIX Changes
      #echo "var=\${line:1:\$vlength}"
      echo "var=\$(echo \"\$line\" | awk -v seqnumb=\"\$vlength\" \'{ string=substr(\$0, 1, seqnumb); print string; }\' )"

      echo "sed -i \"/\$var/d\" \"\$tmpfile\""
      echo "fi"
      echo "done <$saveinfile"
      echo "fi"
      echo "while read line; do" ### keep vars needed for exclusion processing

      # Xentrk test POSIX Changes
      # echo "linetype=\${line:0:1}"
      echo "linetype=\$(echo \"\$line\" | awk  '{ string=substr(\$0, 1, 1); print string; }' )"

      echo "if [ \"\$linetype\" = \"+\" ] || [ \"\$linetype\" = \"&\" ]; then"
      #echo "lvar=\$(echo \${#line})"
      echo "lvar=\${#line}"
      #echo "let vlength=lvar-1"
      echo "vlength=lvar-1"

      # Xentrk test POSIX Changes
      # echo "var=\${line:1:\$vlength}"
      echo "var=\$(echo \"\$line\" | awk -v seqnumb=\"\$vlength\" \'{ string=substr(\$0, 1, seqnumb); print string; }\' )"

      echo "echo \"\$var\" >>\"\$tmpfile\""
      echo "fi"
      echo "done <$saveinfile"
      echo "op=false"
      echo "else"
      echo "echo \"NvRaM NoClEaN\" >\"\$tmpfile\""
      echo "op=true"
      echo "fi"
    } >>"$outfile"
  fi
###########################################################################Martineau Hack ###########################################
else
  {
    #echo "echo -e \"$cBRED\""
    echo "printf '%b' \"$cBRED\""
    #echo "echo -e \"\n\a\tNVRAM FULL Restore possibly NOT SAFE for Firmwares later than v380.xx - hope you know what you are doing!!\""
    printf '%s\n' "printf '\n\a\t%s\n' \"NVRAM FULL Restore possibly NOT SAFE for Firmwares later than v380.xx - hope you know what you are doing!!\""
    #echo "echo -e \"$cBWHT\n\n\""
    printf '%s\n' "printf '%b\n\n' \"$cBWHT\""
    printf '%s\n' "printf '%s' \"Do you want to proceed [Y/N]?\""
    echo "read -r \"input\""
    echo "while true; do"
    echo "  case \"\$input\" in"
    echo "    \"Y\"|\"y\")"
    echo "		  break"
    echo "		  ;;"
    echo "		*)"
    #echo "	    echo -e \"$cBYEL\a\t\n\tRestore aborted\n\""
    printf '%s\n' "      printf '%b\n\a\t%s\n' \"$cBYEL\" \"Restore aborted\""
    echo "	    exit 2"
    echo "			;;"
    echo "  esac"
    echo "done"
    #echo "echo -e \"$cRESET\""
    echo "printf '%b' \"$cRESET\""
  } >>"$outfile"

fi
##############################################################################################################################
{
  echo "echo \"\""
  echo
  echo "nvram set buildno_org=$(nvram get buildno)"
} >>"$outfile"
# backup all nvram vars to text file
############################################################################################Martineau Hack ######################################
#echo "All NVRAM Settings $rundate $macid" >$nvramallfile
true >"$nvramallfile"
{
  echo "All NVRAM Settings $rundate $MYROUTER-$macid $codelevel"
  ###########################################################################################################################################
  echo "WARNING: Some values in this file contain system parameters which should not be user modified"
  echo ""
  nvram show 2>/dev/null
} >>"$nvramallfile"

if [ "$isfat" -eq 0 ]; then
  chmod a-x "$nvramallfile"
fi

#initialize nvram-usr text file
############################################################################################Martineau Hack ######################################
# Xentrk
#echo -e "$cBMAG"
printf '%b' "$cBMAG"
#echo "NVRAM Saved User Settings $rundate $macid" >$nvramusrfile
echo "NVRAM Saved User Settings $rundate $MYROUTER-$macid $codelevel" >"$nvramusrfile"
#echo "echo -e \"$cBBLU\"" >>"$outfile"
echo "printf '%b' \"$cBBLU\"" >>"$outfile"

NVRAM_CNT=0
NVRAM_BYTES=0
###########################################################################################################################################
echo "" >>"$nvramusrfile"

#set -x
echo ""
processvar=1
while read -r var; do
  ###################################################################################Martineau Hack###################
  #lvar=$(echo ${#var})
  lvar=${#var}
  ##############################################################################################################
  forcevar=0
  #echo "DEBUG**" $var
  #[ "$var" == "[Email settings]" ] && set -x
  # Skip blank lines
  if [ "$lvar" -eq 0 ]; then
    continue
  fi

  # Xentrk Testing POSIX Change
  #  linetype=${var:0:1}
  linetype=$(echo "$var" | awk '{ string=substr($0, 1, 1); print string; }')

  # Xentrk Testing POSIX Change
  #  sectionexcl=${var:0:2}
  sectionexcl=$(echo "$var" | awk '{ string=substr($0, 1, 2); print string; }')

  # skip excluded section
  if [ "$sectionexcl" = "#[" ]; then
    processvar=0
    ###################################################################################Martineau Hack###################
    TOTALBYTES=$((TOTALBYTES + NVRAM_BYTES))
    #echo "LOC00"
    #ZZ=", Bytes=$NVRAM_BYTES \tTotal=$(printf "%-5d" $TOTALBYTES)"
    #echo "$ZZ"
    ZZ=$(printf '%s%d\t%s%-5d' ", Bytes=" "$NVRAM_BYTES" "Total=" "$TOTALBYTES")
    [ "$NVRAM_CNT" = "?" ] && {
      RESULT_COLOR="$cBGRA"
      ZZ=
    } || RESULT_COLOR="$cBGRE"
    #    echo -en "$RESULT_COLOR""$(printf "%2d" $((DIFFTIME % 60))) XXXXX ($(printf "%-3s" $NVRAM_CNT) variables$ZZ)\n${cBGRA} $(printf "%-40s" "      ${var}")"
    #echo "LOC01"
    printf '%b%2d%s%-3s%s\n%b\t%-34s' "$RESULT_COLOR" "$((DIFFTIME % 60))" " secs (" "$NVRAM_CNT" " variables$ZZ)" "$cBGRA" "$var"
    TIME_START=$(date +%s)
    TIME_END=$TIME_START
    NVRAM_CNT="?"   # Reset count of NVRAM variables in this category
    NVRAM_BYTES="0" # Reset total size of NVRAM variables in this catergory
    ##############################################################################################################
    continue
  fi

  ###################################################################################Martineau Hack###################
  #if [ "$linetype" = "#" ]; then
  case $linetype in
  # skip comments
  "#")
    continue
    #fi
    ;;
    #if [ "$linetype" = "[" ]; then
    # output category header
  "[")
    ###################################################################################Martineau Hack###################
    #echo "Saving "$var
    if [ -z "$TIME_START" ]; then
      TIME_START=$(date +%s)
      TIME_END=$TIME_START # Time how long it takes to process this NVRAM Category
    else
      TIME_END=$(date +%s) # End time of previous Category
    fi
    DIFFTIME=$((TIME_END - TIME_START)) # Actual duration taken to process previous Category
    if [ "$var" != "[System - Basic]" ]; then
      TOTALBYTES=$((TOTALBYTES + NVRAM_BYTES))
      if [ "$NVRAM_CNT" != "?" ]; then
        # Xentrk Chg from echo to printf
        #echo -en "$cBGRE""$(printf "%2d" $((DIFFTIME % 60))) Xecs ($(printf "%-3s" "$NVRAM_CNT") variables, Bytes=$NVRAM_BYTES \tTotal=$(printf "%-5d" $TOTALBYTES))\n${cBMAG} $(printf "%-40s" "Saving ${var}")"
        #echo "LOC03"
        printf '%b%2d%s%-3s%18s%d\t%s%-5d%s\n%b%-42s' "$cBGRE" "$((DIFFTIME % 60))" " secs (" "$NVRAM_CNT" "variables, Bytes=" "$NVRAM_BYTES" "Total=" "$TOTALBYTES" ")" "$cBMAG" " Saving $var"
      else
        # Xentrk Chg from echo to printf
        #echo -en "$cBGRA" "$(printf "%2d" $((DIFFTIME% 60))) Yecs ($(printf "%-3s" "$NVRAM_CNT") variables)\n${cBMAG} $(printf "%-40s" "Saving ${var}")"
        #echo "LOC04"
        #printf '%b%-2d%s%-3s%s\n%b%-42s' "$cBGRA" "$((DIFFTIME % 60))" " HHHH (" "$NVRAM_CNT" "variables)" "$cBMAG" " Yaving $var"
        printf '%b%2d%s%-3s%s\n%b%-42s' "$cBGRA" "$((DIFFTIME % 60))" " secs (" "$NVRAM_CNT" " variables)" "$cBMAG" " Saving $var"
      fi
    else
      #echo -en " $(printf "%-40s" "Saving ${var}")"
      #echo "LOC05"
      printf '%-42s' " Saving $var"
    fi
    TIME_START=$(date +%s)
    TIME_END=$TIME_START
    NVRAM_CNT=0   # Reset count of NVRAM variables in this category
    NVRAM_BYTES=0 # Reset total size of NVRAM variables in this catergory
    ##############################################################################################################
    echo "" >>"$outfile"
    ###################################################################################Martineau Hack###################
    # Xetrk testing POSIX Change
    #[ "${var:0:6}" != "[Unset" ] && echo "echo \"Restoring $var\"" >>"$outfile" || echo "echo \"Processing $var\"" >>"$outfile"
    [ "$(echo "$var" | awk '{ string=substr($0, 1, 6); print string; }')" != "[Unset" ] && echo "echo \"Restoring $var\"" >>"$outfile" || echo "echo \"Processing $var\"" >>"$outfile"
    ##############################################################################################################
    echo "" >>"$nvramusrfile"
    echo "$var" >>"$nvramusrfile"

    processvar=1
    continue
    #fi
    ;;
    # skip vars in migrate mode
    #if [ "$linetype" = "@" ]; then
  "@")
    if [ $migrate = 1 ]; then
      # echo "Skipping "$var
      continue
    else
      vlength=$((lvar - 1))
      # Xentrk test POSIX changes
      #var=${var:1:$vlength}
      var=$(echo "$var" | awk -v seqnumb="$vlength" '{ string=substr($0, 1, seqnumb); print string; }')
    fi
    #fi
    ;;
    ###################################################################################Martineau Hack###################
  ">") # Unset NVRAM
    vlength=$((lvar - 1))
    # Xentrk test POSIX Changes
    # var=${var:1:$vlength}
    var=$(echo "$var" | awk -v seqnumb="$vlength" '{ string=substr($0, 1, seqnumb); print string; }')
    # Xentrk POSIX update SC2143
    # if [ -n "$(nvram show 2>/dev/null | grep "$var")" ]; then # Only allow the unset if it actually exists...
    if nvram show 2>/dev/null | grep -q "$var"; then # Only allow the unset if it actually exists...
      echo "echo \"Unset $var\"" >>"$outfile"
      #echo -e "nvram unset" "$var" >>"$outfile"
      printf '%s\n' "nvram unset $var" >>"$outfile"
      continue
    else
      #echo -e "#nvram unset" "$var" "ignored" >>"$outfile" # Hmm should issue the unset during the restore regardless?
      printf '%s\n' "#nvram unset $var ignored" >>"$outfile" # Hmm should issue the unset during the restore regardless?
      continue
    fi
    ;;
  "?") # HND NVRAM
    #Xentrk test POSIX changes
    #var=${var:1}
    var=${var#?}
    #echo -e "[ \"\$(uname -m)\" = \"aarch64\" ] && logger -st \$(basename \"\$0\")" \"Warning: \'"$var""' is now in /jffs/nvram\" " >>"$outfile"
    printf '%s\n' "[ \"\$(uname -m)\" = \"aarch64\" ] && logger -st \"\$(basename \"\$0\")\" \"Warning: '$var' is now in /jffs/nvram\" " >>"$outfile"

    ;;
  ##############################################################################################################
  *)
    # process special var flags
    if [ "$linetype" = "%" ] || [ "$linetype" = "+" ] || [ "$linetype" = "&" ]; then
      ###################################################################################Martineau Hack###################
      #let vlength=lvar-1
      vlength=$((lvar - 1))
      ##############################################################################################################
      # Xentrk test POSIX changes
      #var=${var:1:$vlength}
      var=$(echo "$var" | awk -v seqnumb="$vlength" '{ string=substr($0, 2, seqnumb); print string; }')
      if [ "$linetype" = "%" ] || [ "$linetype" = "&" ]; then
        forcevar=1
      fi
    fi
    ;;
  esac
  ##############################################################################################################

  # get and write nvram values
  if [ $processvar = 1 ] && [ "$skipvar" = "${skipvar%$var*}" ]; then
    value=$(nvram get "$var")
    ###################################################################################Martineau Hack###################
    #lval=$(echo ${#value})
    lval=${#value}

    NVRAM_CNT=$((NVRAM_CNT + 1))
    NVRAM_BYTES=$((NVRAM_BYTES + lval))
    ##############################################################################################################
    ###################################################################################Martineau Hack###################
    #if [[ $lval -gt 0 ]] || [[ $forcevar = 1 ]]; then
    if [ "$lval" -gt 0 ] || [ $forcevar = 1 ]; then
      ##############################################################################################################
      #value=${value//$/\\$}

      # Xentrk POSIX Chg
      #[ -n "$(echo "$value" | grep -oF "$")" ] && value=${value//$/\\$}   # escape $ char
      #[ -n "$(echo "$value" | grep -oF "$")" ] && value=$(echo "$value" | sed 's/\$/\\$/g') # escape $ char
      echo "$value" | grep -qoF "$" && value=$(echo "$value" | sed 's/\$/\\$/g') # escape $ char

      #value=${value//\"/\\\"}		# escape " char
      #[ -n "$(echo "$value" | grep -oF '"')" ] && value=${value//\"/\\\"} # escape " char
      #[ -n "$(echo "$value" | grep -oF '"')" ] && value=$(echo "$value" | sed 's/\"/\\"/g') # escape " char
      echo "$value" | grep -qoF '"' && value=$(echo "$value" | sed 's/\"/\\"/g') # escape " char

      #value=${value//\`/\\\`} 	# escape ` char
      #[ -n "$(echo "$value" | grep -oF '`')" ] && value=${value//\`/\\\`} # escape ` char
      #[ -n "$(echo "$value" | grep -oF '`')" ] && value=$(echo "$value" | sed 's/\`/\\`/g') # escape ` char
      echo "$value" | grep -qoF "\`" && value=$(echo "$value" | sed 's/`/\\`/g') # escape ` char

      # Xentrk test POSIX change
      #esc=$(expr index "$value" $'\n')                                    # check for lf escape sequence
      esc=$(awk -v a="$value" -v b="\n" 'BEGIN{print index(a,b)}')

      if [ $clean = 1 ]; then
        grepstring="(\$op || grep -q \"$var\" \"\$tmpfile\") &&"
        #skipstring="|| echo -e \"\tSkipping $var\""
        skipstring="|| printf '%s\n' \"Skipping $var\""

      else
        grepstring=""
        skipstring=""
      fi
      if [ "$esc" -gt 0 ]; then
        # Xentrk POSIX update
        #valuex=${value//$'\r'/}     # remove cr
        #valuex=$(echo "$value" | sed 's/\r$//')  # remove cr
        valuex=$(echo "$value" | sed -e 's/[\r]//g') # remove cr
        #valuex=${valuex//$'\n'/\\n} # convert lf to escape sequence
        valuex=$(echo "$valuex" | sed 's/\n/\\n/g') # convert lf to escape sequence

        #echo "$grepstring \$($setstring $var=\"\$(echo -e \"$valuex\")\") $skipstring" >>"$outfile"
        printf "$grepstring \$($setstring $var=\"\$(printf '%s\n' \"$valuex\")\") $skipstring" >>"$outfile"
        echo "$var=\"$value\"" >>"$nvramusrfile"
      else
        echo "$grepstring \$($setstring $var=\"$value\") $skipstring" >>"$outfile"
        echo "$var=\"$value\"" >>"$nvramusrfile"
      fi
    fi
  else
    continue
  fi
done <$infile
############################################################################################Martineau Hack ######################################
TOTALBYTES=$((TOTALBYTES + NVRAM_BYTES))
#echo -en "$cBGRE" "$(printf "%2d" $((DIFFTIME % 60))) secs ($(printf "%-3s" $NVRAM_CNT) variables, Bytes=$NVRAM_BYTES \tTotal=$(printf "%-5d" $TOTALBYTES))\n"
#LINE788

printf '%b%2d%s%-3s%18s%d\t%s%-5d%s\n' "$cBGRE" "$((DIFFTIME % 60))" " secs (" "$NVRAM_CNT" "WARiables, Bytes=" "$NVRAM_BYTES" "Total=" "$TOTALBYTES" ")"
###########################################################################################################################################
echo "" >>"$outfile"
echo "echo \"\"" >>"$outfile"
if [ "$isfat" -eq 0 ]; then
  chmod a-x "$nvramusrfile"
fi
################################################################################################Martineau Hack ##############################
if [ "$V384XX" != "1" ]; then
  #######################################################################################################################################
  # Process code specific changes
  if [ -f "$cwd/$excfile" ]; then
    ########################################################################################Martineau hack######################################
    {
      #echo "echo -en \"$cBYEL\""
      printf '%s\n' "printf '%b\n' \"$cBYEL\""
      ######################################################################################################################################
      echo "logger -s -t \"\$scr_name\" \"Applying code level exceptions $cwd/$excfile\""
      echo "sh $cwd/$excfile $macid"
      ########################################################################################Martineau hack######################################
      #echo "echo \"\"" >>$outfile
      #echo "echo -e \"\\n$cRESET\"" >>$outfile
      printf '%s\n' "printf '%b\n' \"$cRESET\""
      ######################################################################################################################################
      echo ""
    } >>"$outfile"
  fi

  # commit changes and close restore script
  if [ $clean = 1 ]; then
    echo "rm -f \"\$tmpfile\"" >>"$outfile"
  fi
############################################################################################Martineau hack ##################################
fi
#######################################################################################################################################
{
  echo "nvram commit"
  echo "sleep 5"
  echo ""
} >>"$outfile"
############################################################################################Martineau Hack ######################################
if [ "$V384XX" != "1" ]; then
  {
    echo "echo -e \"$cBGRE$aBLINK\""
    echo "logger -st \"\$scr_name\"  \" Martineau Customisation - '/tmp/mnt/$MYROUTER/Firmware_ver.txt' deleted to force '/jffs/scripts/RefreshWWW.sh' to run @Boot\""
    echo "echo -e \"$cRESET\""
    echo "rm \"/tmp/mnt/$MYROUTER/Firmware_ver.txt\" 2> /dev/null"
    echo "echo \"\""
    echo ""
    echo "echo -e \"$cBWHT\""
  } >>"$outfile"
  # POSIX update
  #echo -e "\n\t" "$cBGRE""$aBLINK"
  printf '\n%b%b' "$cBGRE" "$aBLINK"
  logger -st "$scr_name" "Martineau Customisation - Include deletion of '/tmp/mnt/$MYROUTER/Firmware_ver.txt'"
  # POSIX update
  #echo -e "$cRESET"
  printf '%b' "$cRESET"
fi
{
  ##########################################################################################################################################
  echo "logger -s -t \"\$scr_name\"  \"Complete: User NVRAM restored\""
  ############################################################################################Martineau Hack #####################################
  #echo "echo \"Please reboot\"" >>$outfile
  #echo "echo -e \"\n\t\a$cBRED${aBLINK}Please REBOOT$cRESET\""
  printf '%s\n' "printf '\n\a\t%b%s%b' \"$cBRED$aBLINK\" \"Please REBOOT\" \"$cRESET\""
  ##########################################################################################################################################
  echo "echo \"\""
  echo ""
  echo "exit 0"
} >>"$outfile"

if [ "$isfat" -eq 0 ]; then
  chmod 755 "$outfile"
fi

echo ""
logger -s -t "$scr_name" "Complete: User NVRAM saved to ""$outfile"
echo ""
# Update runlog
############################################################################################Martineau Hack ######################################
#echo "$(printf "%-20s" $scr_name)$(printf "%-20s" $rundate$dash$macid)$(date)$space4$(printf "%-20s" $codelevel)`grep "#Version=" $infile`" >>$runlog
END_TIME=$(date +%s)
DIFFTIME=$((END_TIME - START_TIME))
if [ "$initype" != "custom" ]; then
  echo "$(printf "%-20s" "$scr_name")$(printf '%-30s' "$rundate$UNDERSCORE$MYROUTER$dash$macid$space4")$(date)$space4$(printf "%-11s" "$codelevel") $inifile $(grep "#Version=" $infile) $((DIFFTIME / 60)) minutes and $((DIFFTIME % 60)) seconds elapsed, Total Bytes=$TOTALBYTES" >>"$runlog"
else
  echo "$(printf "%-20s" "$scr_name")$(printf "%-30s" "$rundate$UNDERSCORE$MYROUTER$dash$macid$space4")$(date)$space4$(printf "%-11s" "$codelevel") $inifile $((DIFFTIME / 60)) minutes and $((DIFFTIME % 60)) seconds elapsed, Total Bytes=$TOTALBYTES" >>"$runlog"
fi

###########################################################################################################################################

# backup jffs storage if configured
if [ -d "/jffs" ] && [ "$jffsbackup" -eq 1 ]; then
  ############################################################################################Martineau Hack ######################################
  #jffsdir="$dwd/jffs$dash$rundate$dash$macid"
  jffsdir="$dwd/jffs$dash$rundate$UNDERSCORE$MYROUTER$dash$macid"
  ###########################################################################################################################################

  if [ ! -d "$jffsdir" ]; then
    mkdir "$jffsdir"
  fi
  if [ "$isfat" -eq 0 ]; then
    cp -af "/jffs/." "$jffsdir"
  else
    cp -dRf "/jffs/." "$jffsdir"
  fi
  touch "$jffsdir"
  logger -s -t "$scr_name" "Complete: JFFS directory saved to ""$jffsdir"
  echo ""
  # Update runlog
  ############################################################################################Martineau Hack ######################################
  #echo "$(printf "%-20s" jffs-save)$(printf "%-20s" $rundate$dash$macid)$(date)" >>$runlog
  #echo "$(printf "%-20s" jffs-save)$(printf "%-30s" $rundate$UNDERSCORE$MYROUTER$dash$macid)$(date)" >>$runlog
  echo "$(printf "%-20s" jffs-save)$(printf '%-30s' "$rundate$UNDERSCORE$MYROUTER$dash$macid$space4$(date)")" >>"$runlog"
  ###########################################################################################################################################

fi

# Process user exit if it exists
if [ -f "$cwd/nvram-user.sh" ] && [ "$userscript" -eq 1 ]; then
  set -x
  ############################################################################################Martineau Hack ######################################
  sh "$cwd/nvram-user.sh" "$rundate$UNDERSCORE$MYROUTER$dash$macid" # don't need to pass dir anymore: $dwd"
  #sh $cwd/nvram-user.sh $dash$rundate$dash$macid $dwd
  ###########################################################################################################################################
  logger -s -t "$scr_name" "Complete: Processed user exit script ""$cwd""/nvram-user.sh"
  echo ""
fi

# remove working inifile
rm $infile

############################################################################################Martineau Hack ######################################
# Xentrk
#echo -en "$cBGRE"
printf '%b' "$cBGRE"
# List stats for this invocation
tail -2 "$runlog"
#echo -e "$cRESET"
printf '%b' "$cRESET"
###########################################################################################################################################
exit 0
