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
cat <<EOF > /var/lib/lxc/${lxc_name}/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
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
    out=$1
    tp=$2
    hw=$3

    cat <<EOF >> ${out}
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = ${tp}
lxc.network.hwaddr = ${hw}
EOF
}

function net_info {
    local file=$1
    local ofile=$2
    local lxc_name=$3

    while read -r br tp hw ip; do
        net_setup ${ofile} $tp $hw
        [[ $tp == *m* ]] && render_mgr ${lxc_name}
        [[ $tp == *v* ]] && render_virt ${lxc_name} ${ip}
    done < ${file}

    render_nw ${lxc_name}
}

function finish_config_file {
    file=$1
    lxc_name=$2

    cat << EOF >> ${file}
lxc.rootfs = /var/lib/lxc/${lxc_name}/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = ${lxc_name}
lxc.autodev = 0
EOF
}

function lxc_setup {
    prov_script_file=$1
    container=${2}
    ifname=${3}
    brname=${4}

    script_file_on_vm=/root/lxc_setup.sh

cat >> ${prov_script_file} << EOF

echo "lxc-start -n ${container} -d  2>/dev/null" >> ${script_file_on_vm}

# Give the container time to start up
echo "sleep 10" >> ${script_file_on_vm}

echo "ovs-vsctl del-port ${brname} ${ifname} 2>/dev/null " >> ${script_file_on_vm}
echo "ovs-vsctl add-port ${brname} ${ifname}" >> ${script_file_on_vm}
EOF

#   echo ${prov_script_file}

}

function setup_root_bashinit {

    prov_script_name=$1
    bash_file=/root/.bash_profile

cat << EOF > ${prov_script_name} 
#!/bin/bash
sudo echo 'chmod +x  /root/lxc_setup.sh' >> ${bash_file}
sudo echo /root/lxc_setup.sh >> ${bash_file}
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
interface_setup=${vmdir}/tmp.interface_setup.sh
lxc_setup_provisioner=${vmdir}/tmp.lxc_setup.sh
/bin/rm -r ${lxc_setup_provisioner}
/bin/rm -f ${interface_setup}
echo "#!/bin/bash > ${script_file_on_vm}" > ${lxc_setup_provisioner}
## Assumption here: Only files giving lxc container info. are in this dir!
for container in `ls ${vmdir}/metadata/lxc`; do

   outfile=${vmdir}/tmp.${container}.config.sh
   /bin/rm -f ${outfile}

   echo '#!/bin/bash' > ${outfile}
   echo "cat > /var/lib/lxc/${lxc}/config << 'EOF'" >> ${outfile}

   net_info ${vmdir}/metadata/lxc/${container}/network.info ${outfile} ${container}

   finish_config_file ${outfile} ${container}

   echo "EOF" >> ${outfile}

   script_file_list_str="${script_file_list_str},${outfile}"
   if_data="$(cat ${vmdir}/metadata/lxc/${container}/network.info)"
   br=""
   for l in ${if_data[@]} ; do
       [[ $l =~ ^br ]] && br=${l}
       [[ $l =~ ^if ]] && {
           lxc_setup ${lxc_setup_provisioner} ${container} ${l} ${br}
       }
   done
   echo "mkdir -p /var/lib/lxc/${container}/rootfs/root/.ssh" >> ${outfile}
   echo "cp ~/.ssh/authorized_keys /var/lib/lxc/${container}/rootfs/root/.ssh/" >> ${outfile}
done

vm_bash_init=${vmdir}/tmp.bash_init.sh         # File to modify the .bash_profile file on the vm.
                                               # This is needed to run lxc startup scripts & bridge-connecting
setup_root_bashinit ${vm_bash_init}
script_file_list_str="${script_file_list_str}",${interface_setup}
script_file_list_str="${script_file_list_str}",${lxc_setup_provisioner},${vm_bash_init}

echo ${script_file_list_str#,}
