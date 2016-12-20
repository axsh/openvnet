#!/bin/bash


function generate_on_box () {
    local file="${1}"

    cat <<EOF > /etc/openvnet/${file}
$(cat $file) 
EOF

}

vm_name="${1}"

if [ $# -ne 1 ]; then
   echo "$0  vm_name"
   exit 2
fi


if [ ! -e ${vm_name}/metadata/openvnet ]; then
    echo "No openvnet dir..."
    exit 1
fi

script_file_list_str=""

exec_file="${vm_name}/metadata/tmp.openvnet_setup.sh"

{
    echo "echo mkdir -p /etc/openvnet"
    for ovn_conf in $(ls ${vm_name}/metadata/openvnet) ; do
        generate_on_box ${ovn_conf}
    done
} >> "${exec_file}"

script_file_list_str="${exec_file}"

echo ${script_file_list_str#,}
