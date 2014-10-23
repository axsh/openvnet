# Troubleshooting

## Something is wrong. What should I check?

Please try following:

* Run [ping](http://linux.die.net/man/8/ping) between virtual machines.
* Run [route](http://linux.die.net/man/8/route) to see IP routing table.
* Check /var/log/openvnet/vna.log, /var/log/openvnet/vnmgr.log, /var/log/openvnet/webapi.log.
* Check if the MAC addresses are not duplicated.

```
[kemukins@10-vnetdev ~]$ ifconfig|grep HWaddr
br0       Link encap:Ethernet  HWaddr 02:01:00:00:00:01
eth0      Link encap:Ethernet  HWaddr 52:54:00:51:06:47
eth1      Link encap:Ethernet  HWaddr 52:54:00:51:16:47
veth_kvm1lxc1 Link encap:Ethernet  HWaddr FE:D0:34:A9:89:F6
veth_kvm1lxc2 Link encap:Ethernet  HWaddr FE:18:01:59:48:C2
```

* See "interfaces", "mac_leases", "mac_addresses" and "datapaths" DB tables to check if the virtual machines' NICs are associated.

```
[kemukins@10-vnetdev ~]$ mysql -u root vnet
mysql> select * from datapaths;
+----+----------+--------------+-----------------+---------+--------------+---------------------+---------------------+------------+------------+
| id | uuid     | display_name | dpid            | node_id | is_connected | created_at          | updated_at          | deleted_at | is_deleted |
+----+----------+--------------+-----------------+---------+--------------+---------------------+---------------------+------------+------------+
|  1 | kvm1lxc1 | dp-kvm1lxc1  | 187649984473770 | vna1    |            0 | 2014-10-22 01:47:11 | 2014-10-22 01:47:11 | NULL       |          0 |
|  2 | kvm1lxc2 | dp-kvm1lxc2  | 206414982921147 | vna2    |            0 | 2014-10-22 01:47:12 | 2014-10-22 01:47:12 | NULL       |          0 |
+----+----------+--------------+-----------------+---------+--------------+---------------------+---------------------+------------+------------+
```

* Use "vnflows-monitor" https://github.com/axsh/openvnet/blob/master/vnet/bin/vnflows-monitor
* Run "ovs-vsctl show" to see the Open vSwitch datapath settings.

```
[kemukins@10-vnetdev ~]$ sudo ovs-vsctl show
c715dd09-72e6-4ca3-a3bf-b8f796d0b5ac
    Bridge "br0"
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: standalone
        Port "veth_kvm1lxc2"
            Interface "veth_kvm1lxc2"
        Port "br0"
            Interface "br0"
                type: internal
        Port "eth0"
            Interface "eth0"
        Port "veth_kvm1lxc1"
            Interface "veth_kvm1lxc1"
    ovs_version: "2.3.0"
```

* Run "ovs-vsctl list bridge" to see the Open vSwitch datapath settings.

```
[kemukins@10-vnetdev ~]$ sudo ovs-vsctl list bridge
_uuid               : 04f3d01e-f2cf-4551-9178-c176d8eafee7
controller          : [7cf3384a-d4b8-4b66-b2d9-aaee7ef05f3d]
datapath_id         : "0000aaaaaaaaaaaa"
datapath_type       : ""
external_ids        : {}
fail_mode           : standalone
flood_vlans         : []
flow_tables         : {}
ipfix               : []
mirrors             : []
name                : "br0"
netflow             : []
other_config        : {datapath-id="0000aaaaaaaaaaaa", disable-in-band="true", hwaddr="02:01:00:00:00:01"}
ports               : [3fc6a370-6ce8-424d-bbc1-e1dfbb370c93, 80f1b797-ad25-4ccc-b350-0df6e11f17ce, a8d4854f-3109-4496-a40b-26ebf4a42980, ca8912a6-7320-4015-9b99-d903f92a6441]
protocols           : ["OpenFlow10", "OpenFlow12", "OpenFlow13"]
sflow               : []
status              : {}
stp_enable          : false
```


## Why does not OpenVNet release IP addresses for virtual machines?

* Use [tcpdump](http://www.tcpdump.org/) to capture the DHCP packets sent from the virtual machines to the [Open vSwtich](http://openvswitch.org/)'s datapath.
* Check Open vSwitch's flow tables to see the DHCP packets are handled properly (sometimes the packet is dropped by some rules).
