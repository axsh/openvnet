# Change Log

All notable changes to OpenVNet will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

* `Added` Warning messages in the log when managers receive events with invalid parameters.

* `Changed` Updated the ruby gems dependencies to their most recent versions where possible.

* `Fixed` An issue where Celluloid would some times assume that the main Trema thread was actually a Celluloid thread.

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
