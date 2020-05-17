#!/bin/bash

if [ -e /sys/kernel/mm/ksm/pages_sharing ]; then
    pages_sharing=`cat /sys/kernel/mm/ksm/pages_sharing`;
    page_size=`getconf PAGESIZE`;
    saved=$(echo "scale=0;$pages_sharing * $page_size" |bc);
    echo "KSM currently sharing $saved bytes of memory"
fi