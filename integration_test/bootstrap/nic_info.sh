#!/bin/bash  #  -x


###+
#    Given a directory containing a file named 'nic.info', 
# generates a list of strings defining VBoxManage commands
# to setup a nic of the given type, attached to the given
# host adapter/bridge.
#
# nic.info is expected to be of the form:
# 
# ethN  nic_type  host_connection
# ethN  nic_type  host_connection
# ethN  nic_type  host_connection
#
# Here, nic_type is a type name recognized by virtualbox.
# This will typically be 'hostonly' or 'nat'. The
# host_connection gives the bridge on the host to
# which the nic should be connected.
# 
# !! Important !! 
#
# The order of the ethN devices is important! eth0 should
# always be given first -- it is device "nic1" as far
# as virtualbox is concerned. 
# 
#
# Usage: nic_info.sh dirname
#
# dirname gives the directory with the nic.info file. 
###-

if [ $# -ne 1 ]; then
   echo
   fname=`basename $0`
   echo "   ${fname} nic.info_file_location"
   echo
   exit 1
fi
fdir=$1

nic_info_file=${fdir}/metadata/nic.info
if [ ! -e ${nic_info_file} ]; then
    echo
    echo "nic.info file could not be found in \"${fdir}\""
    exit 2
fi

nic_num=1
nic_cmds=""

while read -r eth type connect_to; do

    nic="--nic${nic_num}"
    if [ "${connect_to}" == "" ]; then 
        attach_string=""
    else
        attach_string=", \"--hostonlyadapter${nic_num}\", \"${connect_to}\",  \"--nicpromisc${nic_num}\", \"allow_all\""
    fi

    vagrant_templ_string="[\"modifyvm\", \"{{.Name}}\", \"${nic}\", \"${type}\"${attach_string}]"
    nic_cmds=${nic_cmds},"${vagrant_templ_string}"

    nic_num=$((nic_num+1))

done < "${nic_info_file}"

echo ${nic_cmds#,}
