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

* Check Open vSwitch's flow tables to see the DHCP packets are handled properly (sometimes the packet is dropped by some rules).
* Use [tcpdump](http://www.tcpdump.org/) to capture the DHCP packets sent from the virtual machines to the [Open vSwtich](http://openvswitch.org/)'s datapath.

```
[kemukins@11-vnetdev ~]$ sudo ovs-vsctl show
7091f6a6-25dc-4d56-bfab-64ec1f8d7d97
    Bridge "br0"
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: standalone
        Port "br0"
            Interface "br0"
                type: internal
        Port "veth_kvm2lxc1"
            Interface "veth_kvm2lxc1"
        Port "eth0"
            Interface "eth0"
        Port "veth_kvm2lxc2"
            Interface "veth_kvm2lxc2"
    ovs_version: "2.3.0"
[kemukins@11-vnetdev ~]$ sudo tcpdump -i veth_kvm2lxc2
11:03:01.265152 IP6 :: > ff02::16: HBH ICMP6, multicast listener report v2, 1 group record(s), length 28
11:03:01.631191 IP6 :: > ff02::1:ffe5:3504: ICMP6, neighbor solicitation, who has fe80::218:51ff:fee5:3504, length 24
11:03:02.631175 IP6 fe80::218:51ff:fee5:3504 > ff02::2: ICMP6, router solicitation, length 16
11:03:05.001001 IP 0.0.0.0.bootpc > 255.255.255.255.bootps: BOOTP/DHCP, Request from 00:18:51:e5:35:04 (oui Unknown), length 300
11:03:05.034090 IP 10.0.0.5.bootps > 10.0.0.203.bootpc: BOOTP/DHCP, Reply, length 300
11:03:05.064323 ARP, Request who-has 10.0.0.203 (Broadcast) tell 0.0.0.0, length 28
11:03:06.064564 ARP, Request who-has 10.0.0.203 (Broadcast) tell 0.0.0.0, length 28
11:03:06.631194 IP6 fe80::218:51ff:fee5:3504 > ff02::2: ICMP6, router solicitation, length 16
11:03:07.810198 IP6 fe80::218:51ff:fee5:3504 > ff02::16: HBH ICMP6, multicast listener report v2, 1 group record(s), length 28
11:03:10.631179 IP6 fe80::218:51ff:fee5:3504 > ff02::2: ICMP6, router solicitation, length 16
```

* Check /var/log/openvnet/vna.log to find the log DHCP release.

```
[kemukins@11-vnetdev ~]$ tail -f /var/log/openvnet/vna.log
D, [2014-10-23T10:52:03.018259 #16740] DEBUG -- : 0x0000bbbbbbbbbbbb service/dhcp: DHCP send: DHCP_MSG_ACK
D, [2014-10-23T10:52:03.034879 #16740] DEBUG -- : 0x0000bbbbbbbbbbbb service/dhcp: DHCP send (output:DHCP Message
        FIELDS:
                Transaction ID = 0xf86da613
                Client IP address = 0.0.0.0
                Your IP address = 10.0.0.203
                Next server IP address = 10.0.0.5
                Relay agent IP address = 0.0.0.0
                Hardware address = 00:18:51:E5:35:04
                Server Name = [""]
                File Name = [""]
        OPT:
                 DHCP Message Type = DHCP ACK (5)
                 Server Identifier = 10.0.0.5
                 IP Address Lease Time = infinite seg
                 Broadcast Adress = 10.0.0.255
                 Subnet Mask = 255.255.255.0
                 Domain Name Server = 127.0.0.1
)
```
