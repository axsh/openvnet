#!/bin/bash

(
    $starting_group "Install sclo ruby"
    run_cmd "rpm -q --quiet ${BOXES_SCL_RUBY:?Missing env.} ${BOXES_SCL_RUBY}-rubygem-bundler ${BOXES_SCL_RUBY}-rubygem-rake"
    $skip_group_if_unessecarry
    install_package "centos-release-scl"
    install_package "yum-utils"
    (
        $starting_step "Enable RHSCL"
        run_cmd "which yum-config-manager > /dev/null"
        $skip_step_if_already_done
        run_cmd "yum-config-manager --enable rhel-server-rhscl-6-rpms"
    ) ; prev_cmd_failed
    install_package "${BOXES_SCL_RUBY}" "${BOXES_SCL_RUBY}-rubygem-bundler" "${BOXES_SCL_RUBY}-rubygem-rake"
) ; prev_cmd_failed
