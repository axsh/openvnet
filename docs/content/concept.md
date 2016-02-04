# Concept

OpenVNet is what you would call a network hypervisor or [software-defined networking](https://en.wikipedia.org/wiki/Software-defined_networking). A network hypervisor provides a layer of abstraction on top of existing network hardware. It is basically is to networking what virtual machines are to servers.

![OpenVNet concept](../img/concept_1.png)

Once OpenVNet has been set up, it becomes possible to create any network topology that you have in mind, without making any changes to the hardware.

OpenVNet is completely independent of hardware. The only requirement is that hypervisor hosts have IP connectivity to each other.

Users can tell OpenVNet what to do by accessing its Web API. This API provides a single endpoint through which you can create simulated network devices like routers, firewalls, DHCP servers, etc. Virtual Machines, or rather their network interfaces, can then be attached to any of these virtual networks. The resulting network topology can be re-arranged on the fly.

## Under the Hood

![OpenVNet's inner workings](../img/concept_2.png)

OpenVNet builds on top of [OpenFlow](http://archive.openflow.org). In short, OpenFlow is an open protocol that can be used to tell network devices like switches or routers what to do. OpenVNet uses OpenFlow to communicate with Open vSwitch.

### Hypervisor host

This is a server running Linux that will start virtual machines which will then be placed in OpenVNet's virtual networks. OpenVNet can work with any hypervisor as long as the virtual machines' network interfaces can be attached to Open vSwitch. Starting the virtual machines themselves is beyond the scope of OpenVNet. It can be done manually or through integration with [Wakame-vdc](http://wakame-vdc.org). Other custom solutions are always possible and Axsh is available for hire to help implement them.

While most OpenVNet environments will consist of only virtual machines, it is possible to place bare metal servers in virtual networks. Their network cards can be added to Open vSwitch in the same way virtual machines are.

Below we will explain OpenVNet's different components one by one.

### Open vSwitch

[Open vSwitch](http://openvswitch.org) is a Linux kernel module that acts as a network switch for virtual machines. Because this switch has implemented OpenFlow, OpenVNet is able to change its *flow tables* on the fly. These flow tables are essentially a set of rules that decide what needs to happen as network traffic is processed. It is through manipulating these that software defined networking can be implemented.

### VNA

The *Virtual Network Agent*, or VNA for short, is the OpenFlow controller that tells Open vSwitch to alter its flow tables. In order to prevent a single point of failure, OpenVNet has a dedicated VNA for every hypervisor host running Open vSwitch.

### Vnmgr

The *Virtual Network Manager* or Vnmgr acts as OpenVNet's database front-end and decision making organ. As the user changes the virtual network topology through OpenVNet's Web API, Vnmgr stores the new topology in the database and broadcasts events to all affected VNAs, informing them of the changes they need to make.

### Database

The database stores a representation of the current network topology. Vnmgr is responsible for maintaining/updating it and sending relevant information to the VNA on each hypervisor host.

### Web API

This is the endpoint through which users can talk to OpenVNet. By sending HTTP requests to this API, the virtual network topology can be changed.

### Vnctl

This is a commandline interface that makes accessing the Web API just a little more convenient.

### User Laptop

This is the client machine from which the user sends requests to the Web API. We use the word laptop to make clear that this device does not need to be running anything special. Any device that can make HTTP calls will do.

### VNet Edge

As the name might imply, this is the edge of VNet's virtual network topology. VNet Edge provides Layer 2 interconnectivity between OpenVNet's virtual networks and any other network.

### Physical Network

This is the network that provides connectivity between hypervisor hosts and the servers running Vnmgr, Web API and the database. It doesn't matter what hardware this is run on. As long as all hosts have TCP/IP access to each other, OpenVNet will work.

