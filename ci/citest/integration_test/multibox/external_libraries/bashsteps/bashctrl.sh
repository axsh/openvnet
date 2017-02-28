#!/bin/bash

reportfailed()
{
    echo "Script failed...exiting. ($*)" 1>&2
    exit 255
}
export -f reportfailed


# The following variables are used to set bashsteps hooks, which are
# used to control and debug bash scripts that use the bashsteps
# framework:
export starting_step
export starting_group
export skip_step_if_already_done
export skip_group_if_unnecessary

helper-function-definitions()
{
    prev_cmd_failed()
    {
	# this is needed because '( cmd1 ; cmd2 ; set -e ; cmd3 ; cmd4 ) || reportfailed'
	# does not work because the || disables set -e, even inside the subshell!
	# see http://unix.stackexchange.com/questions/65532/why-does-set-e-not-work-inside
	# A workaround is to do  '( cmd1 ; cmd2 ; set -e ; cmd3 ; cmd4 ) ; prev_cmd_failed'
	(($? == 0)) || reportfailed "$*"
    }
    export -f prev_cmd_failed

    # for consistency, start to use the variable form for everything
    : ${prev_cmd_failed:='eval [ $? = 0 ] || exit 255'}
    export prev_cmd_failed
}
    
null-definitions()
{
    # The simplest bashsteps hook possible is ":", which just lets
    # control passthru the hooks without any effect. ("" will not work
    # because hooks can be invoked with parameter, and the null
    # operation must ignore the parameters.)  In general, a script
    # starting from a clean environment should run correctly with null
    # definitions, because running the script will traverse all steps,
    # and the steps should already be ordered so that steps that
    # require preconditions are always run after steps that establish
    # the same preconditions.
    
    : ${starting_step:=":"}
    : ${starting_group:=":"}
    : ${skip_step_if_already_done:=":"}
    : ${skip_group_if_unnecessary:=":"}
}


# This set of definitions is probably the simplest where all four hooks
# serves a purpose.
optimized-actions-with-terse-output-definitions()
{
    # This is a complete set of hook definitions that lets the script
    # run through and complete all not-yet-done actions.  For each
    # individual steps, it lets the check part run, and if the checks
    # succeed, it skips the action portion.  A status line for each
    # step is sent to stdout after the checks and before the actions.
    # The status line is indented in org-mode style to reflect the
    # outline depth computed by the group hooks.  At the start of each
    # group, a status line is immediately sent to stdout.  Then the
    # check for the group (if any) are done and if the check succeed,
    # the rest of the group (and any groups or steps inside) are
    # completely skipped.  Therefore, for some steps it is possible
    # that none of the hooks are touched.

    : ${starting_step:=just_remember_step_title}  # OPTIONAL
    : ${skip_step_if_already_done:=output_title_and_skipinfo_at_outline_depth} # REQUIRED

    : ${starting_group:=remember_and_output_group_title_in_outline} # REQUIRED
    : ${skip_group_if_unnecessary:=maybe_skip_group_and_output_if_skipping} # OPTIONAL

    export BASHCTRL_DEPTH=1
    export BASHCTRL_INDEX=1
    just_remember_step_title() # for $starting_step
    {
	# This hook appears at the start of a step, so defining the
	# step title here lets the title appear at the start of the
	# step in the source code.  However, during execution it is
	# desirable to display other information that is not available
	# yet along with the title.  Therefore this step only
	# remembers the title in a variable.  It can assume that the
	# hook for $skip_step_if_already_done will output the title,
	# because that hook is required and all code between this hook
	# and the "skip_step" hook must execute without side effects
	# or terminating errors.
	parents=""
	[[ "$BASHCTRL_INDEX" == *.* ]] && parents="${BASHCTRL_INDEX%.*}".
	read nextcount <&78
	leafindex="${BASHCTRL_INDEX##*.}"
	BASHCTRL_INDEX="$parents$nextcount"

	export step_title="$BASHCTRL_INDEX-$*"
	$starting_step_extra_hook
    }
    export -f just_remember_step_title

    output_title_and_skipinfo_at_outline_depth() # for $skip_step_if_already_done
    {
	# This hook implements the step skipping functionality plus
	# adds minimal output.  It reads the error code from the
	# checking code and if it shows success (rc==0), then it
	# assumes that the step has already been done and that it can
	# be skipped.  It assumes $step_title has already been set.
	# TODO: try to put in useful simple info when $step_title
	# is not set.  It assumes $BASHCTRL_DEPTH is correct.
	if (($? == 0)); then
	    ( set +x
	      outline_header_at_depth "$BASHCTRL_DEPTH"
	    )
	    echo "Skipping step: $step_title"
	    step_title=""
	    exit 0 # i.e. skip (without error) to end of process/step
	else
	    ( set +x
	      echo
	      outline_header_at_depth "$BASHCTRL_DEPTH"
	      echo "DOING STEP: $step_title"
	    )
	    step_title=""
	    $verboseoption && set -x
	fi
    }
    export -f output_title_and_skipinfo_at_outline_depth

    remember_and_output_group_title_in_outline() # for $starting_group
    {
	# This hook remembers the group title in a bash
	# variable and outputs it immediately to the outline log.  The
	# hook is required for groups, and the other group hooks are
	# optional so here is the only (straightforward) place to do
	# such output.  Also, since this hook is required for all
	# groups, here is a reliable place to update the value of
	# $BASHCTRL_DEPTH.
	parents=""
	[[ "$BASHCTRL_INDEX" == *.* ]] && parents="${BASHCTRL_INDEX%.*}".
	read nextcount <&78
	BASHCTRL_INDEX="$parents$nextcount.yyy"
	exec 78< <(seq 1 1000)

	export group_title="${BASHCTRL_INDEX%.yyy}.0-$*"
	( set +x
	  outline_header_at_depth "$BASHCTRL_DEPTH"
	  echo "[[$group_title]]" )
	(( BASHCTRL_DEPTH++ ))
    }
    export -f remember_and_output_group_title_in_outline

    # initialize top level index
    BASHCTRL_INDEX="1"
    exec 78< <(seq 1 1000)
    
    maybe_skip_group_and_output_if_skipping() # for $skip_group_if_unnecessary
    {
	# If the preceding bash statement returns success (rc==0),
	# this hook skips the whole group, including the checks of any
	# of the steps.  This makes sense when executing. (When
	# running the script to collect as much status information as
	# possible, it makes more sense to execute all the steps in
	# the group.)
	if (($? == 0)); then
	    echo "      Skipping group: $group_title"
	    group_title=""
	    exit 0
	else
	    echo ; echo "      DOING GROUP: $group_title"
	    group_title=""
	fi
    }
    export -f maybe_skip_group_and_output_if_skipping

    finished_step=prev_cmd_failed
}

outline_header_at_depth()
{
    depth="$1"
    for (( i = 0; i <= depth; i++ )); do
	echo -n "*"
    done
    echo -n " : "
}
export -f outline_header_at_depth

dump1-definitions()
{
    starting_step=dump1_header
    starting_group=dump1_header
    skip_step_if_already_done='exit 0'
    skip_group_if_unnecessary=':'
    export starting_step
    export starting_group
    export skip_step_if_already_done
    export skip_group_if_already_done

    dump1_header()
    {
	[ "$*" = "" ] && return 0
	step_title="$*"
	echo "** : $step_title  (\$SHLVL=$SHLVL, \$BASH_SUBSHELL=$BASH_SUBSHELL)"
    }
    export -f dump1_header
}
exec 88< <(seq 1 100) # debug counter
quick-definitions()
{
    starting_step=immediately_output_step_title_in_outline
    starting_group=remember_and_output_group_title_in_outline
    skip_step_if_already_done='echo BUG; exit 0'
    skip_group_if_unnecessary=':'
    export starting_step
    export starting_group
    export skip_step_if_already_done
    export skip_group_if_already_done

    immediately_output_step_title_in_outline() # for $starting_step
    {
	# This hook remembers the step title in a bash variable and
	# outputs it immediately to the outline log.  It then
	# immediately exist, so nothing in the step is executed.  For
	# this to work as intended, every step must have a
	# $starting_step hook.
	parents=""
	[[ "$BASHCTRL_INDEX" == *.* ]] && parents="${BASHCTRL_INDEX%.*}".
	read nextcount <&78
	leafindex="${BASHCTRL_INDEX##*.}"
	BASHCTRL_INDEX="$parents$nextcount"

	export step_title="$BASHCTRL_INDEX-$*"
	( set +x
	  outline_header_at_depth "$BASHCTRL_DEPTH"
	  echo "$step_title" )
	read debugcount <&88
	(( debugcount > 8 )) && exit 0
	exit 0 # Move on to next step!
    }
    export -f immediately_output_step_title_in_outline

    # create a counter (up to 1000!) for all subprocesses to share.
    # (seems to be killed automatically by SIGHUP)
}

status-definitions()
{
    # make status safer when used with scripts using old style
    export skip_rest_if_already_done=status_skip_step

    skip_step_if_already_done=status_skip_step

    if $verboseoption; then
	starting_step_extra_hook=extra_for_status
	export starting_step_extra_hook
	
	extra_for_status()
	{
	    (
		set +x
		outline_header_at_depth "$BASHCTRL_DEPTH"
		echo "vvvvvvvvvvvvvvvvv"
	    )
	    set -x
	}
	export -f extra_for_status
    fi

    export skip_whole_tree=''
    skip_group_if_unnecessary='eval (( $? == 0 )) && skip_whole_tree=,skippable'
    
    status_skip_step()
    {
	rc="$?"
	set +x
	outline_header_at_depth "$BASHCTRL_DEPTH"
	echo -n "$step_title"
	if (($rc == 0)); then
	    echo " (DONE$skip_whole_tree)"
	    step_title=""
	else
	    echo " (not done$skip_whole_tree)"
	    step_title=""
	fi
	exit 0 # Always, because we are just checking status
    }
    export -f status_skip_step

    # create a counter (up to 1000!) for all subprocesses to share.
    # (seems to be killed automatically by SIGHUP)
}

filter-definitions()
{
    starting_step=filter_header_step
    starting_group='filter_header_group'
    filter_header_step()
    {
	parents=""
	[[ "$BASHCTRL_INDEX" == *.* ]] && parents="${BASHCTRL_INDEX%.*}".
	read nextcount <&78
	leafindex="${BASHCTRL_INDEX##*.}"
	BASHCTRL_INDEX="$parents$nextcount"

	export step_title="$BASHCTRL_INDEX-$*"
#	echo "$step_title" != $title_glob ,,,,,
	if [[ "$step_title" != $title_glob ]]; then
	    step_title=""
	    exit 0
	fi
	$starting_step_extra_hook
    }
    export -f filter_header_step

    filter_header_group()
    {
	parents=""
	[[ "$BASHCTRL_INDEX" == *.* ]] && parents="${BASHCTRL_INDEX%.*}".
	read nextcount <&78
	BASHCTRL_INDEX="$parents$nextcount.yyy"
	exec 78< <(seq 1 1000)
    }
    export -f filter_header_group
}

do1-definitions()
{
    skip_step_if_already_done=do1_skip_step
    starting_group=':'
    skip_group_if_unnecessary=':'

    do1_skip_step()
    {
	if (($? == 0)); then
	    echo "** DOING STEP AGAIN: $step_title"
	    step_title=""
	else
	    echo ; echo "** DOING STEP: $step_title"
	    step_title=""
	fi
	$verboseoption && set -x
    }
    export -f do1_skip_step
}

thecmd=""
choosecmd()
{
    [ "$thecmd" = "" ] || reportfailed "Cannot override $thecmd with $1"
    thecmd="$1"
}

# status1 and do1 now take the pattern appended to the command
# to make parsing easier. For example:
#   status1-yum   -> give status of all titles matching *yum*.
#   'do1-*Install'  -> do all steps with titles that start with "Install"
glob_heuristics()
{
    [ "$1" = "" ] && reportfailed "A pattern must be appended to the command"
    if [[ "$1" == *\** ]]; then
	# if it already has a glob character, return unchanged
	echo "$1"
    else
	# else wrap so that the fixed string can match anywhere in the title
	echo "*$1*"
    fi
}

cmdline=( )
usetac=false
bashxoption=""
export verboseoption=false
parse-parameters()
{
    while [ "$#" -gt 0 ]; do
	case "$1" in
	    nulldefs | passthru)
		choosecmd "$1"
		;;
	    in-order | debug)
		choosecmd "$1"
		;;
	    quick)
		choosecmd "$1"
		;;
	    status-all | status)
		choosecmd "$1"
		;;
	    status1-*)
		choosecmd "${1%%-*}"
		export title_glob="$(glob_heuristics "${1#status1-}")"
		;;
	    [d]o)
		choosecmd "$1"
		;;
	    [d]o1-*)
		choosecmd "${1%%-*}"
		export title_glob="$(glob_heuristics "${1#do1-}")"
		;;
	    bashx)
		bashxoption='bash -x'
		;;
	    verbose)
		verboseoption=true
		;;
	    *)
		cmdline=( "${cmdline[@]}" "$1" )
		;;
	esac
	shift
    done
}

bashctrl-main()
{
    parse-parameters "$@"
    case "$thecmd" in
	nulldefs | passthru)
	    null-definitions
	    ;;
	in-order | debug)
	    helper-function-definitions
	    optimized-actions-with-terse-output-definitions
	    echo "* An in-order list of steps with bash nesting info.  No attempt to show hierarchy:"
	    dump1-definitions
	    ;;
	quick)
	    helper-function-definitions
	    optimized-actions-with-terse-output-definitions
	    echo "* An in-order list of steps with bash nesting info.  No evaluation of status checks."
	    quick-definitions
	    ;;
	status-all | status)
	    helper-function-definitions
	    optimized-actions-with-terse-output-definitions
	    status-definitions
	    echo "* Status of all steps in dependency hierarchy with no pruning"
	    ;;
	status1)
	    helper-function-definitions
	    optimized-actions-with-terse-output-definitions
	    status-definitions
	    filter-definitions
	    ;;
	[d]o)
	    helper-function-definitions
	    optimized-actions-with-terse-output-definitions
	    ;;
	[d]o1)
	    helper-function-definitions
	    optimized-actions-with-terse-output-definitions
	    do1-definitions
	    filter-definitions
	    ;;
	*)
	    reportfailed "No command chosen"
	    ;;
    esac
    if $usetac; then
	$bashxoption "${cmdline[@]}" | tac
    else
	$bashxoption "${cmdline[@]}"
    fi
}

bashctrl-main "$@"
