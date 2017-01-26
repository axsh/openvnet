# Filters

## Overview

Sometimes we want to be able to controll the traffic between our interfaces and block/allow packages when certain conditions are met. In OpenVNet we can achieve this with the filter feature.

In this guide we will use the enviroment created in the [Single network with DHCP server](../creating-virtual-networks/single-network-dhcp.md) and set up some filters so that `inst1` allows traffic on the arp protocol but blocks all else.

# Setup

Before getting started we make sure that `inst1` and `inst2` can communicate both tcp/icmp by doing some simple tests.

Log into `inst2` and type:

```bash
arping 10.100.0.10
ping 10.100.0.10
ssh 10.100.0.10
```
These should all generate responses which indicates packages are being sent/recived.

### Enable filtering

**Remark:** Due to a bug in OpenVNet's internal event queue, it is currently possible for filters not to update correctly. If the following commands don't have the expected result, try restarting VNA.

To use filters we first need to tell OpenVNet that we want traffic to be filterd.

```bash
vnctl interfaces modify if-inst1 --enable-filtering
```

### Creating the filter item

Now we can create the filter item.

```bash
vnctl filters add \
--uuid fil-filter1 \
--interface-uuid if-inst1 \
--mode static
```

### Creating the rules

We now have a filter that will block all traffic both incoming and outgoing for the interface `if-inst1`. Now we will add a rule that opens up the arp protocol. We also set up filters for tcp and icmp protocols to have traffic dropped.

```bash
vnctl filters static add fil-filter1 \
--protocol arp \
--ipv4-address 0.0.0.0/0 \
--passthrough

vnctl filters static add fil-filter1 \
--protocol tcp \
--ipv4-address 0.0.0.0/0 \
--port-number 0 \
--passthrough false

vnctl filters static add fil-filter1 \
--protocol icmp \
--ipv4-address 0.0.0.0/0 \
--passthrough false
```

`ipv4-address` set to 0.0.0.0/ will make the match for every ip address and `port-number` set to 0 will match all ports.
For more information about filter commands, see [filters section](../vnctl/filters) in the vnctl documentation.

# Test

Log into `inst2` and once again type in the commands from before.
```bash
arping 10.100.0.10
ping 10.100.0.10
ssh 10.100.0.10
```

If everything went well you will notice that both the ping and ssh command should result in no response while the arping response stays unchanged.

By making use of the filter feature we can create our own blacklist or whitelist according to our needs.
