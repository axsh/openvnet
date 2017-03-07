#!/bin/bash

reportfailed()
{
    echo "Script failed...exiting. ($*)" 1>&2
    exit 255
}

export ORGCODEDIR="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)" || reportfailed

DATADIR="$ORGCODEDIR"
source "$ORGCODEDIR/simple-defaults-for-bashsteps.source"

mfff()
{
    (
	$starting_step "Make t-fff"
	cd "$DATADIR"
	[ -f t-fff ]
	$skip_step_if_already_done; set -e
	date >t-fff
    ) ; $prev_cmd_failed
}


(
    $starting_group "group 1"
    mfff
    (
	$starting_step "Make t-ddd"
	cd "$DATADIR"
	[ -f t-ddd ]
	$skip_step_if_already_done; set -e
	date >t-ddd
    ) ; $prev_cmd_failed
) ; $prev_cmd_failed

(
    $starting_group "group 2"
    mfff
    (
	$starting_step "Make t-eee"
	cd "$DATADIR"
	[ -f t-eee ]
	$skip_step_if_already_done; set -e
	date >t-eee
    ) ; $prev_cmd_failed
) ; $prev_cmd_failed
