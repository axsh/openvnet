#!/bin/bash

check_dep "tar"
check_dep "rsync"
check_dep "brctl"
check_dep "qemu-system-x86_64"
check_dep "parted" # For mount-partition.sh

for box in ${BOXES} ; do
    download_seed_image "${box}"
done

create_bridge "${name_ovs_br0}"
create_bridge "${name_ovs_br1}"
create_bridge "${name_ovs_wanedge}" "${ip_wanedge}"
create_bridge "${name_mng_br0}" "${ip_mng_br0}"


(
    $starting_step "Add macvlan interface"
    ip link | grep -q "${macvlan_1_name}"
    $skip_step_if_already_done; set -ex
    sudo ip link add link ${name_ovs_wanedge} dev ${macvlan_1_name} address ${macvlan_1_mac} type macvlan
    sudo ip addr add ${macvlan_1_ip} dev ${macvlan_1_name}
) ; prev_cmd_failed
