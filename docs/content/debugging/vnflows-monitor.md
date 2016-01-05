# Vnflows monitor

Vnflows-monitor is a debug tool that automatically gets installed along with VNA. You can use it to display the flows that are currently present in Open vSwitch.

To run it first make sure that OpenVNet's ruby binary is in your `PATH`.

```bash
PATH=/opt/axsh/openvnet/ruby/bin:${PATH}
```

Now run it like so:

```bash
cd /opt/axsh/openvnet/vnet/bin/
./vnflows-monitor
```

If Open vSwitch is running and currently has flows in it, you should see this kind of output.

```bash
(0): TABLE_CLASSIFIER
  0-00        0       0 => SWITCH(0x0)               actions=write_metadata:REMOTE(0x0),goto_table:TABLE_TUNNEL_PORTS(3)
  0-01        0       0 => SWITCH(0x0)              tun_id=0 actions=drop
  0-02       28       0 => PORT(0x1)                in_port=1 actions=write_metadata:TYPE_INTERFACE|LOCAL(0x1),goto_table:TABLE_INTERFACE_EGRESS_CLASSIFIER(15)
  0-02       22       0 => PORT(0x2)                in_port=2 actions=write_metadata:TYPE_INTERFACE|LOCAL(0x5),goto_table:TABLE_INTERFACE_EGRESS_CLASSIFIER(15)
  0-02        0       0 => SWITCH(0x0)              in_port=CONTROLLER actions=write_metadata:LOCAL|NO_CONTROLLER(0x0),goto_table:TABLE_CONTROLLER_PORT(7)
  0-02        0       0 => PORT(0x7ffffffe)         in_port=LOCAL actions=write_metadata:LOCAL(0x0),goto_table:TABLE_LOCAL_PORT(6)
(3): TABLE_TUNNEL_PORTS
  3-00        0       0 => SWITCH(0x0)               actions=drop
(4): TABLE_TUNNEL_NETWORK_IDS
  4-00        0       0 => SWITCH(0x0)               actions=drop
  4-30        0       0 => ROUTE_LINK(0x1)          tun_id=0x10000001,dl_dst=02:00:10:00:00:01 actions=write_metadata:TYPE_ROUTE_LINK(0x1),goto_table:TABLE_ROUTER_CLASSIFIER(33)
  4-30        0       0 => NETWORK(0x1)             tun_id=0x80000001 actions=write_metadata:TYPE_NETWORK(0x1),goto_table:TABLE_NETWORK_SRC_CLASSIFIER(20)
  4-30        0       0 => NETWORK(0x2)             tun_id=0x80000002 actions=write_metadata:TYPE_NETWORK(0x2),goto_table:TABLE_NETWORK_SRC_CLASSIFIER(20)
(6): TABLE_LOCAL_PORT
  6-00        0       0 => SWITCH(0x0)               actions=drop
...
```

As you can see in this output flows are grouped in what we call "flow tables".

The numbers on the left are the flow table index followed the the flow's priority. Packets traversing Open vSwitch start in the flow table with index 0 and will get matched against the flows with the highest priority first.

The next number shows the amount of packets that have been matched against the flow. For most flows in the above example that is 0 but there's two flows that have been matched 28 and 22 times respectively.

Next is the flow's cookie. What a cookie is in OpenFlow is beyond the scope of this guide.

Finally, on the right we see the data we are matching packets against and the actions we undertake in case a match is found.

## Monitoring changes in flows as they happen

One of vnflows-monitor's most useful features is the ability to continously monitor flows and report any changes immediately. Try running it with the following arguments.

```bash
cd /opt/axsh/openvnet/vnet/bin
./vnflows-monitor -d -c 0
```

Now it will constantly keep iterating and probably not show any output. While this is going on, try having two VMs in virtual networks ping each other. For example have `inst1` from the installation guide ping `inst2`.

You should see this kind of output.

```bash
-------run:4--iteration:43-------
(0): TABLE_CLASSIFIER
  0-02       34       0 => PORT(0x1)                in_port=1 actions=write_metadata:TYPE_INTERFACE|LOCAL(0x1),goto_table:TABLE_INTERFACE_EGRESS_CLASSIFIER(15)
  0-02       28       0 => PORT(0x2)                in_port=2 actions=write_metadata:TYPE_INTERFACE|LOCAL(0x5),goto_table:TABLE_INTERFACE_EGRESS_CLASSIFIER(15)
(15): TABLE_INTERFACE_EGRESS_CLASSIFIER
 15-30       11       0 => INTERFACE(0x1)[0x12]     ip,metadata=TYPE_INTERFACE(0x1),dl_src=10:54:ff:00:00:01,nw_src=10.100.0.10 actions=write_metadata:TYPE_NETWORK(0x1),goto_table:TABLE_INTERFACE_EGR
ESS_FILTER(18)
 15-30        8       0 => INTERFACE(0x5)[0x12]     ip,metadata=TYPE_INTERFACE(0x5),dl_src=10:54:ff:00:00:02,nw_src=192.168.50.10 actions=write_metadata:TYPE_NETWORK(0x2),goto_table:TABLE_INTERFACE_E
GRESS_FILTER(18)
(18): TABLE_INTERFACE_EGRESS_FILTER
 18-00       38       0 => SWITCH(0x0)               actions=goto_table:TABLE_NETWORK_SRC_CLASSIFIER(20)
(20): TABLE_NETWORK_SRC_CLASSIFIER
 20-30       25       0 => NETWORK(0x1)             metadata=TYPE_NETWORK(0x1) actions=goto_table:TABLE_ROUTE_INGRESS_INTERFACE(30)
 20-30       13       0 => NETWORK(0x2)             metadata=TYPE_NETWORK(0x2) actions=goto_table:TABLE_ROUTE_INGRESS_INTERFACE(30)
(30): TABLE_ROUTE_INGRESS_INTERFACE
 30-10        8       0 => INTERFACE(0x6)[0x12]     ip,metadata=TYPE_NETWORK(0x1),dl_dst=02:00:00:00:02:01 actions=write_metadata:TYPE_INTERFACE(0x6),goto_table:TABLE_ROUTE_INGRESS_TRANSLATION(31)
 30-10        8       0 => INTERFACE(0x7)[0x12]     ip,metadata=TYPE_NETWORK(0x2),dl_dst=02:00:00:00:02:02 actions=write_metadata:TYPE_INTERFACE(0x7),goto_table:TABLE_ROUTE_INGRESS_TRANSLATION(31)
(31): TABLE_ROUTE_INGRESS_TRANSLATION
 31-90        8       0 => INTERFACE(0x6)           metadata=TYPE_INTERFACE(0x6) actions=goto_table:TABLE_ROUTER_INGRESS_LOOKUP(32)
 31-90        8       0 => INTERFACE(0x7)           metadata=TYPE_INTERFACE(0x7) actions=goto_table:TABLE_ROUTER_INGRESS_LOOKUP(32)
(32): TABLE_ROUTER_INGRESS_LOOKUP
 32-30        8       0 => ROUTE(0x1)               ip,metadata=TYPE_INTERFACE(0x6),nw_src=10.100.0.0/24 actions=write_metadata:TYPE_ROUTE_LINK|REFLECTION(0x1),goto_table:TABLE_ROUTER_CLASSIFIER(33)
 32-30        8       0 => ROUTE(0x2)               ip,metadata=TYPE_INTERFACE(0x7),nw_src=192.168.50.0/24 actions=write_metadata:TYPE_ROUTE_LINK|REFLECTION(0x1),goto_table:TABLE_ROUTER_CLASSIFIER(33
)
33): TABLE_ROUTER_CLASSIFIER
 33-30       16       0 => ROUTE_LINK(0x1)          metadata=TYPE_ROUTE_LINK(0x1) actions=goto_table:TABLE_ROUTER_EGRESS_LOOKUP(34)
(34): TABLE_ROUTER_EGRESS_LOOKUP
 34-30        8       0 => ROUTE(0x1)               ip,metadata=TYPE_ROUTE_LINK(0x1),nw_dst=10.100.0.0/24 actions=write_metadata:0x8000000600000001,goto_table:TABLE_ROUTE_EGRESS_LOOKUP(35)
 34-30        8       0 => ROUTE(0x2)               ip,metadata=TYPE_ROUTE_LINK(0x1),nw_dst=192.168.50.0/24 actions=write_metadata:0x8000000700000001,goto_table:TABLE_ROUTE_EGRESS_LOOKUP(35)
(35): TABLE_ROUTE_EGRESS_LOOKUP
 35-20        8       0 => INTERFACE(0x6)[0x12]     metadata=VALUE_PAIR(0x8000000600000000/0xffffffff00000000)(0x0) actions=write_metadata:0x702000000000006,goto_table:TABLE_ROUTE_EGRESS_TRANSLATION(
36)
 35-20        8       0 => INTERFACE(0x7)[0x12]     metadata=VALUE_PAIR(0x8000000700000000/0xffffffff00000000)(0x0) actions=write_metadata:0x702000000000007,goto_table:TABLE_ROUTE_EGRESS_TRANSLATION(
36)
(36): TABLE_ROUTE_EGRESS_TRANSLATION
 36-90        8       0 => INTERFACE(0x6)           metadata=TYPE_INTERFACE(0x6) actions=goto_table:TABLE_ROUTE_EGRESS_INTERFACE(37)
 36-90        8       0 => INTERFACE(0x7)           metadata=TYPE_INTERFACE(0x7) actions=goto_table:TABLE_ROUTE_EGRESS_INTERFACE(37)
(37): TABLE_ROUTE_EGRESS_INTERFACE
 37-20        8       0 => INTERFACE(0x6)[0x12]     metadata=TYPE_INTERFACE(0x6) actions=set_field:02:00:00:00:02:01->eth_src,write_metadata:TYPE_NETWORK(0x1),goto_table:TABLE_ARP_TABLE(40)
 37-20        8       0 => INTERFACE(0x7)[0x12]     metadata=TYPE_INTERFACE(0x7) actions=set_field:02:00:00:00:02:02->eth_src,write_metadata:TYPE_NETWORK(0x2),goto_table:TABLE_ARP_TABLE(40)
(40): TABLE_ARP_TABLE
 40-40        8       0 => INTERFACE(0x1)[0x12]     ip,metadata=TYPE_NETWORK(0x1),nw_dst=10.100.0.10 actions=set_field:10:54:ff:00:00:01->eth_dst,goto_table:TABLE_NETWORK_DST_CLASSIFIER(42)
 40-40        8       0 => INTERFACE(0x5)[0x12]     ip,metadata=TYPE_NETWORK(0x2),nw_dst=192.168.50.10 actions=set_field:10:54:ff:00:00:02->eth_dst,goto_table:TABLE_NETWORK_DST_CLASSIFIER(42)
(42): TABLE_NETWORK_DST_CLASSIFIER
 42-30       25       0 => NETWORK(0x1)             metadata=TYPE_NETWORK(0x1) actions=goto_table:TABLE_NETWORK_DST_MAC_LOOKUP(43)
 42-30       13       0 => NETWORK(0x2)             metadata=TYPE_NETWORK(0x2) actions=goto_table:TABLE_NETWORK_DST_MAC_LOOKUP(43)
(43): TABLE_NETWORK_DST_MAC_LOOKUP
 43-60       12       0 => INTERFACE(0x1)[0x12]     metadata=TYPE_NETWORK(0x1),dl_dst=10:54:ff:00:00:01 actions=write_metadata:TYPE_INTERFACE(0x1),goto_table:TABLE_INTERFACE_INGRESS_FILTER(45)
 43-60        8       0 => INTERFACE(0x5)[0x12]     metadata=TYPE_NETWORK(0x2),dl_dst=10:54:ff:00:00:02 actions=write_metadata:TYPE_INTERFACE(0x5),goto_table:TABLE_INTERFACE_INGRESS_FILTER(45)
(45): TABLE_INTERFACE_INGRESS_FILTER
 45-90       11       0 => INTERFACE(0x1)[0x71]     metadata=TYPE_INTERFACE(0x1) actions=goto_table:TABLE_OUT_PORT_INTERFACE_INGRESS(90)
 45-90        8       0 => INTERFACE(0x5)[0x71]     metadata=TYPE_INTERFACE(0x5) actions=goto_table:TABLE_OUT_PORT_INTERFACE_INGRESS(90)
(90): TABLE_OUT_PORT_INTERFACE_INGRESS
 90-10       12       0 => PORT(0x1)                metadata=TYPE_INTERFACE(0x1) actions=output:1
 90-10        8       0 => PORT(0x2)                metadata=TYPE_INTERFACE(0x5) actions=output:2

```

As the ping request and reply traverse Open vSwitch' flows, all the flows that they match will have their match counters incremented. Those and only those will now be outputted by vnflows-monitor. This allows us to immediately see which path our packets followed through Open vSwitch's flows.

This time we used vnflows-monitor to see which flows are matched when a packet comes through but another idea is to change the virtual network topology while it is running. This will show you exactly what flows get added and removed with each step. Have fun.
