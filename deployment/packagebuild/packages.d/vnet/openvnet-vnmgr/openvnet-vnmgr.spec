Name: openvnet-vnmgr
Version: 0.7
Release: 2
Summary: Virtual Network Manager for OpenVNet.
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://openvnet.org
Source: https://github.com/axsh/openvnet
License: LGPLv3

BuildArch: noarch

Requires: openvnet-common

%Description
This package contains OpenVNet's VNMGR process. This process acts as a frontend for the MySQL database and broadcasts commands to VNA processes.

%prep
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
if [ ! -d "$OPENVNET_SRC_DIR" ]; then
  git clone https://github.com/axsh/openvnet "$OPENVNET_SRC_DIR"
fi

%files
/opt/axsh/openvnet/vnet/bin/vnmgr
%config /etc/openvnet/vnmgr.conf
%config /etc/default/vnet-vnmgr
%config /etc/init/vnet-vnmgr.conf

%install
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
mkdir -p "$RPM_BUILD_ROOT"/etc/openvnet
mkdir -p "$RPM_BUILD_ROOT"/etc/default
mkdir -p "$RPM_BUILD_ROOT"/etc/init
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/default/vnet-vnmgr "$RPM_BUILD_ROOT"/etc/default/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/init/vnet-vnmgr.conf "$RPM_BUILD_ROOT"/etc/init/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/openvnet/vnmgr.conf "$RPM_BUILD_ROOT"/etc/openvnet/
cp "$OPENVNET_SRC_DIR"/vnet/bin/vnmgr "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin/

%post
user="vnet-vnmgr"
logfile="/var/log/openvnet/vnmgr.log"

if ! id "$user" > /dev/null 2>&1 ; then
    adduser --system --no-create-home --shell /bin/false "$user"
fi

touch "$logfile"
chown "$user"."$user" "$logfile"
