#!/bin/bash

reportfailed()
{
    echo "Script failed...exiting. ($*)" 1>&2
    exit 255
}

export CODEDIR="$(cd "$(dirname "$0")" && pwd -P)" || reportfailed

if [ "$DATADIR" = "" ]; then
    # Choose directory of symbolic link by default
    DATADIR="$CODEDIR"
fi

source "$DATADIR/datadir.conf"

kvm_is_running()
{
    pid="$(cat "$DATADIR/runinfo/kvm.pid" 2>/dev/null)" &&
	[ -d /proc/"$(< "$DATADIR/runinfo/kvm.pid")" ]
}

kvm_is_running || reportfailed "KVM is not running"

: ${SSHUSER:=$(cat "$DATADIR/sshuser" 2>/dev/null)}
: ${SSHPORT:=$(cat "$DATADIR/runinfo/port.ssh" 2>/dev/null)}

sshkeyfile="$DATADIR/sshkey"
keyparams="-i $sshkeyfile"
[ -f "$sshkeyfile" ] || keyparams=""

: ${SSHUSER:?} ${SSHPORT:?}

ssh "$SSHUSER"@127.0.0.1 -p "$SSHPORT" $keyparams "$@"
