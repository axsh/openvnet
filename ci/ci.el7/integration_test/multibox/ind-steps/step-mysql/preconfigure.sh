#!/bin/bash

(
    $starting_step "Disable strict trans tables"
    sudo grep -q "STRICT_TRANS_TABLES" ${TMP_ROOT}/etc/my.cnf
    [[ $? -eq 1 ]]
    $skip_step_if_already_done; set -xe
    # Mysql now  sets STRIC_TRANS_TABLES by default, this serves as a workaround
    run_cmd "sed -i 's,\,STRICT_TRANS_TABLES,,g' /etc/my.cnf"
) ; prev_cmd_failed
