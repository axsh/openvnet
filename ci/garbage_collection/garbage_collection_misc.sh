#!/bin/bash 


function remove_dir {
    dir_to_rm=$1

    ## "master" and "develop" dirs. should NEVER be removed
    ## "packages" are built separately when new versions are released and should thereore be left.
    short_name=${dir_to_rm%/}     # Remove any trailing '/'
    short_name=${short_name##*/}  # Remove everything up to and including the last '/'
    for no_rm in "master" "develop" "packages"; do
       if [[ "${short_name}" = "${no_rm}" ]]; then
           echo "Cannot remove \"${no_rm}\". Ignoring."
           return 0
       fi
    done

    echo "rm -rf ${dir_to_rm}"
    rm -rf ${dir_to_rm}

}


