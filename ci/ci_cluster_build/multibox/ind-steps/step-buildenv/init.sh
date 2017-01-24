
check_dep "tar"
check_dep "rsync"
check_dep "brctl"
check_dep "qemu-system-x86_64"
check_dep "parted" # For mount-partition.sh

for box in ${BOXES} ; do
    download_seed_image "${box}"
done

create_bridge "vnet-itest0"
create_bridge "vnet-itest1"

create_bridge "vnet-wanedge" "10.210.0.1/24"
create_bridge "vnet-br0" "${GATEWAY}/${PREFIX}"
