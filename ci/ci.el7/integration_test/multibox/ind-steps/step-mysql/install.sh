#!/bin/bash

(
    $starting_step "Add mysql community release rpm package"
    run_cmd "rpm -qa | grep -wq mysql-community-release-el7"
    $skip_step_if_already_done; set -ex
    run_cmd "curl -O http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm"
    run_cmd "rpm -ivh mysql-community-release-el7-5.noarch.rpm"
) ; prev_cmd_failed

install_package "mysql-server"
