#!/bin/bash

# don't run unless this script is the process leader
kill -0 -$$ || {
    echo "This script must be started with setsid" 1>&2
    exit 255
}

proc_info_prefix="$1"
shift

cmdline=( "$@" )

stillrunning()
{
    # probably not worth doing, but this catches the (very) rare case
    # where some similar looking process reuses the same pid
    env="$(cat /proc/$orgpid/environ 2>/dev/null)" && [[ "$env" == *${marker}* ]]
}

monitor()
{
    while true; do
	sleep ${mp_interval:=30}
	nowpid="$(cat "$proc_info_prefix.pid")"
	[ "$nowpid" == "$orgpid" ] || break
	stillrunning || break
    done
    kill -TERM 0
    # see man kill(2), should kill all processes in same process group
    # including the background process $orgpid
}

export marker=aaa-$$-$RANDOM-zzz
echo "$marker" >"$proc_info_prefix.marker"

echo "$$" >"$proc_info_prefix.wrapperpid"

echo "${cmdline[@]}" >"$proc_info_prefix.cmdline"

# the process of interest gets started here
"${cmdline[@]}" 1>"$proc_info_prefix.stdout" 2>"$proc_info_prefix.stderr" </dev/null &
orgpid="$!"
echo "$orgpid" >"$proc_info_prefix.pid"

# monitor the process, and if anything looks amiss, kill it and related processes
monitor &
echo "$!" >"$proc_info_prefix.monitorpid"

# if the process exits normally, note its return code
rm -f "$proc_info_prefix.returncode"
wait "$orgpid"
rc="$?"
echo "Exited with rc=$rc" >>"$proc_info_prefix.stdout"
echo "$rc" >"$proc_info_prefix.returncode"
kill -TERM 0 # should also kill monitor()
