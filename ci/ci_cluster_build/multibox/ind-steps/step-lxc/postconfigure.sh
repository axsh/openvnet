#!/bin/bash

(
    $starting_step "Setup LXC"
    run_cmd "mount | grep -q cgroup"
    $skip_step_if_already_done; set -xe
    run_cmd <<EOS
mkdir -p /cgroup
echo "cgroup /cgroup cgroup defaults 0 0" >> /etc/fstab
mount /cgroup
EOS
) ; prev_cmd_failed
