Name: openvnet-vnctl
Version: 0.7
Release: 2
Summary: A commandline client for OpenVNet's WebAPI.
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://openvnet.org
Source: https://github.com/axsh/openvnet
License: LGPLv3

BuildArch: noarch

Requires: openvnet-ruby

%Description
This package contains the vnctl client for OpenVNet's WebAPI. It's a simple commandline client that just sends plain http calls to the API and prints their response.

%prep
#TODO: make sure we have ruby and bundle installed
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
if [ ! -d "$OPENVNET_SRC_DIR" ]; then
  git clone https://github.com/axsh/openvnet "$OPENVNET_SRC_DIR"
fi
cd "$OPENVNET_SRC_DIR/client/vnctl"
bundle install --path vendor/bundle --without development test --standalone

%files
%dir /etc/openvnet
/opt/axsh/openvnet/client/vnctl
/usr/bin/vnctl
%config /etc/openvnet/vnctl.conf

%install
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
mkdir -p "$RPM_BUILD_ROOT"/etc/openvnet
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/client
mkdir -p "$RPM_BUILD_ROOT"/usr/bin
cp -r "$OPENVNET_SRC_DIR"/client/vnctl "$RPM_BUILD_ROOT"/opt/axsh/openvnet/client/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/usr/bin/vnctl "$RPM_BUILD_ROOT"/usr/bin/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/openvnet/vnctl.conf "$RPM_BUILD_ROOT"/etc/openvnet
