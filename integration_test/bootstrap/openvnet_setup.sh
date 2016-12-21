#!/bin/bash


function generate_on_box () {
    local file="${1}"
    local location="${2}"

    cat <<EOF
cat << "CFG" > /etc/${location}/${file}
$(cat ${vm_name}/metadata/openvnet/${file})
CFG
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

exec_file="${vm_name}/tmp.openvnet_setup.sh"
/bin/rm -r ${exec_file}

{
    echo "echo mkdir -p /etc/openvnet"
    for file in $(ls ${vm_name}/metadata/openvnet) ; do
        [[ "${file}" == *".conf" ]] && location="openvnet" || location="default"
        generate_on_box "${file}" "${location}"
    done

} >> "${exec_file}"

script_file_list_str="${exec_file}"

echo ${script_file_list_str#,}
