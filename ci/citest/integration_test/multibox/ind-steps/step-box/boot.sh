#!/bin/bash

[[ "${base}" == "true" ]] && { umount-seed-image ; exit 200 ; }
(
    $starting_group "Cleanup build phase"
    [ ! -f "$(vm_image)" ]
    $skip_group_if_unnecessary
    umount-seed-image
    (
        $starting_step "Cache box for branch ${BRANCH}"
        [ -f "$(cache_image)" ]
        $skip_step_if_already_done ; set -ex
        sudo qemu-img convert -c -O qcow2 "$(vm_image)" "$(cache_image)"
    ) ; prev_cmd_failed

    (
        $starting_step "Delete raw image"
        [ ! -f "$(vm_image)" ]
        $skip_step_if_already_done ; set -ex
        rm "$(vm_image)"
    ) ; prev_cmd_failed
) ; prev_cmd_failed

(
    $starting_step "Generate copy-on-write image"
    [ -f "${NODE_DIR}/${vm_name}.qcow2" ]
    $skip_step_if_already_done ; set -ex
    sudo qemu-img create -f qcow2 -b $(cache_image) "${NODE_DIR}/${vm_name}.qcow2"
) ; prev_cmd_failed

(
    $starting_step "Start kvm for ${vm_name}"
    sudo kill -0 $(sudo cat "${NODE_DIR}/${vm_name}.pid" 2> /dev/null) 2> /dev/null
    $skip_step_if_already_done;
    boot_img="${NODE_DIR}/${vm_name}.qcow2"

    sudo $(cat <<EOS
     qemu-system-x86_64 \
       -machine accel=kvm \
       -cpu ${cpu_type} \
       -m ${mem_size} \
       -smp ${cpu_num} \
       -vnc ${vnc_addr}:${vnc_port} \
       -serial ${serial} \
       -serial pty \
       -drive file=${boot_img},media=disk,if=virtio,format=qcow2
       $(
         for (( i=0 ; i < ${#nics[@]} ; i++ )); do
             nic=(${nics[$i]})
             echo -netdev tap,ifname=${nic[0]#*=},script=,downscript=,id=${vm_name}${i}
             echo -device virtio-net-pci,netdev=${vm_name}${i},mac=${nic[1]#*=},bus=pci.0,addr=0x$((3 + ${i}))
         done
       ) \
       -daemonize \
       -pidfile ${NODE_DIR}/${vm_name}.pid
EOS
        )
) ; prev_cmd_failed

for (( i=0 ; i < ${#nics[@]} ; i++ )) ; do
    nic=(${nics[$i]})

    # Attach tap device to bridge if bridge= was provided
    [[ -z "${nic[2]#*=}" ]] || {
        (
            $starting_step "Attach ${nic[0]#*=} to ${nic[2]#*=}"
            sudo brctl show ${nic[2]#*=} | grep -wq ${nic[0]#*=}
            $skip_step_if_already_done; set -ex
            sudo ip link set ${nic[0]#*=} up
            sudo brctl addif ${nic[2]#*=} ${nic[0]#*=}
        ) ; prev_cmd_failed
    }

    # Set tap device IP adddress if tap_ip_addr= was provided
    [[ -z "${nic[3]#*=}" ]] || {
      (
        ip_addr="${nic[3]#*=}"
        $starting_step "Assign ${ip_addr} to ${nic[0]#*=}"
        ip addr show ${nic[0]#*=} | grep -q ${ip_addr}
        $skip_step_if_already_done; set -x
        sudo ip addr add ${ip_addr} dev ${nic[0]#*=}
        sudo ip link set ${nic[0]#*=} up
      ) ; prev_cmd_failed
    }

    # Set tap device MAC address if tap_hwaddr= was provided
    [[ -z "${nic[4]#*=}" ]] || {
      (
        mac_addr="${nic[4]#*=}"
        $starting_step "Assign ${mac_addr} to ${nic[0]#*=}"
        ip addr show ${nic[0]#*=} | grep -q ${mac_addr}
        $skip_step_if_already_done; set -x
        sudo ip link set dev ${nic[0]#*=} address ${mac_addr}
      ) ; prev_cmd_failed
    }
done
