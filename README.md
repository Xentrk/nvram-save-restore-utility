# NVRAM Save/Restore Utility for Asuswrt-Merlin Firmware
[![Build Status](https://travis-ci.com/Xentrk/nvram-save-restore-utility.svg?branch=master)](https://travis-ci.com/Xentrk/nvram-save-restore-utility)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/dd74bea80e1846ddbbde7d794aff2b73)](https://www.codacy.com/manual/Xentrk/nvram-save-restore-utility?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=Xentrk/nvram-save-restore-utility&amp;utm_campaign=Badge_Grade)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Introduction
Utility to save/restore NVRAM values and the jffs partition on Asuswrt-Merlin firmware.

## Support
For help and support, please visit the NVRAM Save/Restore Utility support thread on [snbforums.com](https://www.snbforums.com/threads/release-nvram-save-restore-utility.61722/).

See the
[[FAQ] NVRAM and Factory Default Reset](https://www.snbforums.com/threads/faq-nvram-and-factory-default-reset.22822/) for additional information.

## Requirements
A properly formatted USB drive with an available partition for the NVRAM Save/Restore Utility installation.

## Project Development
[john9547](https://www.snbforums.com/members/john9527.27638/) is the original author of the NVRAM Save/Restore Utility. The last update made by john9527 was [Version 26.2](http://bit.ly/2aaAySO) released on 24-Sep-2018.

[Martineau](https://www.snbforums.com/members/martineau.13215/) made numerous updates to the NVRAM Save/Restore Utility:
* Version 30.1 code updates to **nvram-restore.sh**, **nvram-restore.sh** and **nvram-save.sh** made the utility compatible with the 384.13 Asuswrt-Merlin release.
* Added functionality to **nvram-restore.sh** listing the restore files with the ability to delete a restore file or a range of restore files.
* Add functionality to **jffs-restore.sh** listing the jffs restore files.

[Xentrk](https://www.snbforums.com/members/xentrk.49161/) contributed the hosting of the repository on GitHub, coding of the installation menu, code updates to make the code POSIX compliant, and updating the nvram variables in the nvram-merlin.ini file.

Contributions to the project by other coders are always welcome and appreciated.

## Installation

Copy and paste the command below into an SSH session:

```
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/Xentrk/nvram-save-restore-utility/master/nsrum" -o "/jffs/scripts/nsrum" && sleep 5 && chmod 755 /jffs/scripts/nsrum && sh /jffs/scripts/nsrum
```
This command will download and install the NVRAM Save/Restore Ulitity Menu **nsrum** to the **/jffs/scripts** directory.

<img src="https://github.com/Xentrk/nvram-save-restore-utility/blob/master/InstallationMenu.PNG" alt="drawing" width="700" height="600"/>

Option **[5]  Update NVRAM Save/Restore Utility Menu** will only be displayed if there is an update to the installation menu available.

Select option **[1]  Install NVRAM Save/Restore Utility** to install the utility. You will be presented with a list of available partitions on the USB drive. Select the partition you want to install the utility in. A directory called **nsru** (the acronym for NVRAM Save/Restore Utility) will be created in the partition for the utility scripts and files (e.g. **/mnt/ASUS/nsru**). The installation program will also create a backup directory (e.g. **/mnt/ASUS/nsru/backup**) to keep the generated save/restore files separate from the utility scripts and files.

To access the installation menu, type the command **nsrum** at the command prompt. To access the project directory, type the command **nsru** at the command prompt. These commands will not work after performing a factory reset since they require alias entries in **/jffs/configs/profile.add**, which will not exist after performing a factory reset. After a factory reset, you must navigate to the NVRAM Save/Restore Utility directory using the **cd** command (e.g. cd /mnt/AC88U/nsru).

## Project Scripts and Files
| Script Name   | Description |
| --- | --- |
| nvram-save.sh |	Main user script |
nvram-restore.sh | User script to restore saved user NVRAM variables |
| jffs-restore.sh	|	User script to restore jffs directory |
| nvram-hnd-migr.sh | Script to restore nvram parameters when migrating from a non-HND router to a HND* router |
| nvram-excp-merlin.sh | Script to adjust nvram parameters for code specific issues |
| nvram-merlin.ini | NVRAM variable control file
| nvram-sample.ini | Example user NVRAM control file with only basic variables |
| nvram-user-sample.sh | Creates a tar backup of the nvram backup files and jffs directory |
| clear-maclist.sh	| Script to clear MAC list filters in case of problems detecting the correct format (multiple changes between firmware levels) |
| save-mynvram.sh	|	A small script that can save/restore a small number of user specified nvram settings |
| QuickStart.txt	|	Documentation in text format |
| Changelog.txt |		Version history in text format |

*HND Router models: RT-AC86U and RT-AX88U

## Running the Scripts from the Command Line
The NVRAM Save/Restore Utility scripts must be run from the command line in the project directory.
* At the SSH prompt, enter ```ls /mnt``` to see the names of the partition labels on the USB stick (e.g. ASUS).
* Change to the project directory using the change directory command (e.g. ```cd /mnt/ASUS/nsru```).
* Run the scripts using the syntax ```sh script-name.sh``` or ```./script-name.sh```.

## nvram-save.sh Usage Notes

* Basic help is available by entering ```sh nvram-save.sh -h```

```
NVRAM User Save/Restore Utility
nvram-save.sh Version 30.3.0
Options: -h           this help msg
         -v           Print version/perform consistency check
         -b           Backup mode - save for restore to same router (default)
         -m           Migration mode - transfer settings to another router
         -i inifile   Specify custom nvram variable ini file
         -clk         Include clkfreq/overclock setting (Backup mode only)
         -nojffs      Skip backup of jffs storage
         -nouser      Skip execution of user exit script
```
* When running the utility or using the -v version option, **nvram-save.sh**, **nvram-restore.sh**, **jffs-restore.sh**, **nvram-merlin.ini** and **nvram-excp-merlin.sh** are consistency checked to make sure they are all the same version. A WARNING message will be printed on a version mismatch, but execution will continue if actually running to generate the restore script.

* You can now specify a custom nvram variable 'ini' file to use to generate the restore script. A sample ini file, **nvram-sample.ini**, is included which is a stripped down version of the full ini containing only basic entries that people have mentioned in various threads.

* The default state is NOT to save clkfreq overclocking values (safest when moving to a new code level). If you wish to include this setting, specify the -clk option on the nvram-save.sh command.

* The nvram-merlin.ini files contains a section at the end for additions. You may edit this section to add any NVRAM variables you may have created for use in scripts, or to temporarily add any variables which may be missing.

* The NVRAM Save/Restore Utility also creates three text files during execution that can be viewed or archived.
  * nvram-all-yyyymmddhhmm_MODEL-macid.txt (all nvram variables, including system variables not normally changed by the user)
  * nvram-usr-yyyymmddhhmm_MODEL-macid.txt (the nvram variables actually saved by the utility in their save categories)
  * nvram-ini-yyyymmddhhmm_MODEL-macid.txt (a copy of the nvram-merlin.ini configuration file used by the utility in the nvram-save operation)

  Where
  * yyyymmddhhmm is the timestamp of the saved setting
  * MODEL is the model number e.g. RT-AC88U
  * macid In Backup Mode, this is the last two bytes of the router MAC address (for example E1F2). In Migration Mode, this will be MIGR

* The utility is still valid for ASUS OEM as well as Merlin releases, although it will not attempt to fix changes in the use of nvram variables between releases (just too many ASUS levels with various release numbers to track).

## nvram-restore.sh Usage Notes

* Enter ```sh nvram-restore.sh```

You will be presented with a listing of current nvram-restore backup files. The **'Ver=--------'** indicates the presence of a nvram-restore file that was interrupted when nvram-save.sh was run.

Enter a 'y' or 'Y' to restore nvram using the most recent file. Press the enter key or any non-valid character to exit.

To delete a NVRAM restore file (and all associated text files) and the associated jffs restore backup directory, enter the line number followed by the 'del' parameter (e.g. 1 del). To delete a range of files, enter the from-to range separated by a dash followed by the 'del' parameter (e.g. 1-3 del).

```
          nvram-restore.sh NVRAM Restore Utility - Version 30.3.0

        NVRAM Restore File Directory: /tmp/mnt/AC88U/nsru/backup

  1 : nvram-restore-202001112027_RT-AC88U-8248.sh       Ver=384.14_2 nvram-merlin.ini
  2 : nvram-restore-202001112031_RT-AC88U-8248.sh       Ver=384.14_2 nvram-merlin.ini
  3 : nvram-restore-202001121854_RT-AC88U-8248.sh       Ver=384.14_2 nvram-merlin.ini
  4 : nvram-restore-202001151944_RT-AC88U-8248.sh       Ver=--------
  5 : nvram-restore-202001151945_RT-AC88U-8248.sh       Ver=--------

        Restore last NVRAM save ? (nvram-restore-202001121854_RT-AC88U-8248.sh)
        { n[{-n}] [ del ] | Y } (or press ENTER to ABORT) > 5 del
        Deleted                   (*202001151945_RT-AC88U-8248.*)

```
You can also provide the yyyymmddhhmm_MODEL-macid code on the command line to load a specific file:

```
sh nvram-restore.sh 202001121854_RT-AC88U-8248

Migration restore from a full nvram-save is not supported on this save file

Do you want to proceed [Y/N]? y

A clean restore will restore only those NVRAM settings
  which have been initialized by the router after a factory reset
This option should by used when reverting to an earlier
  firmware level, when updating past a single firmware release,
  when moving between OEM and Merlin firmware or
  to ensure any special use or obsolete NVRAM variables are cleared
If in doubt, answer Y to perform a clean restore

Perform a clean restore and remove unused NVRAM variables [Y/N]?
```
### Restoring After a Factory Reset

* The **UPnP** setting on the WAN page must be configured manually after running **nvram-restore.sh**.
* You will need to acknowledge the **TrendMicro** EULA upon logging into the router Web GUI if it was previously enabled.

## jffs-restore.sh Usage Notes

* Enter ```sh jffs-restore.sh```

You will be presented with a listing of current jffs backup files.

Enter a 'y' or 'Y' to restore the jffs partition, or the enter key, or any non-valid character, to exit.

```
  jffs-restore.sh JFFS Restore Utility - Version 30.3.0

  JFFS Restore File Directory: /tmp/mnt/AC88U/nsru/backup

     1 : jffs-202001112027_RT-AC88U-8248
     2 : jffs-202001112031_RT-AC88U-8248
     3 : jffs-202001121854_RT-AC88U-8248

  Restore last saved /jffs/ ? (jffs-202001121854_RT-AC88U-8248)
  { n | Y } (or press ENTER to ABORT) >
```

You can also provide the yyyymmddhhmm_MODEL-macid code on the command line to load a specific file:

```
sh jffs-restore.sh 202001121854_RT-AC88U-8248

        Restoring saved /jffs/ (jffs-202001121854_RT-AC88U-8248)

        WARNING: This will overwrite/replace the current contents of your /jffs directory!
        Do you want to continue [Y/N] ?
```
## nvram-merlin.ini File Format and Usage Notes
**nvram-merlin.ini** is the NVRAM variable control file used by **nvram-save.sh** containing the nvram variables to process. The **nvram-merlin.ini** file format for the nvram definitions follows the format of a section header followed by nvram variables. For example:
```
[System - Basic]
time_zone_dst
time_zone
time_zone_dstoff
```
There are additional controls which can be added. To exclude an entire section from backup, comment # the section header
```
#[System - Basic]
time_zone_dst
time_zone
time_zone_dstoff
```

To exclude an individual nvram setting from backup, comment # the setting
```
[System - Basic]
#time_zone_dst
time_zone
time_zone_dstoff
```
To exclude the setting from being saved during a migration save, or restored during a migration restore, prefix it with a @. This is only valid for individual settings and is not valid on the section header.
```
[System - Basic]
@time_zone_dst
time_zone
time_zone_dstoff
```
To force a setting to always be included in the restore, even if it would normally be excluded on a 'clean' restore, prefix the setting with a + .  This may also be used to preserve custom nvram settings across a factory reset. This is only valid for individual settings and is not valid on the section header.
```
[System - Basic]
+time_zone_dst
time_zone
time_zone_dstoff
```

To force a setting to always be included in the save, even if it is an empty value, prefix the setting with a % .  This will force some variables which may have a valid empty setting to be saved/restored. This is only valid for individual settings and is not valid on the section header.
```
[System - Basic]
%time_zone_dst
time_zone
time_zone_dstoff
```

To combine the above flags and force both the save of an empty value and force it to be restored even if it is not present after a factory reset, prefix the setting with a & .
This is only valid for individual settings and is not valid on the section header.
```
[System - Basic]
&time_zone_dst
time_zone
time_zone_dstoff
```

The last section header in the default nvram-merlin.ini file is for user added nvram settings, such as may be used in custom scripting. For example (also using the force save prefix) for a user nvram variable 'blacklist_enable'

```
[User Adds]
+blacklist_enable
```

## save-mynvram.sh Usage Notes

**save-mynvram.sh** is a small script that can save/restore a small number of user specified nvram settings. Pass the nvram values you want to save to the script as parameters (e.g. **dhcp_hostnames** and **dhcp_staticlist**). This will create a script called **restore-mynvram.sh**. Run **restore-mynvram.sh** to restore the nvram parameters. If a previous **restore-mynvram.sh** restore file exists, a backup file will be created.

```
sh save-mynvram.sh dhcp_hostnames dhcp_staticlist

Saving dhcp_hostnames
Saving dhcp_staticlist
Backing up previous restore script to /tmp/mnt/AC88U/nsru/restore-mynvram.sh.bak

Saved 2 NVRAM variable(s)
Run /tmp/mnt/AC88U/nsru/restore-mynvram.sh to restore your saved settings
```
## nvram-user-sample.sh Usage Notes

**nvram-user-sample.sh** is a small script that creates a tar backup of the nvram backup files and jffs directory using the
save id string "yyyymmddhhmm_MODEL-macid".

```
# sh nvram-user-sample.sh 202001191051_RT-AC88U-8248
Creating nvram-backup-202001191051_RT-AC88U-8248.tar.gz
tar: removing leading '/' from member names
tmp/mnt/AC88U/nsru/backup/nvram-restore-202001191051_RT-AC88U-8248.sh
tmp/mnt/AC88Unsru/backup/jffs-202001191051_RT-AC88U-8248/
tmp/mnt/AC88U/nsru/backup/jffs-202001191051_RT-AC88U-8248/sr
<snip>
```
## nvram-user.sh Usage Notes
The script **nvram-save.sh** will call a user exit script **nvram-user.sh** at the end of execution. A user may create this script to do extra processing on the backup files such as move or copy the backup files to another location.

One parameter is passed to the script
- the save id string in 'yyyymmddhhmm_MODEL-macid' format

See the example included in the script **nvram-user-sample.sh**.

## nvram-hnd-migr.sh Usage Notes
HND routers store some nvram values in the **/jffs/nvram** directory. Run **nvram-hnd-migr.sh** if performing a migration from a non-HND router to an HND router (RT-AC86U and RT-AX88U). This script will create a script in the NVRAM Save/Restore Utility folder called **restore-hnd-migr.sh**. Run **restore-hnd-migr.sh** after running the scripts **nvram-restore.sh** and **jffs-restore.sh** on the HND router to copy the HND specific nvram parameters stored in the the **/jffs/nvram** directory.

Since I lack an HND router to test on, I have only been able to perform limited testing. I have confirmed the nvram parameters do get created in the **/jffs/nvram** directory. Please provide feedback if you happen to use this script during a non-HND to HND router migration.

## Acknowledgements

* Grateful to [Martineau](https://www.snbforums.com/members/martineau.13215/) for providing ongoing support and assistance to myself and other snbforums members, in addition to the 384.13 firmware and feature updates to the project.

* [Adamm](https://github.com/Adamm00) contributed the **md5sum** check function to detect updated code and the **Manage_Device** function to prompt for USB partition.

* I cloned the code used for the update code function from [Jack Yaz](https://github.com/jackyaz/spdMerlin) (also inspired by Adamm) used on the [SpdMerlin](https://github.com/jackyaz/spdMerlin) project on GitHub.

* Gratitude to the [thelonelycoder](https://www.snbforums.com/members/thelonelycoder.25480/), also known as the [Decoderman](https://github.com/decoderman) on GitHub, for his inspiration and ongoing support in my coding journey.

* Thank you to [RMerlin](https://www.snbforums.com/members/rmerlin.10954/) for the [Asuswrt-Merlin](https://github.com/RMerl/asuswrt-merlin.ng) firmware and helpful support on the [snbforums.com](https://www.snbforums.com/forums/asuswrt-merlin.42/) wesbsite. To learn more about Asuswrt-Merlin firmware for Asus routers, visit the project website at [https://www.asuswrt-merlin.net/source](https://www.asuswrt-merlin.net/source).
