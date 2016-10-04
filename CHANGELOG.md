# Change Log

All notable changes to OpenVNet will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

* `Added` A new features called `segment` that accurately simulates L2 segments, allowing connected interfaces to freely set and change their IP addresses without making OpenVNet aware of them.

* `Added` New feature `promiscuous interface mode`, allowing us to connect physical networks to OpenVNet's virtual networks on an L2 level without the need for VNet Edge.

* `Added` The option to have VNA take control of an Open vSwitch running on another host.

* `Changed` It is no longer possibly to directly modify an IP lease through the WebAPI. In order to preserve network state history, IP leases need to be deleted and recreated.

* `Changed` We now use the [PIO](https://github.com/trema/pio) library to manage MAC addresses.

* `Changed` Refactored IP/MAC leases and wrote a bunch more unit tests for them.

## [0.9] - 2016-04-19

* `Added` A new `topology manager` that automatically creates `datapath_network` and `datapath_route_link` entries in the database.

* `Added` A new simple firewall feature alongside the existing security groups. Security groups will eventually be ported to use this.

* `Added` Automatic MAC address assignment using `mac range groups`.

* `Added` Vnctl commands for the creation and deletion of static network address translation.

* `Added` Error handling for IPv4 addresses in the wrong subnet as early as the WebAPI.

* `Removed` The `broadcast_mac_address` parameter in the WebAPI's datapaths endpoint. Use `mac_address` instead.

* `Changed` Optimized manager initialization code so no events can be processed before the targeted managers are properly initialized.

* `Deprecated` The `type` parameter in the WebAPI's network_services endpoint. Use `mode` instead.

* `Changed` Added a default value of `false` to all `is_deleted` flags in the database. Now OpenVNet can be used with MySQL's STRICT mode.

* `Changed` The `mac_address` parameter in the WebAPI's `datapath_networks` and `datapath_route_links` endpoints are no longer required. OpenVNet will now generate them if not provided.

* `Changed` Use different priority for flows depending on their prefix in order to ensure that e.g. 10.10.10.0/24 gets handled before 10.10.0.0/16.

* `Fixed` An issue where vna could retrieve network resources from vnmgr while their related resources were not fully loaded yet.

* `Fixed` Several minor bugfixes. 

## [0.8] - 2015-09-04

* `Added` Warning messages in the log when managers receive events with invalid parameters.

* `Added` A ruby gem for accessing the WebAPI. (https://rubygems.org/gems/vnet_api_client)

* `Added` Error handling for when a user tries to create an IP address outside of its subnet range.

* `Deprecated` The `broadcast_mac_address` parameter in the WebAPI's datapaths endpoint. Use `mac_address` instead.

* `Changed` Updated the ruby gems dependencies to their most recent versions where possible.

* `Changed` The command line arguments to the `vnflows-monitor` debug tool now use a more common format.

* `Changed` Moved `vnctl` to the client directory.

* `Fixed` An issue where VNet Edge related flows were not always created correctly. Edge is now no longer considered experimental.

* `Fixed` An issue where Celluloid would some times assume that the main Trema thread was actually a Celluloid thread.

* `Fixed` Code cleanup and minor bug fixes in datapath manager.

* `Fixed` An issue where events could get processed before managers were initialized, causing race conditions.

## [0.7] - 2015-06-04

The first numbered OpenVNet release.

* `Added` Process `vna` which acts as an OpenFlow controller for Open vSwitch.

* `Added` Process `vnmgr` which acts as a database frontend and pushes events to `vna`.

* `Added` Process `webapi` which acts as a user interface.

* `Added` Two protocols to support virtual networking.
  - **MAC2MAC**, our own original protocol for virtual networking on top of a physical L2 connection.
  - **GRE** for virtual networking on top of a physical L3 connection.

* `Added` Simulated DHCP service to assign IP addresses to network interfaces.

* `Added` L3 routing between virtual networks.

* `Added` Single hop L3 routing between physical and virtual networks.

* `Added` Security groups feature for implementing per-interface firewalls.

* `Added` Connection tracking feature that simulates stateful firewalls in Open vSwitch's stateless world.

* `Added` Integration with Wakame-vdc. (http://wakame-vdc.org)

* `Added` VNet Edge feature that allows virtual networks to communicate on L2 with legacy networks. (Experimental)
