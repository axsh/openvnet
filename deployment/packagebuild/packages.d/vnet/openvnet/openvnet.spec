Name: openvnet
Version: 0.7
Release: 2
Summary: Metapackage that depends on all other OpenVNet packages.
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://openvnet.org
Source: https://github.com/axsh/openvnet
License: LGPLv3

BuildArch: noarch

Requires: openvnet-vnctl
Requires: openvnet-webapi
Requires: openvnet-vnmgr
Requires: openvnet-vna

%Description
This is an empty metapackage that depends on all OpenVNet services and the vnctl client. Just a conventient way to install everything at once on a single machine.

%files
