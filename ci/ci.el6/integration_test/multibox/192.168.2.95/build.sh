#!/bin/bash

export ENV_ROOTDIR="$(cd "$(dirname $(readlink -f "$0"))/.." && pwd -P)"
export NODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT="${NODE_DIR}/tmp_root"

. "${ENV_ROOTDIR}/config.source"
. "${NODE_DIR}/vmspec.conf"
. "${ENV_ROOTDIR}/ind-steps/common.source"

IND_STEPS=(
    "box"
    "ssh"
)

initialize
build "${IND_STEPS[@]}"

run_cmd "/sbin/sysctl -w net.ipv4.ip_forward=1"
