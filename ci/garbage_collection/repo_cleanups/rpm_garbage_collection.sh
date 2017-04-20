#!/bin/bash

set -ex

. ../garbage_collection_misc.sh
. ../prune_branches.sh

time_limit=14   ## Days. Set this to give the "deadline". 
                ## All branches older than this a removed.

rpm_base_dir=/var/www/html/repos

## Remove all directories whose branch (on git) no longer exists
## or which has not beenm pushed to within $time_limit days.
for directory in $(TIME_LIMIT=${time_limit} dirs_to_prune ${rpm_base_dir}); do
   remove_dir ${rpm_base_dir}/${directory}
done
 
## Now delete "old" (> ${time_limit} days) rpm's from the develop directory

here=$PWD

for rhel_version in 6 7 ; do
    (
        cd ${rpm_base_dir}/develop/packages/rhel/${rhel_version}/
        current=$(readlink current)
        if [[ -z ${current} ]]; then
            echo "No 'current' symlink in develop! "
            continue                # There is no "current" symlink. Don't remove anything!
        fi
        echo "'current' rpm repo is ${current}"

        readlink current
        current=${current##*\/}

        cutoff_date=$(get_cutoff_date)

        echo "Checking for stale rpm repos under develop..."
        for directory in $(ls -d 2*); do
            dr=${directory}
            rpmdate=${dr:0:8}     # yyyymmddgitxxxx is the rpm repo directory format

            if [[ "${dr}" = "${current}" ]]; then
                continue
            fi

            if [[ "${rpmdate}" < "${cutoff_date}" ]]; then
                remove_dir "${rpm_base_dir}/develop/packages/rhel/${rhel_version}/${dr}"
            fi
        done
    )
done

exit 0   ## Explicit notice: We are done.
