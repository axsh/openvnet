#!/bin/bash


###+
#    Simple script designed to look for ifcfg-eth* files
# in a directory and generate a template line for a packer
# template file. The template line is used by packer to
# run VBoxManage to create a NIC for the given eth* file.
# Note that no NIC card needs to be created for eth0!
#
# Usage: generate_niclist.sh dirname
#
# dirname gives the directory with the ifcfg-eth* files. 
###-

if [ $# -ne 1 ]; then
   echo
   fname=`basename $0`
   echo "   ${fname} ifcfg_dir"
   echo
   exit 1
fi

fdir=$1

# Find the highest-numbered ifcfg-eth<N> file and return <N>
function max_eth {
    local dirname=$1

    here=$PWD
    there=${dirname}

    cd ${there}

#   ls ifcfg-eth* 2>/dev/null

    if [ $? -ne 1 ]; then
       # Note that if the directory contains up to eth10 (or more) the logic fails! (The sort is lexicographic.)
       var=`ls -r ifcfg-eth*  | head -1 | cut -d- -f2`   # ls the ifcfg-eth* files in reverse sorted order,
                                                         # keep only the first/top (highest-numbered) one

       # Lop off the number and return it. (And again -- the logic fails if N>9.)
       echo ${var//[^0-9]/}
    else
       echo 0
    fi

    cd ${here}

}


##################################################################

n=`max_eth ${fdir}`

nic_stub="--nicN"
vagrant_templ_string='["modifyvm", "{{.Name}}", "NIC_STUB", "nat"]'

if [ $n -gt 0 ]; then
    for j in $( seq $n ); do
       nic=${nic_stub//N/$j}
       temp=${vagrant_templ_string//NIC_STUB/${nic}}
       echo "${nic}  -->  ${temp} "
    done
fi 
