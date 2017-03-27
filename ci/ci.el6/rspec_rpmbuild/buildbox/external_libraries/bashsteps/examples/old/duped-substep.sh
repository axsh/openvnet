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
	$starting_checks "Make t-fff"
	cd "$DATADIR"
	[ -f t-fff ]
	$skip_rest_if_already_done; set -e
	date >t-fff
    ) ; $prev_cmd_failed
}


(
    $starting_dependents "Make t-ddd"
    mfff
    $starting_checks
    cd "$DATADIR"
    [ -f t-ddd ]
    $skip_rest_if_already_done; set -e
    date >t-ddd
) ; $prev_cmd_failed

(
    $starting_dependents "Make t-eee"
    mfff
    $starting_checks
    cd "$DATADIR"
    [ -f t-eee ]
    $skip_rest_if_already_done; set -e
    date >t-eee
) ; $prev_cmd_failed
