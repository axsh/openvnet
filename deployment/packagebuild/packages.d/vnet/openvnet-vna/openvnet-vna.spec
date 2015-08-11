Name: openvnet-vna
Version: 0.7
Release: 2
Summary: Virtual network agent for OpenVNet.
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://openvnet.org
Source: https://github.com/axsh/openvnet
License: LGPLv3

BuildArch: noarch

Requires: openvnet-common
Requires: openvswitch = 2.3.1

%Description
This package contains OpenVNet's VNA process. This is an OpenFlow controller that sends commands to Open vSwitch to implement virtual networks.

%prep
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
if [ ! -d "$OPENVNET_SRC_DIR" ]; then
  git clone https://github.com/axsh/openvnet "$OPENVNET_SRC_DIR"
fi

%files
/opt/axsh/openvnet/vnet/bin/vna
/opt/axsh/openvnet/vnet/bin/vnflows-monitor
%config /etc/openvnet/vna.conf
%config /etc/default/vnet-vna
%config /etc/init/vnet-vna.conf

%install
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
mkdir -p "$RPM_BUILD_ROOT"/etc/openvnet
mkdir -p "$RPM_BUILD_ROOT"/etc/default
mkdir -p "$RPM_BUILD_ROOT"/etc/init
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/default/vnet-vna "$RPM_BUILD_ROOT"/etc/default/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/init/vnet-vna.conf "$RPM_BUILD_ROOT"/etc/init/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/openvnet/vna.conf "$RPM_BUILD_ROOT"/etc/openvnet/
cp "$OPENVNET_SRC_DIR"/vnet/bin/vna "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin/
cp "$OPENVNET_SRC_DIR"/vnet/bin/vnflows-monitor "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin/
