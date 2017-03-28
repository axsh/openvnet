#!/bin/bash  #  -x


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
   echo "   ${fname} metadata_dir_location"
   echo
   exit 1
fi

fdir=$1

# Find the highest-numbered ifcfg-eth<N> file and return <N>
function max_eth {
    local dirname=$1

    here=$PWD
    there=${dirname}/metadata

    cd ${there}

    # Default case -- the directory has no ifcfg-eth<N> files
    neth=0

    # Check to see if the given directory has any ifcfg-eth* files
    ls ifcfg-eth* &>/dev/null
    if [ $? -eq 0 ]; then
       # Note that if the directory contains up to eth10 (or more) the logic fails! (The sort is lexicographic.)
       var=`ls -r ifcfg-eth*  | head -1 | cut -d- -f2`   # ls the ifcfg-eth* files in reverse sorted order,
                                                         # keep only the first/top (highest-numbered) one
                                                         # ${var} now contains "ethN", where N is the highest numbered file
       # Lop off the number and return it.
#      echo ${var//[^0-9]/}
#      echo ${var#eth}
       neth=${var#eth}
    fi

    cd ${here}

    echo ${neth}
}


##################################################################

n=`max_eth ${fdir}`

nic_cmds=""
if [ $n -gt 0 ]; then

    nic_stub="--nicN"
    vagrant_templ_string='["modifyvm", "{{.Name}}", "NIC_STUB", "nat"]'
    for j in $( seq $n ); do
       j=$((j+1))
       nic=${nic_stub//N/$j}
       temp=${vagrant_templ_string//NIC_STUB/${nic}}
#      echo "${temp}"
       nic_cmds=${nic_cmds},"${temp}"
    done
fi 

echo ${nic_cmds#,}
