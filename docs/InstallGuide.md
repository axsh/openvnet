
Overview
--------

Welcome to the world of OpenVNet! With this installation guide we help you
create a very simple yet innovative virtual network environment.

![vnet_minimum](https://www.dropbox.com/s/dezarv561fg7sdj/vnet_minimum.png?dl=1)

On a given physical server (here named as server1) there is one virtual network whose network address is 10.100.0.0/24 and 2 virtual machines joining it.


Requirements
------------

### Network Requirements

+ Local Area Network (LAN)
+ Internet connection

Installation
---------

Download the openvnet.repo file and put it to your /etc/yum.repos.d/ directory.

    # curl -o /etc/yum.repos.d/openvnet.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/openvnet.repo

Download the openvnet-third-party.repo file and put it in your /etc/yum.repos.d/ directory.

    # curl -o /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/openvnet-third-party.repo

Install epel-release.

    # rpm -Uvh http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release


Install OpenVNet packages.

    # yum install -y openvnet


Modify the following section in /etc/openvnet/vnmgr.conf on the vnmgr node.

    node {
      id "vnmgr"
      addr {
        protocol "tcp"
        host "192.168.100.2"
        public ""
        port 9102
      }
    }

- **host** : The private IP address of the vnmgr node.
- **port** : The port number for the ZeroMQ connection. If the vnmgr process is run on the same node as vna o


Modify the following section in /etc/openvnet/vna.conf on the node.

    node {
      id "vna"
      addr {
        protocol "tcp"
        host "192.168.100.2"
        public ""
        port 9103
      }
    }

- **host** : The private IP address of the vna node.
- **port** : The port number for the ZeroMQ connection. If the vna process is run on the same node as vnmgr or webapi, specify a different value from vnmgr and webapi.
- **public** : The public IP address if exist.

The ID (written as `vna`) will be used later to create a database record for a datapath.


Modify the following section in /etc/openvnet/webapi.conf on the webapi node.

    node {
      id "webapi"
      addr {
        protocol "tcp"
        host "192.168.100.2"
        public ""
        port 9101
      }
    }

- **host** : The private IP address of the webapi node.
- **port** : The port number for the ZeroMQ connection. If the webapi process is run on the same node as vnmgr or vna, specify a different value from vnmgr and vna.
- **public** : The public IP address if exist.

Datapath is one of the Linux kernel capabilities behaving similar to the Linux bridge.
Save the following net-script in `/etc/sysconfig/network-scripts` directory as `ifcfg-br0`. However you need to pay attention to several parameters.

* IPADDRESS, NETMASK

The IP address and the netmask of the datapath. Omit them unless IP address is assigned to the datapath.

* datapath-id

The datapath ID that the Open vSwitch will use. Set unique 16 hex digits as you like.

```
DEVICE=br0
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=static
IPADDR=172.16.20.41
NETMASK=255.255.255.0
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

Modify the following section in /etc/openvnet/common.conf on the vnmgr nodes.

    db {
      adapter "mysql2"
      host "localhost"
      database "vnet"
      port 3306
      user "root"
      password ""
    }

- **host** : The IP address of the node running mysqld.
- **database** : The database name.
- **port** : The port number for mysqld. If necessary.
- **user** : The user name for mysqld.
- **password** : The password for mysqld.

Before creating the database, you need to launch the mysql server.

    # service mysqld start

To automatically launch the mysql server, execute the following command.

    # chkconfig mysqld on

Create database

    # mysqladmin -uroot create vnet
    # cd /opt/axsh/openvnet/vnet
    # bundle exec rake db:init

To insert the database records use `vnctl`

```
# cd /opt/axsh/openvnet/vnctl
# bundle install --path vendor/bundle
```

Start vnmgr and webapi since `vnctl` is just a webapi client.

    # initctl start vnet-vnmgr
    # initctl start vnet-webapi

From now on you need to create a couple of database records to launch your OpenVNet environment.

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
# ./vnctl networks add --uuid nw-test1 --display-name testnet1 --ipv4-network 10.100.0.0 --ipv4-prefix 24 --network-mode virtual
```

* ipv4-network

The IPv4 network address.

* ipv4-prefix

The IPv4 network prefix. (default 24)

* network-mode

The mode of the network to create. Use `virtual` in case of creating virtual network.

#### Interface

```
# ./vnctl interfaces add --uuid if-inst1 --mode vif --owner-datapath-uuid dp-test1 --mac-address 10:54:ff:00:00:01 --network-uuid nw-vnet1 --ipv4-address 10.100.0.10 --port-name inst1
# ./vnctl interfaces add --uuid if-inst2 --mode vif --owner-datapath-uuid dp-test1 --mac-address 10:54:ff:00:00:02 --network-uuid nw-vnet1 --ipv4-address 10.100.0.11 --port-name inst2
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

OpenVNet needs to know which port of the Open vSwitch is associated to the database. You can see what is attached by `ovs-vsctl show`.

```
fbe23184-7f14-46cb-857b-3abf6153a6d6
    Bridge "br0"
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: standalone
        Port "br0"
            Interface "br0"
                type: internal
```

There are 2 ports named as inst1 and inst2 on the example output above. They are must be the same
as the parameter `port-name`.


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
