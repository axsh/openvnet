# Single network with DHCP server

## Overview

This document expects you to have set up OpenVNet according to the [installation guide](installation). We will be referring to the VMs `inst1` and `inst2` As they've been set up in there.

### Remove the IP addresses from LXC's config

Open the files `/var/lib/lxc/inst1/config` and `/var/lib/lxc/inst2/config`. Find the lines that start with `lxc.network.ipv4` and either remove them or comment them out.

We are going to start using OpenVNet's built-in DHCP service to assign IP addresses so we no longer need to rely on LXC to do it for us.

```
vi /var/lib/lxc/inst1/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst1
# lxc.network.ipv4 = 10.100.0.10
lxc.network.hwaddr = 10:54:FF:00:00:01
lxc.rootfs = /var/lib/lxc/inst1/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst1
lxc.autodev = 0

```

```
vi /var/lib/lxc/inst2/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst2
# lxc.network.ipv4 = 10.100.0.11
lxc.network.hwaddr = 10:54:FF:00:00:02
lxc.rootfs = /var/lib/lxc/inst2/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst2
lxc.autodev = 0
```

### Create a simulated interface

OpenVNet will simulate DHCP without actually starting up a server. Everything will be handled using flows in Open vSwitch. However, the machines attached to OpenVNet's virtual networks will still expect a DHCP server to exist with a certain IP address. Therefore we need to tell OpenVNet to create a simulated interface that will give off the illusion of a real DHCP server.

```
vnctl interfaces add \
  --uuid if-dhcp \
  --mode simulated \
  --owner-datapath-uuid dp-test1 \
  --mac-address 02:00:00:00:01:11 \
  --network-uuid nw-test1 \
  --ipv4-address 10.100.0.100
```

### Create the DHCP service

Now that we have a simulated interface in place, all we have to do is tell OpenVNet to simulate a DHCP service on it.

```
vnctl network-services add --uuid ns-dhcp --interface-uuid if-dhcp --type dhcp
```
