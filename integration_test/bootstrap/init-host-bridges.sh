#!/bin/bash   # -x

vboxcmd=VBoxManage

function get_hostonlyifs {
    cmd="${vboxcmd} list hostonlyifs"

    
    for line in $($cmd | sed -n -e '/^Name:/p' | awk '{print $2}'); do
       iface=${line}
       echo $iface
    done
}

function add_interface {
    echo "${vboxcmd} hostonlyif create"
    ${vboxcmd} hostonlyif create
}

function update_if_ip {
    local host_interface=$1
    local host_if_ip=$2

    echo "${vboxcmd} hostonlyif ipconfig ${host_interface}  -ip ${host_if_ip}  "
    ${vboxcmd} hostonlyif ipconfig ${host_interface}  -ip ${host_if_ip} 
}

########################################################

existing_host_list=""
for hst in $(get_hostonlyifs); do
    existing_host_list="${hst} $existing_host_list"
done

echo ${existing_host_list} | grep -q "vboxnet0"
if [  $? -ne 0 ]; then
   add_interface
fi
#update_if_ip vboxnet0 dummyip

echo ${existing_host_list} | grep -q "vboxnet1"
if [  $? -ne 0 ]; then
   add_interface
fi
#update_if_ip vboxnet1 dummyip

echo ${existing_host_list} | grep -q "vboxnet2"
if [  $? -ne 0 ]; then
   add_interface
fi
#update_if_ip vboxnet2 dummyip

echo ${existing_host_list} | grep -q "vboxnet3"
if [  $? -ne 0 ]; then
   add_interface
fi
update_if_ip vboxnet3 192.168.3.1

