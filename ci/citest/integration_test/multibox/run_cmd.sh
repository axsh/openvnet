#!/bin/bash

export ENV_ROOTDIR="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)"
export NODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

node="${1}"

if [[ "${NODE_DIR}" == "${ENV_ROOTDIR}" ]] ; then
    [[ "${node}" == "" ]] && {
        echo "Error: missing node name"
        exit 1
    }
    shift ; ${ENV_ROOTDIR}/${node}/run_cmd.sh "${@}"
else
    . "${NODE_DIR}/vmspec.conf"
    $(sudo kill -0 $(sudo cat "${NODE_DIR}/${vm_name}.pid" 2> /dev/null) 2> /dev/null) || {
        echo "Error: node not running"
        exit 1
    }

    . "${ENV_ROOTDIR}/ind-steps/common.source"
    run_cmd "${@}"
fi
