#!/bin/bash

(
    $starting_group "Building box"
    false
    $skip_group_if_unnecessary
    ${ENV_ROOTDIR}/box/build.sh
) ; prev_cmd_failed
