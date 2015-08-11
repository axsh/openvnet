Name: openvnet-common
Version: 0.7
Release: 2
Summary: Common code for all OpenVNet services.
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://openvnet.org
Source: https://github.com/axsh/openvnet
License: LGPLv3

BuildArch: x86_64

BuildRequires: rpmdevtools
BuildRequires: make
BuildRequires: gcc-c++ gcc
BuildRequires: git
BuildRequires: mysql-devel
BuildRequires: sqlite-devel
BuildRequires: libpcap-devel

# We turn off automatic dependecy detection because rpmbuild will see some
# things in ruby gems under vendor that it wrongly detects as a dependency.
AutoReqProv: no

Requires: zeromq
Requires: openvnet-ruby

%Description
This package contains all the common code for OpenVNet's services. All of the OpenVNet services depend on this package.

%prep
#TODO: make sure we have ruby and bundle installed
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
if [ ! -d "$OPENVNET_SRC_DIR" ]; then
  git clone https://github.com/axsh/openvnet "$OPENVNET_SRC_DIR"
fi
cd "$OPENVNET_SRC_DIR/vnet"
bundle install --path vendor/bundle --without development test --standalone

%files
%dir /etc/openvnet
%dir /opt/axsh/openvnet/vnet
%dir /opt/axsh/openvnet/vnet/bin
%dir /var/log/openvnet
/opt/axsh/openvnet/vnet/Gemfile
/opt/axsh/openvnet/vnet/Gemfile.lock
/opt/axsh/openvnet/vnet/LICENSE
/opt/axsh/openvnet/vnet/README.md
/opt/axsh/openvnet/vnet/Rakefile
/opt/axsh/openvnet/vnet/db
/opt/axsh/openvnet/vnet/lib
/opt/axsh/openvnet/vnet/vendor
/opt/axsh/openvnet/vnet/.bundle
%config /etc/openvnet/common.conf
%config /etc/default/openvnet

%install
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
mkdir -p "$RPM_BUILD_ROOT"/etc/openvnet
mkdir -p "$RPM_BUILD_ROOT"/etc/default
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin
mkdir -p "$RPM_BUILD_ROOT"/var/log/openvnet
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/default/openvnet "$RPM_BUILD_ROOT"/etc/default/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/openvnet/common.conf "$RPM_BUILD_ROOT"/etc/openvnet/
cp "$OPENVNET_SRC_DIR"/vnet/Gemfile "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp "$OPENVNET_SRC_DIR"/vnet/Gemfile.lock "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp "$OPENVNET_SRC_DIR"/vnet/LICENSE "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp "$OPENVNET_SRC_DIR"/vnet/README.md "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp "$OPENVNET_SRC_DIR"/vnet/Rakefile "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r "$OPENVNET_SRC_DIR"/vnet/db "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r "$OPENVNET_SRC_DIR"/vnet/lib "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r "$OPENVNET_SRC_DIR"/vnet/vendor "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r "$OPENVNET_SRC_DIR"/vnet/.bundle "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
