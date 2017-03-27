#!/bin/bash

(
    $starting_step "Download epel-release rpm"
    run_cmd "[ -f /home/epel-release-6-8.noarch.rpm ]"
    $skip_step_if_already_done ; set -ex
    run_cmd "curl -o /home/epel-release-6-8.noarch.rpm -OL http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
) ; prev_cmd_failed

(
    $stating_step "Install epel-release rpm"
    false
    $skip_step_if_already_done ; set -ex
    run_cmd "rpm -ivh /home/epel-release-6-8.noarch.rpm"
) ; prev_cmd_failed
