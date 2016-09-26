#!/bin/bash   # -x
#
#
#

if [ $# -ne 4 ]; then
  echo "  `basename $0` base  vm_name ovfdir machine_dir"
  echo
  echo "  base=6.8 or 7.2 "
  exit 1
fi

base=$1
box_base=centos-${base}
vm_name=$2
ovfdir=$3
machine_dir=$4

##############################################################

#ovf_file=${ovfdir}/box.ovf


### Packer templating
function packer_template {

    local ovf_file=$1
    local vm_name=$2
    local script_files=$3
    local template_file=$4 

###+
#   This vulgarity is needed since packer requires each
# provisioning script file name to be specified on its
# own line. The list is input here as a comma-separated
# list. Change the commas to '\n', do `echo -e ${script_files}`.
# Alas, scripting does often unleash such unpleasantness.
###-
    script_files=${script_files//,/\",'\n'\"}

#   template_file="centos-"${base}.json

    cat > ${template_file} << EOF
{
  "builders": [
    {
      "boot_wait": "10s",
      "guest_additions_path": "VBoxGuestAdditions_{{.Version}}.ovf",
      "headless": "",
      "http_directory": "http",
      "output_directory": "packer-${vm_name}-virtualbox",
      "shutdown_command": "echo 'vagrant' | sudo -S shutdown -P now",
      "ssh_password": "vagrant",
      "ssh_port": 22,
      "ssh_username": "vagrant",
      "ssh_wait_timeout": "10000s",
      "type": "virtualbox-ovf",
      "source_path": "${ovf_file}",
      "virtualbox_version_file": ".vbox_version",
      "vm_name": "${vm_name}"
    }
  ],
  "provisioners": [
    {
      "execute_command": "echo 'vagrant' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'",
      "scripts": [
        "packer_scripts/networking.sh",
        "packer_scripts/vagrant.sh",
        "`echo -e ${script_files}`"
      ],
      "type": "shell"
    }
  ],
  "variables": {
    "build_timestamp": "{{isotime \"20060102150405\"}}",
    "headless": "",
    "version": "2.1.TIMESTAMP"
  }
}

EOF

echo "Created ${template_file}..."

}  ### End, function packer_template

script_file_list="`./make_network_template_files.sh ${machine_dir}`"

template_file="centos-"${base}.json
packer_template  ${ovfdir}/box.ovf  ${vm_name}  ${script_file_list} ${template_file}

if [ ! -e ${template_file} ]; then
    echo "Template file ${template_file} not found!"
    exit 1
fi

echo "packer build  ${template_file} "




      exit 2






packer build  ${template_file}

if [ $? -ne 0 ]; then
  exit 1
fi

#rm ${template_file}
exit 0

