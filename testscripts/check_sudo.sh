#!/bin/bash
echo "Checking for sudo"
if [[ $EUID != 0 ]];
  then
    echo "Trying to use sudo"
    sudo "./check_sudo.sh" "$0"
    exit $?
fi
echo "Yes we're sudo"
exit
