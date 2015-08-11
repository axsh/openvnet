Name: openvnet-webapi
Version: 0.7
Release: 2
Summary: OpenVNet's RESTful WebAPI.
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://openvnet.org
Source: https://github.com/axsh/openvnet
License: LGPLv3

BuildArch: noarch

Requires: openvnet-common

%Description
This package contains OpenVNet's Restful WebAPI. Users can interact with OpenVNet by sending HTTP requests to this API.

%files
/opt/axsh/openvnet/vnet/rack
%config /etc/openvnet/webapi.conf
%config /etc/default/vnet-webapi
%config /etc/init/vnet-webapi.conf

%install
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
mkdir -p "$RPM_BUILD_ROOT"/etc/openvnet
mkdir -p "$RPM_BUILD_ROOT"/etc/default
mkdir -p "$RPM_BUILD_ROOT"/etc/init
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/default/vnet-webapi "$RPM_BUILD_ROOT"/etc/default/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/init/vnet-webapi.conf "$RPM_BUILD_ROOT"/etc/init/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/openvnet/webapi.conf "$RPM_BUILD_ROOT"/etc/openvnet/
cp -r "$OPENVNET_SRC_DIR"/vnet/rack "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet

%post
user="vnet-webapi"
logfile="/var/log/openvnet/webapi.log"

if ! id "$user" > /dev/null 2>&1 ; then
    adduser --system --no-create-home --shell /bin/false "$user"
fi

touch "$logfile"
chown "$user"."$user" "$logfile"
