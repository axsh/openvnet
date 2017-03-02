#!/bin/bash

reportfailed()
{
    echo "Script failed...exiting. ($*)" 1>&2
    exit 255
}

export ORGCODEDIR="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)" || reportfailed

DATADIR="$ORGCODEDIR"
source "$ORGCODEDIR/simple-defaults-for-bashsteps.source"

(
    $starting_group "get hello world binary"
    [ -x "$DATADIR/hw" ]
    $skip_group_if_unnecessary
    (
	$starting_step "output source"
	cd "$DATADIR"
	[ -f hw.c ]
	$skip_step_if_already_done; set -e
	cat >hw.c <<'EOF'
#include <stdio.h>
int main() { printf("hw\n") ; }
EOF
    ) ; $prev_cmd_failed
    
    (
	$starting_step "compile source"
	cd "$DATADIR"
	[ -x hw ]
	$skip_step_if_already_done; set -e
	gcc -o hw hw.c
    ) ; $prev_cmd_failed

    (
	$starting_step "remove source"
	cd "$DATADIR"
	[ -x hw.c ]
	$skip_step_if_already_done; set -e
	rm hw.c
    )
) ; $prev_cmd_failed
(
    $starting_step "run binary"
    [ -f "$DATADIR/result" ]
    $skip_step_if_already_done; set -e
    "$DATADIR/hw" | tee "$DATADIR/result"
) ; $prev_cmd_failed
