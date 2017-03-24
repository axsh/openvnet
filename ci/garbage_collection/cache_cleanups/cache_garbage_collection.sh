#!/bin/bash 


    
. ../garbage_collection_misc.sh
. ../prune_branches.sh

time_limit=14     ## Days. Set this to give the "deadline". All
                  ## branches older than this will be removed.

cache_location_dir=/data/openvnet-ci/branches


###################################################################################

## main()


## Remove all directories whose branch (on git) no longer exists
## or which has not beenm pushed to within $time_limit days.
for directory in $(TIME_LIMIT=${time_limit} dirs_to_prune ${cache_location_dir}); do

   group_owner=$(stat -c %G ${cache_location_dir}/${directory})
   if [[ "${group_owner}" = "root" ]]; then
       echo "${directory} is owned by root. Cannot remove!"
   else
       remove_dir ${cache_location_dir}/${directory}
   fi
done
