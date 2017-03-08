# This is a little trick to allow the rpmbuild command to define a suffix for
# development (non stable) versions.
%define release 1
%{?dev_release_suffix:%define release %{dev_release_suffix}}

Name: openvnet
Version: 0.9%{?dev_release_suffix:dev}
Release: %{release}%{?dist}
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

BuildRequires: %{scl_ruby}-scldevel
BuildRequires: %{scl_ruby} %{scl_ruby}-ruby-devel %{scl_ruby}-rubygem-rake %{scl_ruby}-rubygem-bundler

Requires: openvnet-vnctl
Requires: openvnet-webapi
Requires: openvnet-vnmgr
Requires: openvnet-vna

%description
This is an empty metapackage that depends on all OpenVNet services and the vnctl client. Just a conventient way to install everything at once on a single machine.

%files
# No files in the openvnet metapackage.

%prep
OPENVNET_SRC_DIR="$RPM_SOURCE_DIR/openvnet"
if [ ! -d "$OPENVNET_SRC_DIR" ]; then
  git clone https://github.com/axsh/openvnet "$OPENVNET_SRC_DIR"
fi

%build
cd "$RPM_SOURCE_DIR/openvnet"
(
  cd "vnet"
  bundle install --path vendor/bundle --without development test --standalone
)
(
  cd "client/vnctl"
  bundle install --path vendor/bundle --without development test --standalone
)

%install
cd "$RPM_SOURCE_DIR/openvnet"
mkdir -p "$RPM_BUILD_ROOT"/etc
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/client
mkdir -p "$RPM_BUILD_ROOT"/var/log/openvnet
mkdir -p "$RPM_BUILD_ROOT"/usr/bin
cp -r ci/ci.el7/rspec_rpmbuild/conf_files/etc/default "$RPM_BUILD_ROOT"/etc/
echo "SCL_RUBY=%{scl_ruby}" >> "$RPM_BUILD_ROOT"/etc/sysconfig/openvnet
echo ". scl_source enable %{scl_ruby}" >> "$RPM_BUILD_ROOT"/etc/openvnet/vnctl-ruby
install -m 755 ci/ci.el7/rspec_rpmbuild/conf_files/usr/bin/vnctl "$RPM_BUILD_ROOT"/usr/bin/
cp vnet/Gemfile "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp vnet/Gemfile.lock "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp vnet/LICENSE "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp vnet/README.md "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp vnet/Rakefile "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
install -m 755 vnet/bin/vna "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin/
install -m 755 vnet/bin/vnflows-monitor "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin/
install -m 755 vnet/bin/vnmgr "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin/
cp -r vnet/db "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r vnet/lib "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r vnet/.bundle "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r vnet/rack "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet
cp -r client/vnctl "$RPM_BUILD_ROOT"/opt/axsh/openvnet/client/
%if %{defined strip_vendor} && "%{strip_vendor}" == "1"
tar cO --directory="vnet" \
  --exclude='*.o' \
  --exclude='.git' \
  --exclude='cache/*.gem' \
  vendor/ | tar -x --directory="${RPM_BUILD_ROOT}/opt/axsh/openvnet/vnet" -f -
%else
cp -r vnet/vendor "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
%endif

%package common
#
# openvnet-common package
#

Summary: Common code for all OpenVNet services.

# We turn off automatic dependecy detection because rpmbuild will see some
# things in ruby gems under vendor that it wrongly detects as a dependency.
AutoReqProv: no

Requires: zeromq3
Requires: mysql-libs
Requires: %{scl_ruby} %{scl_ruby}-rubygem-bundler

# The zeromq3-devel package is required because it provides the /usr/lib64/libzmq.so file.
# That file is just a symlink to /usr/lib64/libzmq.so.3.0.0 which is provided by the zerom13
# runtime package but we will need it for our 0mq client to work. Why this symlink is included
# in the development package instead of the runtime package is beyond me.
Requires: zeromq3-devel

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
%config(noreplace) /etc/openvnet/common.conf
%config(noreplace) /etc/sysconfig/openvnet

%package webapi
#
# openvnet-webapi package
#

Summary: OpenVNet's RESTful WebAPI.
BuildArch: noarch

Requires: openvnet-common

%description webapi
This package contains OpenVNet's Restful WebAPI. Users can interact with OpenVNet by sending HTTP requests to this API.

%files webapi
/opt/axsh/openvnet/vnet/rack
%config(noreplace) /etc/openvnet/webapi.conf
%config %{_unitdir}/vnet-webapi.service
%config(noreplace) /etc/systemd/system/vnet-webapi.service.d/env.conf

%post webapi
user="vnet-webapi"
logfile="/var/log/openvnet/webapi.log"

if ! id "$user" > /dev/null 2>&1 ; then
    adduser --system --no-create-home --home-dir /opt/axsh/openvnet --shell /bin/false "$user"
fi

touch "$logfile"
chown "$user"."$user" "$logfile"

%{?systemd_post:%systemd_post vnet-webapi.service}

%postun webapi
%{?systemd_postun:%systemd_postun vnet-webapi.service}

%preun webapi
%{?systemd_preun:%systemd_preun vnet-webapi.service}

%package vnmgr
#
# openvnet-vnmgr package
#

Summary: Virtual Network Manager for OpenVNet.
BuildArch: noarch

Requires: openvnet-common


%description vnmgr
This package contains OpenVNet's VNMGR process. This process acts as a frontend for the MySQL database and broadcasts commands to VNA processes.

%files vnmgr
/opt/axsh/openvnet/vnet/bin/vnmgr
%config(noreplace) /etc/openvnet/vnmgr.conf
%config %{_unitdir}/vnet-vnmgr.service

%post vnmgr
user="vnet-vnmgr"
logfile="/var/log/openvnet/vnmgr.log"

if ! id "$user" > /dev/null 2>&1 ; then
    adduser --system --no-create-home --home-dir /opt/axsh/openvnet --shell /bin/false "$user"
fi

touch "$logfile"
chown "$user"."$user" "$logfile"

%{?systemd_post:%systemd_post vnet-vnmgr.service}

%postun vnmgr
%{?systemd_postun:%systemd_postun vnet-vnmgr.service}

%preun vnmgr
%{?systemd_preun:%systemd_preun vnet-vnmgr.service}

%package vna
#
# openvnet-vna package
#

Summary: Virtual network agent for OpenVNet.
BuildArch: noarch

Requires: openvnet-common
# Open vSwitch itself is no longer required to be running on the same host as vna
# but even when using a remote ovs, vna still depends on ovs-ofctl which is provided
# by this package.
Requires: openvswitch >= 2.4, openvswitch < 2.5

%description vna
This package contains OpenVNet's VNA process. This is an OpenFlow controller that sends commands to Open vSwitch to implement virtual networks.

%files vna
/opt/axsh/openvnet/vnet/bin/vna
/opt/axsh/openvnet/vnet/bin/vnflows-monitor
%config(noreplace) /etc/openvnet/vna.conf
%config %{_unitdir}/vnet-vna.service

%post vna
%{?systemd_post:%systemd_post vnet-vna.service}

%postun vna
%{?systemd_postun:%systemd_postun vnet-vna.service}

%preun vna
%{?systemd_preun:%systemd_preun vnet-vna.service}

%package vnctl
#
# openvnet-vnctl package
#

Summary: A commandline client for OpenVNet's WebAPI.
BuildArch: noarch

# We turn off automatic dependecy detection because rpmbuild will see some
# things in ruby gems under vendor that it wrongly detects as a dependency.
AutoReqProv: no
Requires: %{scl_ruby} %{scl_ruby}-rubygem-bundler

%description vnctl
This package contains the vnctl client for OpenVNet's WebAPI. It's a simple commandline client that just sends plain http calls to the API and prints their response.

%files vnctl
%dir /etc/openvnet
/opt/axsh/openvnet/client/vnctl
/usr/bin/vnctl
%config(noreplace) /etc/openvnet/vnctl.conf
%config /etc/openvnet/vnctl-ruby
