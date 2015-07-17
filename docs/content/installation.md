# OpenVNet Installation Guide

## Overview


Welcome to the world of OpenVNet! With this installation guide we help you
create a very simple yet innovative virtual network environment.

![vnet_minimum](https://www.dropbox.com/s/dezarv561fg7sdj/vnet_minimum.png?dl=1)

On a given server (here named as server1) there is one virtual network whose network address is 10.100.0.0/24 and 2 virtual machines joining it.
The orange circles describe OpenVNet's ruby processes; vna, vnmgr and webapi.
See architecture for more details of how the OpenVNet works.


## Requirements

+ Ruby 2.1.1
+ CentOS 6.6
+ Open vSwitch 2.3.1
+ Internet connection

## Installation

### Install OpenVNet Packages

Download the openvnet.repo file and put it to your `/etc/yum.repos.d/` directory.

```bash
curl -o /etc/yum.repos.d/openvnet.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet.repo
```

Download the openvnet-third-party.repo file and put it in your `/etc/yum.repos.d/` directory.

```bash
curl -o /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet-third-party.repo
```

Each repo has the following packages:

* openvnet.repo
  * openvnet (metapackage)
  * openvnet-common
  * openvnet-vna
  * openvnet-vnmgr
  * openvnet-webapi
  * openvnet-vnctl

* openvnet-third-party.repo
  * openvnet-ruby
  * openvswitch

Install epel-release.

```bash
yum install -y epel-release
```


Install OpenVNet packages.

```bash
yum install -y openvnet
```

`openvnet` is a metapackage. It is equivalent to installing `openvnet-common`,
`openvnet-vna`, `openvnet-vnmgr`, `openvnet-webapi`, `openvnet-vnctl` at once.

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
the sample environment in the overview section we leave those parameters as is. The detail of each parameter is following.

- **id** : OpenVNet relies on the [0mq](http://zeromq.org) protocol for communication among its processes. Hereby processes means vnmgr, vna and webapi. This id is used by 0mq to identify each process. Any string here is fine as long as there's no collision in OpenVNet. It's recommended to just use the default values.

- **protocol** : The layer 4 protocol which is either TCP or UDP. A socket which the 0mq needs will be created based on this parameter. The default value is `tcp`.

- **host** : The IP address of the vnmgr node. We use loopback address in this guide because all the processes reside on the same node .

- **public** : In case the process running in a NAT environment, specify the NAT address as the process can be reached from the outside of the NAT environment.

- **port** : The port number that the process will listen to. Specify a unique port number and make sure the port number is different for each of the OpenVNet's processes and also not taken by any other process.

`/etc/openvnet/vna.conf` and `/etc/openvnet/webapi.conf` have the same structure as `vnmgr.conf`. Edit them if necessary otherwise leave them as is for the sample environment we are just creating. We need the `id` parameter in `vna.conf` later when we configure the database. Please make sure what you specified.

### Setup Local Infrastructure

Datapath is one of the Linux kernel capabilities behaving similar to the Linux bridge.
Create the file `/etc/sysconfig/network-scripts/ifcfg-br0` with the following contents. However you need to pay attention to several parameters.

* datapath-id

The datapath ID that the Open vSwitch will use. Set unique 16 hex digits as you like.

```bash
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

```bash
service openvswitch start
ifup br0
```

Start redis

```bash
service redis start
```

### Setup Database

Edit `/etc/openvnet/common.conf` if necessary. The sample environment uses the default settings.

Launch mysql server.

```bash
service mysqld start
```

To automatically launch the mysql server at boot, execute the following command.

```bash
chkconfig mysqld on
```

Set `PATH` environment variable as following since the OpenVNet uses its own ruby binary.

```bash
PATH=/opt/axsh/openvnet/ruby/bin:${PATH}
```

Create database

```bash
cd /opt/axsh/openvnet/vnet
bundle exec rake db:create
bundle exec rake db:init
```

Start vnmgr and webapi.

```bash
initctl start vnet-vnmgr
initctl start vnet-webapi
```

We use `vnctl` to create the database records subsequent to the above configurations. `vnctl` is Web API client offered by the `openvnet-vnctl` package.

#### Datapath

We created a datapath earlier that the OpenVNet needs to know. The following database record must be created in order to tell the OpenVNet about the datapath.

```bash
vnctl datapaths add --uuid dp-test1 --display-name test1 --dpid 0x0000aaaaaaaaaaaa --node-id vna
```

* dpid

The datapath ID specified in `/etc/sysconfig/network-scripts/ifcfg-br0`

* node-id

The ID of the vna written in `/etc/openvnet/vna.conf`


#### Network

In the figure of the sample environment there is a light purple circle which represents a virtual network. You need to define the virtual network by `vnctl networks add` subcommand with the following parameters.

```bash
vnctl networks add --uuid nw-test1 --display-name testnet1 --ipv4-network 10.100.0.0 --ipv4-prefix 24 --network-mode virtual
```

* ipv4-network

The IPv4 network address.

* ipv4-prefix

The IPv4 network prefix. (default 24)

* network-mode

The mode of the network to create. We are currently creating the virtual network (10.100.0.0/24) mentioned in the figure. That is why we specify `virtual` here.


#### Interface

As the sample environment has 2 virtual machines, here we define 2 database records of interface. These records will be associated to the tap interfaces of the virtual machines. The former record contains `inst1`'s network interface information. The latter is for `inst2`.

```bash
vnctl interfaces add --uuid if-inst1 --mode vif --owner-datapath-uuid dp-test1 --mac-address 10:54:ff:00:00:01 --network-uuid nw-test1 --ipv4-address 10.100.0.10 --port-name inst1
vnctl interfaces add --uuid if-inst2 --mode vif --owner-datapath-uuid dp-test1 --mac-address 10:54:ff:00:00:02 --network-uuid nw-test1 --ipv4-address 10.100.0.11 --port-name inst2
```

* mode

The mode of the interface. An entry with `vif` mode is basically for a virtual or physical device that is attached to the datapath of the Open vSwitch. Another mode might be specified for a physical device but here we omit the explanation about it.

* owner-datapath-uuid

The UUID of the datapath to which this interface will be connected.

* mac-address

The MAC address of the network interface of the virtual machine.

* network-uuid

The UUID of the virtual network to participate

* ipv4-address

The IPv4 address which will be assigned to the network interface.

* port-name

The OpenVNet associates an Open vSwitch's port with a database record of the interface table if its `port-name` is corresponded to what you can see by `ovs-vsctl show`.


### Launch Services

The OpenVNet's processes(vnmgr, webapi and vna) are registered as upstart jobs.
You can launch them using the following commands. vnmgr and webapi may have already been launched in the last sections.

```bash
initctl start vnet-vnmgr
initctl start vnet-webapi
initctl start vnet-vna
```

The log files are created in the /var/log/openvnet directory. Refer to them if something bad happens. If the vna is successfully launched you can see `is_connected: true` by `ovs-vsctl show` such as following.

```bash
fbe23184-7f14-46cb-857b-3abf6153a6d6
    Bridge "br0"
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
```

This means the OpenFlow controller which is vna is now connected to the datapath. After the connection between the OpenFlow controller and the
datapath is established it starts installing the flows on the datapath.

Verification
-------

By following all the instructions from the beginning to this section, you already have the sample environment. In this section, we are firstly going to play around the environment then secondary see network packets going through OpenFlow rules to reach
from one guest to another.

As a representation of the guest here we use [LXC](https://linuxcontainers.org), which helps users run multiple isolated Linux system containers. Any other virtualization technologies might be used, however we take LXC since it is easy to create/destroy/configure and simple enough to do this verification.

Install LXC

```bash
yum -y install lxc lxc-templates
```

Create and mount cgroup

```bash
mkdir /cgroup
echo "cgroup /cgroup cgroup defaults 0 0" >> /etc/fstab
mount /cgroup
```

Create 2 LXC guests
(it may require rsync to be installed. If it is not installed execute `yum install rsync`)

```bash
lxc-create -t centos -n inst1
lxc-create -t centos -n inst2
```

Configure interfaces of each guest

```bash
vi /var/lib/lxc/inst1/config

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

```bash
vi /var/lib/lxc/inst2/config

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

We do not use `lxc.network.link` parameter because the Linux bridge is replaced by the Open vSwitch.

Make sure that the IPv4 address and MAC address are the same as what you specify when you create the interface database records.

Launch the LXC guests then enslave the LXC's tap interfaces to the datapath.

```bash
lxc-start -d -n inst1
lxc-start -d -n inst2

ovs-vsctl add-port br0 inst1
ovs-vsctl add-port br0 inst2
```

Now the LXC's network interfaces are attached to the Open vSwitch, likewise you plug a LAN cable to a network switch.

Log in to the inst1 to see if the IP address is assigned properly.

```bash
lxc-console -n inst1
ip a
```

ping to inst2 (10.100.0.11)

```bash
ping 10.100.0.11
```

You would see the ping reply from the peer machine (in this case inst2). Meanwhile you can see which flows are selected by `vnflows-monitor`. Execute the following command on a lxc guest, then ping from one another.

```bash
cd /opt/axsh/openvnet/vnet/bin
./vnflows-monitor c 0 d 1
```

You can see the whole flows by `vnflows-monitor`.

```bash
cd /opt/axsh/openvnet/vnet/bin
./vnflows-monitor
```
