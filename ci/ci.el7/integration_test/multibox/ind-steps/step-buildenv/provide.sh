#!/bin/bash

for node in ${scheduled_nodes[@]} ; do
    [[ $node == "base" ]] && continue

    (
        $starting_group "Provide node: ${node%,*}"
        false
        $skip_group_if_unnecessary

        . "${ENV_ROOTDIR}/${node}/vmspec.conf"
        NODE_DIR=${ENV_ROOTDIR}/${node}

        [[ -z ${#containers[@]} ]] || {
            for c in ${containers[@]} ; do
                (
                    $starting_step "Start container: $c"
                    run_cmd "lxc-info -n $c | grep -q RUNNING"
                    $skip_step_if_already_done; set -e
                    run_cmd "lxc-start -n $c -d"
                ) ; prev_cmd_failed
            done

            for iface in "${container_if[@]}" ; do
                read name ifname mac_addr bridge ip_addr <<< "${iface}"
                bridge="${bridge#*=}"
                ifname="${ifname#*=}"
                (
                    # Try to remove the port in case it exists on the bridge to make sure we have
                    # the correct port attached to the bridge
                    $starting_step "Remove port for if-${ifname} from ${bridge}"
                    run_cmd "ovs-vsctl show | grep -q if-${ifname}"
                    [[ $? -ne 0 ]]
                    $skip_step_if_already_done; set -e
                    run_cmd "ovs-vsctl del-port ${bridge} if-${ifname}"
                ) ; prev_cmd_failed

                (
                    # Re-add the port, we always want to perform this step so the check is set to false
                    $starting_step "Add port if-${ifname} to ${bridge}"
                    false
                    $skip_step_if_already_done; set -e
                    run_cmd "ovs-vsctl add-port ${bridge} if-${ifname}"
                ) ; prev_cmd_failed
            done
        }
    ) ; prev_cmd_failed
done


(
    $starting_step "Import ssh key for integration test"
    [ -f ~/.ssh/integ_sshkey ]
    $skip_step_if_already_done
    cp ${CACHE_DIR}/${BRANCH}/sshkey ~/.ssh/sshkey
    chown ${USER}:${USER} ~/.ssh/sshkey
) ; prev_cmd_failed
