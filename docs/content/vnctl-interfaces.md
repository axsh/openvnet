# The interfaces commands explained

Let's take a little time to explain what all the lines in these commands actually mean. Feel free to skip to the [test phase](single-network#test) if you're not interested.

* mode

The mode of the interface. An entry with `vif` mode is basically means that this is a network interface that will be connected to one of OpenVNet's virtual networks.

* owner-datapath-uuid

The UUID of the datapath to which this interface will be connected. We created this datapath back in the installation guide.

* mac-address

The MAC address of the network interface of the virtual machine.

* network-uuid

The UUID of the virtual network to participate

* ipv4-address

The IPv4 address which will be assigned to the network interface.

* port-name

The OpenVNet associates an Open vSwitch's port with a database record of the interface table if its `port-name` is corresponded to what you can see by `ovs-vsctl show`.

