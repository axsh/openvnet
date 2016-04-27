# interfaces add

This page explains the arguments used by the `vnctl interfaces add` command in the [Single network](../creating-virtual-networks/single-network)) guide.

```bash
vnctl interfaces add \
  --uuid if-inst1 \
  --mode vif \
  --owner-datapath-uuid dp-test1 \
  --mac-address 10:54:ff:00:00:01 \
  --network-uuid nw-test1 \
  --ipv4-address 10.100.0.10 \
  --port-name inst1
```

* uuid

A unique ID that will be used to refer to this interface.

* mode

The mode of the interface. An entry with `vif` mode is basically means that this is a network interface that will be connected to one of OpenVNet's virtual networks.

* owner-datapath-uuid

The UUID of the datapath to which this interface will be connected. We created this datapath back in the [installation guide](../installation).

* mac-address

The MAC address of the network interface of the virtual machine.

* network-uuid

The UUID of the virtual network to participate

* ipv4-address

The IPv4 address which will be assigned to the network interface.

* port-name

Typically there are multiple network interfaces connected to Open vSwitch. OpenVNet needs to know which one we are describing here. That's where `port-name` comes in. This needs to be the same as this interface's port name on Open vSwitch. You can see the ports currently connected to Open vSwitch by running `ovs-vsctl show`.
