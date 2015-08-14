# This is a little trick to allow the rpmbuild command to define a suffix for
# development (non stable) versions.
%define release 2
%{?dev_release_suffix:%define release %{dev_release_suffix}}

Name: openvnet
Version: 0.7%{?dev_release_suffix:dev}
Release: %{release}.el6
Summary: Metapackage that depends on all other OpenVNet packages.
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://openvnet.org
Source: https://github.com/axsh/openvnet
License: LGPLv3

BuildArch: x86_64

BuildRequires: rpmdevtools
# The requirements below are for building trema
BuildRequires: make
BuildRequires: gcc-c++ gcc
BuildRequires: git
BuildRequires: mysql-devel
BuildRequires: sqlite-devel
BuildRequires: libpcap-devel

# We require openvnet-ruby to run bundle install.
# By using openvnet-ruby we ensure that the downloaded gems are compatible.
BuildRequires: openvnet-ruby = 2.1.1.axsh0

Requires: openvnet-vnctl
Requires: openvnet-webapi
Requires: openvnet-vnmgr
Requires: openvnet-vna

%description
This is an empty metapackage that depends on all OpenVNet services and the vnctl client. Just a conventient way to install everything at once on a single machine.

%prep
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
BUNDLE_PATH="/opt/axsh/openvnet/ruby/bin/bundle"
if [ ! -d "$OPENVNET_SRC_DIR" ]; then
  git clone https://github.com/axsh/openvnet "$OPENVNET_SRC_DIR"
fi
cd "$OPENVNET_SRC_DIR/vnet"
"$BUNDLE_PATH" install --path vendor/bundle --without development test --standalone
cd "$OPENVNET_SRC_DIR/client/vnctl"
"$BUNDLE_PATH" install --path vendor/bundle --without development test --standalone

%files
# No files in the openvnet metapackage.

%install
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
mkdir -p "$RPM_BUILD_ROOT"/etc
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/client
mkdir -p "$RPM_BUILD_ROOT"/var/log/openvnet
mkdir -p "$RPM_BUILD_ROOT"/usr/bin
cp -r "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/default "$RPM_BUILD_ROOT"/etc/
cp -r "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/init "$RPM_BUILD_ROOT"/etc/
cp -r "$OPENVNET_SRC_DIR"/deployment/conf_files/etc/openvnet "$RPM_BUILD_ROOT"/etc/
cp "$OPENVNET_SRC_DIR"/deployment/conf_files/usr/bin/vnctl "$RPM_BUILD_ROOT"/usr/bin/
cp "$OPENVNET_SRC_DIR"/vnet/Gemfile "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp "$OPENVNET_SRC_DIR"/vnet/Gemfile.lock "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp "$OPENVNET_SRC_DIR"/vnet/LICENSE "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp "$OPENVNET_SRC_DIR"/vnet/README.md "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp "$OPENVNET_SRC_DIR"/vnet/Rakefile "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp "$OPENVNET_SRC_DIR"/vnet/bin/vna "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin/
cp "$OPENVNET_SRC_DIR"/vnet/bin/vnflows-monitor "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin/
cp "$OPENVNET_SRC_DIR"/vnet/bin/vnmgr "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin/
cp -r "$OPENVNET_SRC_DIR"/vnet/db "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r "$OPENVNET_SRC_DIR"/vnet/lib "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r "$OPENVNET_SRC_DIR"/vnet/vendor "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r "$OPENVNET_SRC_DIR"/vnet/.bundle "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r "$OPENVNET_SRC_DIR"/vnet/rack "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet
cp -r "$OPENVNET_SRC_DIR"/client/vnctl "$RPM_BUILD_ROOT"/opt/axsh/openvnet/client/

#
# openvnet-common package
#

%package common
Summary: Common code for all OpenVNet services.

# We turn off automatic dependecy detection because rpmbuild will see some
# things in ruby gems under vendor that it wrongly detects as a dependency.
AutoReqProv: no

Requires: zeromq
Requires: openvnet-ruby

%description common
This package contains all the common code for OpenVNet's services. All of the OpenVNet services depend on this package.

%files common
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

#
# openvnet-webapi package
#

%package webapi
Summary: OpenVNet's RESTful WebAPI.
BuildArch: noarch

Requires: openvnet-common


%description webapi
This package contains OpenVNet's Restful WebAPI. Users can interact with OpenVNet by sending HTTP requests to this API.

%files webapi
/opt/axsh/openvnet/vnet/rack
%config /etc/openvnet/webapi.conf
%config /etc/default/vnet-webapi
%config /etc/init/vnet-webapi.conf

%post webapi
user="vnet-webapi"
logfile="/var/log/openvnet/webapi.log"

if ! id "$user" > /dev/null 2>&1 ; then
    adduser --system --no-create-home --shell /bin/false "$user"
fi

touch "$logfile"
chown "$user"."$user" "$logfile"

#
# openvnet-vnmgr package
#

%package vnmgr
Summary: Virtual Network Manager for OpenVNet.
BuildArch: noarch

Requires: openvnet-common

%description vnmgr
This package contains OpenVNet's VNMGR process. This process acts as a frontend for the MySQL database and broadcasts commands to VNA processes.

%files vnmgr
/opt/axsh/openvnet/vnet/bin/vnmgr
%config /etc/openvnet/vnmgr.conf
%config /etc/default/vnet-vnmgr
%config /etc/init/vnet-vnmgr.conf

%post vnmgr
user="vnet-vnmgr"
logfile="/var/log/openvnet/vnmgr.log"

if ! id "$user" > /dev/null 2>&1 ; then
    adduser --system --no-create-home --shell /bin/false "$user"
fi

touch "$logfile"
chown "$user"."$user" "$logfile"

#
# openvnet-vna package
#

%package vna

Summary: Virtual network agent for OpenVNet.
BuildArch: noarch

Requires: openvnet-common
Requires: openvswitch = 2.3.1

%description vna
This package contains OpenVNet's VNA process. This is an OpenFlow controller that sends commands to Open vSwitch to implement virtual networks.

%files vna
/opt/axsh/openvnet/vnet/bin/vna
/opt/axsh/openvnet/vnet/bin/vnflows-monitor
%config /etc/openvnet/vna.conf
%config /etc/default/vnet-vna
%config /etc/init/vnet-vna.conf

#
# openvnet-vnctl package
#

%package vnctl

Summary: A commandline client for OpenVNet's WebAPI.
BuildArch: noarch

# We turn off automatic dependecy detection because rpmbuild will see some
# things in ruby gems under vendor that it wrongly detects as a dependency.
AutoReqProv: no

Requires: openvnet-ruby

%description vnctl
This package contains the vnctl client for OpenVNet's WebAPI. It's a simple commandline client that just sends plain http calls to the API and prints their response.

%files vnctl
%dir /etc/openvnet
/opt/axsh/openvnet/client/vnctl
/usr/bin/vnctl
%config /etc/openvnet/vnctl.conf
