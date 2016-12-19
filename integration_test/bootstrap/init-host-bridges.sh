#!/bin/bash   # -x

vboxcmd=VBoxManage

function update_if_ip {
    local host_interface=$1
    local host_if_ip=$2

    echo "${vboxcmd} hostonlyif ipconfig ${host_interface}  -ip ${host_if_ip}  "
    ${vboxcmd} hostonlyif ipconfig ${host_interface}  -ip ${host_if_ip} 
}

########################################################

bridge_iface=(
    "vboxnet0"
    "vboxnet1"
    "vboxnet2"
    "vboxnet3"
    "vboxnet4"
)

for iface in ${bridge_iface[@]}; do
    "${vboxcmd}" hostonlyif remove ${iface}
    "${vboxcmd}" hostonlyif create
done

# Wanedge bridge
update_if_ip vboxnet3 10.210.0.1 

# Manage bridge
update_if_ip vboxnet4 192.168.3.1
