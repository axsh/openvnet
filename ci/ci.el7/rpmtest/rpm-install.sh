#!/bin/bash

set -xe

echo "${BRANCH}" > /etc/yum/vars/branch
echo "${RELEASE_SUFFIX}" > /etc/yum/vars/ovn_release_suffix

yum install -y openvnet
