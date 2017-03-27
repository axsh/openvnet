#!/bin/bash

export ENV_ROOTDIR="$(cd "$(dirname $(readlink -f "$0"))/.." && pwd -P)"
export NODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT="${NODE_DIR}/tmp_root"

. "${ENV_ROOTDIR}/config.source"
. "${ENV_ROOTDIR}/ind-steps/common.source"
. "${NODE_DIR}/vmspec.conf"

packages=(
    "createrepo"
    "rpmdevtools"
    "rpm-build"
    "yum-utils"
    "rsync"
    "sudo"
    "file"
    "zeromq3-devel"
    "yum-utils"
    "make"
    "gcc"
    "gcc-c++"
    "git"
    "mysql-devel"
    "sqlite-devel"
    "mysql"
    "mysql-server"
)

shared_folders=(
    "/cache"
    "/repos"
    "/opt/axsh/openvnet"
)

IND_STEPS=(
    "box"
    "ssh"
    "nfs"
    "epel-release"
    "packages" # the packages usually installed by Dockerfile
)

initialize
build "${IND_STEPS[@]}"
