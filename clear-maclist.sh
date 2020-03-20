#!/bin/sh

echo "Clear MAC Filter Lists"
# Clear mac-list entries in case of format incompatibility
nvram unset wl_maclist
nvram unset wl0_maclist
nvram unset wl1_maclist
nvram unset wl2_maclist
nvram unset wl_maclist_x
nvram unset wl0_maclist_x
nvram unset wl1_maclist_x
nvram unset wl2_maclist_x
nvram unset wl0.1_maclist
nvram unset wl1.1_maclist
nvram unset wl2.1_maclist
nvram unset wl0.2_maclist
nvram unset wl1.2_maclist
nvram unset wl2.2_maclist
nvram unset wl0.3_maclist
nvram unset wl1.3_maclist
nvram unset wl2.3_maclist
nvram unset wl0.1_maclist_x
nvram unset wl1.1_maclist_x
nvram unset wl2.1_maclist_x
nvram unset wl0.2_maclist_x
nvram unset wl1.2_maclist_x
nvram unset wl2.2_maclist_x
nvram unset wl0.3_maclist_x
nvram unset wl1.3_maclist_x
nvram unset wl2.3_maclist_x

nvram commit

echo "Complete"

exit 0
