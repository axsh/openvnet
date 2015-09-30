# Change Log

All notable changes to OpenVNet will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

* `Changed` Added a default value of `false` to all `is_deleted` flags in the database. Now OpenVNet can be used with MySQL's STRICT mode.

* `Fixed` An issue where vna could retrieve network resources from vnmgr while their related resources were not fully loaded yet.

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
