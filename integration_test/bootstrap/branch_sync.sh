#!/bin/bash

case "$(uname)" in
    "Darwin")
        rl_cmd="greadlink" ;;
    *)
        rl_cmd="readlink" ;;
esac

readonly OVN_ROOTDIR="$(cd "$(dirname $($rl_cmd -f "$0"))/../../" && pwd -P)"

include_dirs=(
    "client/vnctl"
    "vnet/bin"
    "vnet/lib"
    "vnet/db"
)

vnet_hosts=(
    "192.168.3.91"
    "192.168.3.92"
    "192.168.3.93"
    "192.168.3.96"
)


for vnet_host in "${vnet_hosts[@]}" ; do
    echo "Copying branch: $(cd ${OVN_ROOTDIR} ; git branch | grep \* | cut -d ' ' -f2) to ${vnet_host}"
    for include_dir in "${include_dirs[@]}" ; do
        echo "Copying dir: $OVN_ROOTDIR/$include_dir"
        rsync -ruv ${OVN_ROOTDIR}/$include_dir/ root@$vnet_host:/opt/axsh/openvnet/$include_dir >> synch.log
    done
done
