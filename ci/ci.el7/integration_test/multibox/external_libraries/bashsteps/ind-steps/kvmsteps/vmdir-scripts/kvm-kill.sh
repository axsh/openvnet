#!/bin/bash

source "$(dirname $(readlink -f "$0"))/../simple-defaults-for-bashsteps.source"

if [[ "$DATADIR" != /* ]]; then
    # Choose directory of symbolic link by default
    DATADIR="$LINKCODEDIR"
fi

kvm_is_running()
{
    pid="$(cat "$DATADIR/runinfo/kvm.pid" 2>/dev/null)" &&
	[ -d /proc/"$(< "$DATADIR/runinfo/kvm.pid")" ]
}

(
    $starting_step "Killing KVM process"
    ! kvm_is_running
    $skip_step_if_already_done
    set -e
    thepid="$(cat "$DATADIR/runinfo/kvm.pid" 2>/dev/null)"
    marker="$(cat "$DATADIR/runinfo/kvm.marker" 2>/dev/null)"
    env="$(cat /proc/$thepid/environ 2>/dev/null)" && [[ "$env" == *${marker}* ]]
    kill -TERM "$thepid"
) ; prev_cmd_failed
