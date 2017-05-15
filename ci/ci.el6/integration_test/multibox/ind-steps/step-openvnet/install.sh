#!/bin/bash

(
    $starting_step "Update openvnet repository"
    false # Always perform this step
    $skip_step_if_already_done; set -ex
    run_cmd <<EOF
yum --enablerepo=openvnet clean metadata
cat <<EOS > /etc/yum.repos.d/openvnet.repo
[openvnet]
name=OpenVNet
failovermethod=priority
baseurl=https://ci.openvnet.org/repos/${BRANCH}/packages/rhel/6/vnet/${RELEASE_SUFFIX:-current}
enabled=1
gpgcheck=0
EOS
EOF

) ; prev_cmd_failed

install_package "openvnet"
