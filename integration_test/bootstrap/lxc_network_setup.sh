#!/bin/bash

function render_mgr () {
    local lxc_name="${1}"
cat <<EOS >> ${interface_setup}
cat <<EOF > /var/lib/lxc/${lxc_name}/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
TYPE=Ethernet
EOF
EOS
}

function render_virt () {
    local lxc_name="${1}" ip="${2}"
cat <<EOS >> ${interface_setup}
cat <<EOF > /var/lib/lxc/${lxc_name}/rootfs/etc/sysconfig/network-scripts/ifcfg-eth1
DEVICE=eth1
BOOTPROTO=static
ONBOOT=yes
TYPE=Ethernet
IPADDR=${ip}
NETMASK=255.255.255.0
EOF
EOS
}

function render_nw () {
    local lxc_name="${1}"
cat <<EOS >> ${interface_setup}
cat <<EOF > /var/lib/lxc/${lxc_name}/rootfs/etc/sysconfig/network
NETWORKING=yes
HOSTNAME=${lxc_name}
EOF
EOS
}

function net_setup {
    tp=$1
    hw=$2

    cat <<EOF
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = ${tp}
lxc.network.hwaddr = ${hw}
EOF
}

function net_info {
    local file=$1
    local lxc_name=$2

    while read -r br tp hw ip; do
        net_setup $tp $hw
        [[ $tp == *m* ]] && render_mgr ${lxc_name}
        [[ $tp == *v* ]] && render_virt ${lxc_name} ${ip}
    done < ${file}

    render_nw ${lxc_name}
}

function finish_config_file {
    lxc_name=$1

    cat << EOF
lxc.rootfs = /var/lib/lxc/${lxc_name}/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = ${lxc_name}
lxc.autodev = 0
EOF
}

function lxc_setup {
    local ifname=${1} brname=${2} script_file_on_vm=${3}

    cat << EOF

echo ovs-vsctl --if-exists del-port ${brname} ${ifname} >> ${script_file_on_vm}
echo ovs-vsctl add-port ${brname} ${ifname} >> ${script_file_on_vm}
EOF

}

##################################################################

if [ $# -ne 1 ]; then
   echo "$0  vm_name"
   exit 2
fi
vmdir=$1


if [ ! -e ${vmdir}/metadata/lxc ]; then
    echo "No lxc dir..."
    exit 1
fi

script_file_list_str=""

# Add the interfaces to contaiers network-scripts
interface_setup=${vmdir}/tmp.interface_setup.sh

# Configure the containers and initialize openvswitch
lxc_setup_provisioner=${vmdir}/tmp.lxc_setup.sh

# Run the generated scripts on start up
vm_bash_init=${vmdir}/tmp.bash_init.sh

/bin/rm -r ${lxc_setup_provisioner}
/bin/rm -f ${interface_setup}
/bin/rm -f ${vm_bash_init}

## Assumption here: Only files giving lxc container info. are in this dir!
for container in `ls ${vmdir}/metadata/lxc`; do
    container_cfg=${vmdir}/tmp.${container}.config.sh
    /bin/rm -f ${container_cfg}

    # generate container config
    {
        echo '#!/bin/bash'
        echo "cat > /var/lib/lxc/${container}/config << 'EOF'"
        net_info ${vmdir}/metadata/lxc/${container}/network.info ${container}
        finish_config_file ${container}
        echo "EOF"
        echo "mkdir -p /var/lib/lxc/${container}/rootfs/root/.ssh"
        echo "cp ~/.ssh/authorized_keys /var/lib/lxc/${container}/rootfs/root/.ssh/"
    } >> ${container_cfg}

    # generate initialization script
    {
        if_data="$(cat ${vmdir}/metadata/lxc/${container}/network.info)"
        script_file_on_vm=/root/lxc_setup.sh
        echo "echo lxc-start -n ${container} -d  2>/dev/null >> ${script_file_on_vm}"
        echo "echo sleep 10 >> ${script_file_on_vm}"
        for iface in ${if_data[@]} ; do
            [[ $iface =~ ^br ]] && br=${iface}
            [[ $iface =~ ^if ]] && {
                lxc_setup ${iface} ${br} ${script_file_on_vm}
                unset br
            }
        done
    } >> ${lxc_setup_provisioner}

    script_file_list_str="${script_file_list_str},${container_cfg}"
done

cat << EOF > ${vm_bash_init}
#!/bin/bash
sudo echo 'chmod +x  /root/lxc_setup.sh' >> /etc/rc.d/rc.local
sudo echo /root/lxc_setup.sh >> /etc/rc.d/rc.local
EOF

script_file_list_str="${script_file_list_str},${interface_setup},${lxc_setup_provisioner},${vm_bash_init}"

echo ${script_file_list_str#,}
