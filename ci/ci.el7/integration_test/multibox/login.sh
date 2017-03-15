#!/bin/bash

export ENV_ROOTDIR="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)"
export NODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

node="${1}"
protocol="${2:-ssh}"

if [[ "${NODE_DIR}" == "${ENV_ROOTDIR}" ]] ; then
    [[ "${node}" == "" ]] && {
        echo "Error: missing node name"
        exit 1
    }
    PROTOCOL=${protocol} ${ENV_ROOTDIR}/${node}/login.sh
else
    . "${NODE_DIR}/vmspec.conf"

    $(sudo kill -0 $(sudo cat "${NODE_DIR}/${vm_name}.pid" 2> /dev/null) 2> /dev/null) || {
        echo "Error: node not running"
        exit 1
    }

    [[ ${PROTOCOL} == "ssh" ]] &&
        ssh -i ${NODE_DIR}/sshkey root@${IP_ADDR}
    [[ ${PROTOCOL} == "telnet" ]] && {
        telnet_host="${serial%%,*}"
        telnet_host=${telnet_host#*:}
        telnet "${telnet_host%:*}" "${telnet_host#*:}"
    }
fi
