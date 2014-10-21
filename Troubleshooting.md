# Troubleshooting

## Something is wrong. What should I check?

Please try following:

* Ping between virtual machines.
* Check /var/log/openvnet/vna.log.
* Check /var/log/openvnet/vnmgr.log.
* See "interfaces", "mac_leases", "mac_addresses" DB table to know KVM's NICs are connected.
* Use vnflows-monitor https://github.com/axsh/openvnet/blob/master/vnet/bin/vnflows-monitor

## Why not OpenVNet release IP address for virtual machines?

* Use [tcpdump](http://www.tcpdump.org/) to see DHCP packet from virtual machines to [Open vSwtich](http://openvswitch.org/)'s bridge.
* Check Open vSwtich's flow table to know DHCP packet (sometimes the packet is dropped by some rules)
