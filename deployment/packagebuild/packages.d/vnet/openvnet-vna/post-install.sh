#!/bin/sh
set -e

user="vnet-webapi"
logfile="/var/log/openvnet/webapi.log"
vnet_run_dir="/var/run/openvnet"

if ! id "$user" > /dev/null 2>&1 ; then
    adduser --system --no-create-home --shell /bin/false "$user"
fi

touch "$logfile"
chown "$user"."$user" "$logfile"
chown "$user"."$user" "$vnet_run_dir"
