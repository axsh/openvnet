# OpenVNet Installation Guide

## Overview


Welcome to the world of OpenVNet! With this installation guide we help you
create a very simple yet innovative virtual network environment.

![vnet_minimum](https://www.dropbox.com/s/dezarv561fg7sdj/vnet_minimum.png?dl=1)

On a given physical server (here named as server1) there is one virtual network whose network address is 10.100.0.0/24 and 2 virtual machines joining it.
The orange circles describe OpenVNet's ruby processes; vna, vnmgr and webapi.
See architecture for more detail of how the OpenVNet works.


## Requirements


### Network Requirements

+ Local Area Network (LAN)
+ Internet connection

## Installation

### Install OpenVNet Packages

Download the openvnet.repo file and put it to your /etc/yum.repos.d/ directory.

    # curl -o /etc/yum.repos.d/openvnet.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/openvnet.repo

Download the openvnet-third-party.repo file and put it in your /etc/yum.repos.d/ directory.

    # curl -o /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/openvnet-third-party.repo

Each repo has the following packages:

* openvnet.repo
  * openvnet (virtual package)
  * openvnet-common
  * openvnet-vna
  * openvnet-vnmgr
  * openvnet-webapi

* openvnet-third-party.repo
  * openvnet-ruby
  * openvswitch

Install epel-release.

    # yum install -y epel-release


Install OpenVNet packages.

    # yum install -y openvnet

`openvnet` is a virtual package. It is equivalent to install `openvnet-common`,
`openvnet-vna`, `openvnet-vnmgr` and `openvnet-webapi` at once.

### Edit Configuration Files

Edit the file `/etc/openvnet/vnmgr.conf`

    node {
      id "vnmgr"
      addr {
        protocol "tcp"
        host "127.0.0.1"
        public ""
        port 9102
      }
    }

Modify the parameters `host` and `public` according to your environment. In order for
the sample environment we leave those parameters as is. The detail of each parameter is
following.

- **id** : The identifier of the OpenVNet's process. For example the paramter `id` in `vnmgr.conf` is applied to the vnmgr process. Specify universally unique string data in the world of the OpenVNet.

- **protocol** : The network protocol that the OpenVNet's processes will use for communication. The default `tcp`.

- **host** : The IP address of the vnmgr node. Since all the processes reside on the same node we use loopback address in this guide.

- **public** : In case the process running in a NAT environment, specify the NAT address as the process can advertise its location.

- **port** : The port number that the process will listen to. Specify a unique port number and make sure the port number is different for each of the OpenVNet's processes and also not taken by any other process.

`/etc/openvnet/vna.conf` and `/etc/openvnet/webapi.conf` have the same structure as `vnmgr.conf`. Edit them if necessary otherwise leave them as is for the sample environment we are just creating. However the `id` parameter in `vna.conf`, we need it for the database configuration so please remember what you specified.

### Setup Local Infrastructure

Datapath is one of the Linux kernel capabilities behaving similar to the Linux bridge.
Create the file `/etc/sysconfig/network-scripts/ifcfg-br0` with the following contents. However you need to pay attention to several parameters.

* datapath-id

The datapath ID that the Open vSwitch will use. Set unique 16 hex digits as you like.

```
DEVICE=br0
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=static
HOTPLUG=no
OVS_EXTRA="
 set bridge     ${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     ${DEVICE} other_config:disable-in-band=true --
 set bridge     ${DEVICE} other-config:datapath-id=0000aaaaaaaaaaaa --
 set bridge     ${DEVICE} other-config:hwaddr=02:01:00:00:00:01 --
 set-fail-mode  ${DEVICE} standalone --
 set-controller ${DEVICE} tcp:127.0.0.1:6633
"
```

Start `openvswitch` service and `ifup` the datapath.

```
# service openvswitch start
# ifup br0
```

Start redis

```
# service redis start
```

### Setup Database

Edit `/etc/openvnet/common.conf` if necessary. The sample environment uses the default settings.

Launch mysql server.

    # service mysqld start

To automatically launch the mysql server, execute the following command.

    # chkconfig mysqld on

Set `PATH` environment variable as following since the OpenVNet uses its own ruby binary.

```
# PATH=/opt/axsh/openvnet/ruby/bin:${PATH}
```

Create database

```
# cd /opt/axsh/openvnet/vnet
# bundle exec rake db:create
# bundle exec rake db:init
```

We use `vnctl` to create database records.

```
# cd /opt/axsh/openvnet/vnctl
# bundle install --path vendor/bundle
```

Start vnmgr and webapi.

```
# initctl start vnet-vnmgr
# initctl start vnet-webapi
```

Subsequent database records are required for the sake of the sample environment.

#### Datapath

```
# ./bin/vnctl datapaths add --uuid dp-test1 --display-name test1 --dpid 0x0000aaaaaaaaaaaa --node-id vna
```

* dpid

The datapath ID specified in `/etc/sysconfig/network-scripts/ifcfg-br0`

* node-id

The ID of the vna written in `/etc/openvnet/vna.conf`


#### Network

```
# ./bin/vnctl networks add --uuid nw-test1 --display-name testnet1 --ipv4-network 10.100.0.0 --ipv4-prefix 24 --network-mode virtual
```

* ipv4-network

The IPv4 network address.

* ipv4-prefix

The IPv4 network prefix. (default 24)

* network-mode

The mode of the network to create. Use `virtual` in case of creating virtual network.

#### Interface

```
# ./bin/vnctl interfaces add --uuid if-inst1 --mode vif --owner-datapath-uuid dp-test1 --mac-address 10:54:ff:00:00:01 --network-uuid nw-test1 --ipv4-address 10.100.0.10 --port-name inst1
# ./bin/vnctl interfaces add --uuid if-inst2 --mode vif --owner-datapath-uuid dp-test1 --mac-address 10:54:ff:00:00:02 --network-uuid nw-test1 --ipv4-address 10.100.0.11 --port-name inst2
```

* mode

The mode of the interface. `vif` must be specified if a virtual machine is supposed to have this.

* owner-datapath-uuid

The UUID of the datapath to which this interface will be connected.

* mac-address

The MAC address of an interface of a virtual machine.

* network-uuid

The UUID of the virtual network to participate

* ipv4-address

The IPv4 address which will be assigned to the network interface.

* port-name

OpenVNet associates an Open vSwitches port with a database record of the interface table if its `port-name` is corresponded to what you can see by `ovs-vsctl show`.


Start vna

```
# initctl start vnet-vna
```

OpenVNet writes its logs in the /var/log/openvnet directory. If there's a problem starting any of the services, you can find its log files there.

If it launches vna successfully you can see `is_connected: true` by `ovs-vsctl show` such as following.

```
fbe23184-7f14-46cb-857b-3abf6153a6d6
    Bridge "br0"
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
```

This means the OpenFlow controller which is vna is now connected to the datapath. After the connection between the OpenFlow controller and the
datapath is established it starts installing the flows on the datapath. You can see the flows by `vnflows-monitor`.

```
# cd /opt/axsh/openvnet/vnet/bin
# ./vnflows-monitor
```

It may require you to setup `PATH` environment variable to find ruby binary. OpenVNet uses its own ruby binary which is in `/opt/axsh/openvnet/ruby/bin` directory.

Verification
-------

By following all the instructions in the previous section, you already have the simple OpenVNet environment. In this section we are going to see network packets going through OpenFlow rules to reach
from one LXC guest to another.

Create 2 LXC guests

```
# lxc-create -t centos -n inst1
# lxc-create -t centos -n inst2
```

Configure interfaces of each guest

```
# vi /var/lib/lxc/inst1/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst1
lxc.network.ipv4 = 10.100.0.10
lxc.network.hwaddr = 10:54:FF:00:00:01
lxc.rootfs = /var/lib/lxc/inst1/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst1
lxc.autodev = 0
```

```
# vi /var/lib/lxc/inst2/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst2
lxc.network.ipv4 = 10.100.0.11
lxc.network.hwaddr = 10:54:FF:00:00:02
lxc.rootfs = /var/lib/lxc/inst2/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst2
lxc.autodev = 0
```

Make sure that the IPv4 address and MAC address are the same as what you specify when you create interface
database records.

Launch the LXC guests then enslave the tap interfaces to the datapath.

```
# lxc-start -d -n inst1
# lxc-start -d -n inst2

# ovs-vsctl add-port br0 inst1
# ovs-vsctl add-port br0 inst2
```

Log in to the inst1 to see if the IP address is assigned properly.

```
# lxc-console -n inst1
# ip a
```

ping to inst2

```
# ping 10.100.0.11
```

Meanwhile you can see which flows are selected by `vnflows-monitor`.

```
# ./vnflows-monitor c 0 d 1
```


---------------------------------------------------------------------

# License

Copyright (c) Axsh Co. Components included are distributed under LGPL 3.0
