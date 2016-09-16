#!/bin/bash -x
#
#
#

if [ $# -ne 3 ]; then
  echo "  `basename $0` base  vm_name ovfdir"
  echo
  echo "  base=6.8 or 7.2 "
  exit 1
fi

base=$1
box_base=centos-${base}
vm_name=$2
ovfdir=$3

##############################################################

ovf_file=${ovfdir}/box.ovf

### Packer templating

template_file="centos-"${base}.json


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
  "post-processors": [
    {
      "output": "builds/${box_base}.{{.Provider}}.box",
      "type": "vagrant"
    }
  ],
  "provisioners": [
    {
      "execute_command": "echo 'vagrant' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'",
      "scripts": [
        "scripts/networking.sh",
        "scripts/vagrant.sh",
        "base.sh"
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

echo "packer build  ${template_file} "
packer build  ${template_file}

if [ $? -ne 0 ]; then
  exit 1
fi

#rm ${template_file}
exit 0

