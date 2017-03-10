#!/bin/bash

(
    $starting_group "Install sclo ruby"
    run_cmd "rpm -qa | grep -q rh-ruby"
    $skip_group_if_unessecarry
    (
        $starting_step "Install centos-release-scl"
        run_cmd "rpm -qa | grep -qw centos-release-scl"
        $skip_step_if_already_done
        run_cmd "yum install -y centos-release-scl"
    ) ; prev_cmd_failed

    (
        $starting_step "Install yum-utils"
        run_cmd "rpm -qa | grep -qw yum-utils"
        $skip_step_if_already_done
        run_cmd "yum install -y yum-utils"
    ) ; prev_cmd_failed

    (
        $starting_step "Enable RHSCL"
        run_cmd "which yum-config-manager > /dev/null"
        $skip_step_if_already_done
        run_cmd "yum-config-manager --enable rhel-server-rhscl-7-rpms"
    ) ; prev_cmd_failed

    (
        $starting_step "Install rh-ruby"
        run_cmd "rpm -qa | grep -q rh-ruby"
        $skip_step_if_already_done
        run_cmd "yum install -y rh-ruby22"
    ) ; prev_cmd_failed
) ; prev_cmd_failed
