#!/bin/bash

# Set the PATH variable so chrooted centos will know where to find stuff
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/libexec

export ENV_ROOTDIR="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)"
. "${ENV_ROOTDIR}/ind-steps/common.source"
. "${ENV_ROOTDIR}/config.source"

scheduled_nodes=${NODES[@]}
[[ -n "$1" ]] && scheduled_nodes="${@}"

# Current build process
#
#    env : build - buildenv
#              init
#              preconfigure
#              boot
#
#              node<n>: build - IND_STEPS[@]
#                  init
#                  install
#                  preconfigure
#                  boot
#                  postconfigure
#                  provide
#              /node<n>
#
#              node<n> ovn: build - openvnet
#                  install
#              /node<n> ovn finish
#
#              postconfigure
#              provide
#    /env finish

initialize
( build "buildenv" ) ; prev_cmd_failed
