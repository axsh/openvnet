#!/bin/bash

(
    $starting_step "Set up OpenVNet third party repo for openvswitch"
    [[ -f ${TMP_ROOT}/etc/yum.repos.d/openvnet-third-party.repo ]]
    $skip_step_if_already_done; set -xe
    sudo chroot ${TMP_ROOT} /bin/bash -c "cat > /etc/yum.repos.d/openvnet-third-party.repo <<EOS
[openvnet-third-party]
name=OpenVNet - 3d party
failovermethod=priority
baseurl=https://ci.openvnet.org/repos/packages/rhel/7/third_party/current/
enabled=1
gpgcheck=0
EOS"
) ; prev_cmd_failed

install_package "openvswitch-2.4.1"
