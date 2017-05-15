#!/bin/bash     

set -e
set -o pipefail

###+
#
#     This file is intended to serve as a "library" to
#  be used to locate and remove directories based on
#  the existing branch structure for a git repository.
#  Directory names are assumed to be named directly after
#  a relevant git branch. Directories for which the  git 
#  branch is no longer active are removed. "No longer 
#  active" here means either the git branch no longer
#  exists or the git branch (if it still exists) has not
#  had a commit in a given period of time. The default
#  period of time is 2 weeks, but it may be cahanged
#  via the user defining a TIME_LIMIT environment
#  variable.
#
###-


## Days. Repos. older than this are removed (unless the repo. is 'current')
time_limit=${TIME_LIMIT:-14}

echo "Will prune all branches not commited to in the past ${time_limit} days."

function git_query {
    git for-each-ref --sort=-committerdate refs/remotes --format='%(refname), %(committerdate:short)'
}

function get_cutoff_date {
    date -d "-${time_limit} days" +%Y%m%d
}

# This routine will fail ingloriously if it is not run inside a git repository!
function active_git_branches {

    cutoff_date=$(get_cutoff_date)
    git_query | while IFS= read -r branch; do
        branch=${branch##*/}      ## Remove everything up to and including the last '/'
                                  ## (Directory names are assumed to match the branch name
                                  ## only, without any leading path names. origin/, etc.)

        bname=$(echo ${branch} | cut -d, -f1)
        commit_date=$(echo ${branch} | cut -d, -f2 | sed -e 's/-//g')

        if [[ "${commit_date}"  <  "${cutoff_date}" ]]; then
            break      # break: The git command sorts by date. Once we reach here, all
        fi             #        further dates will also extend beyond the cutoff date. 
        echo "${bname}"
    done

}

function dirs_to_prune {

    base_directory=${1?No base directory name passed to dirs_to_prun function.}

    active_branches=$(active_git_branches)
    if [[ -z "${active_branches}" ]]; then
        exit 1
    fi

    ls -1 ${base_directory} | comm -23 - <(printf "%s\n" "${active_branches}" | sort)

}
