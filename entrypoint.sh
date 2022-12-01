#!/bin/bash

echo && echo -e "\033[032mI AM \033[035m$( whoami )\033[032m!\033[0m" && echo

su root -c "export HOME=/root"
su docker -c "export HOME=/home/docker"

echo -e -n "Server \033[032m${HOSTNAME}\033[0m up and running!"
tail -f /dev/null