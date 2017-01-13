#!/bin/bash

export ENV_ROOTDIR="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)"
. "${ENV_ROOTDIR}/ind-steps/common.source"
. "${ENV_ROOTDIR}/ind-steps/step-buildenv/common.source"
. "${ENV_ROOTDIR}/config.source"

kill_option=false
[[ "$1" == "--kill" ]] && { kill_option=true ; shift ; }

scheduled_nodes=${NODES[@]}
[[ -n "$1" ]] && scheduled_nodes="${@}"

for node in ${scheduled_nodes[@]} ; do
    (
        $starting_group "Destroy ${node%,*}"
        false
        $skip_group_if_unnecessary
        ${kill_option} && { ${ENV_ROOTDIR}/${node}/kill.sh ; } || { ${ENV_ROOTDIR}/${node}/destroy.sh ; }
    ) ; prev_cmd_failed
done

[[ -z "${1}" ]] || exit 1

destroy_bridge "vnet-itest_0"
destroy_bridge "vnet-itest_1"
destroy_bridge "vnet-itest_2"
destroy_bridge "vnet-wanedge"
destroy_bridge "vnet-br0"

stop_masquerade "${NETWORK}/${PREFIX}"

