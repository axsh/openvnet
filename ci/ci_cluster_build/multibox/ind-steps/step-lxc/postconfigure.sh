#!/bin/bash

(
    $starting_step "Setup LXC"
    run_ssh root@${IP_ADDR} "mount | grep -q cgroup"
    $skip_step_if_already_done; set -xe
    run_ssh root@${IP_ADDR} <<EOS
mkdir -p /cgroup
echo "cgroup /cgroup cgroup defaults 0 0" >> /etc/fstab
mount /cgroup
EOS
) ; prev_cmd_failed
