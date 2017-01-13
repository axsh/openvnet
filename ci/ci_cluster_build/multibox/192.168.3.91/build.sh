#!/bin/bash

export ENV_ROOTDIR="$(cd "$(dirname $(readlink -f "$0"))/.." && pwd -P)"
export NODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT="${NODE_DIR}/tmp_root"

. "${ENV_ROOTDIR}/config.source"
. "${NODE_DIR}/vmspec.conf"
. "${ENV_ROOTDIR}/ind-steps/common.source"

ovn_vnmgr=true
ovn_webapi=true

containers=(
    vm1
    vm2
)

IND_STEPS=(
    "box"
    "ssh"
    "epel"
    "redis"
    "mysql"
    "lxc"
)

initialize
build "${IND_STEPS[@]}"
