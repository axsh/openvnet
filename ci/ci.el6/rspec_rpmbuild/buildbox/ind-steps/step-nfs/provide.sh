#!/bin/bash

for folder in ${shared_folders[@]} ; do
    [[ -d ${folder} ]] && {
        run_cmd "mkdir -p ${folder}"
        run_cmd "mount 10.100.1.1:${folder} ${folder}"
    }
done
