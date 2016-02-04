# datapaths add

This page explains the arguments used by the `vnctl datapaths add` command in the [installation guide](../installation)).

```bash
vnctl datapaths add \
 --uuid dp-test1 \
 --display-name test1 \
 --dpid 0x0000aaaaaaaaaaaa \
 --node-id vna
```
* uuid

A unique ID that will be used to refer to this datapath.

* display-name

A human readable name that describes this datapath. It can be anything you want.

* dpid

The datapath ID specified in `/etc/sysconfig/network-scripts/ifcfg-br0`

* node-id

The ID of the VNA that will manage this datapath. You can find this ID written in `/etc/openvnet/vna.conf`. In a production environment, it's very likely for OpenVNet to span multiple hosts, each with their own Open vSwitch and VNA combo. Therefore we need to tell OpenVNet which VNA will manage which datapath.
