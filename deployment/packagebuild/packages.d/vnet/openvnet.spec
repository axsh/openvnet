%define debug_package %{nil}
# This is a little trick to allow the rpmbuild command to define a suffix for
# development (non stable) versions.
%define release 1
%{?dev_release_suffix:%define release %{dev_release_suffix}}

Name: openvnet
Version: 0.8%{?dev_release_suffix:dev}
Release: %{release}%{?dist}
Summary: Metapackage that depends on all other OpenVNet packages.
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://openvnet.org
Source: %{name}.tar.gz
License: LGPLv3

BuildArch: x86_64

BuildRequires: rpmdevtools
# The requirements below are for building trema
BuildRequires: make
BuildRequires: gcc-c++ gcc
BuildRequires: git
%if 0%{?el6}
BuildRequires: mysql-devel
%else
BuildRequires: mysql-community-devel
%endif
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
%setup -qn %{name}

%build
pushd "vnet"
bundle install --path vendor/bundle --without development test --standalone
popd
pushd "client/vnctl"
bundle install --path vendor/bundle --without development test --standalone
popd

%files
# No files in the openvnet metapackage.

%install
mkdir -p "$RPM_BUILD_ROOT"/etc
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/bin
mkdir -p "$RPM_BUILD_ROOT"/opt/axsh/openvnet/client
mkdir -p "$RPM_BUILD_ROOT"/var/log/openvnet
mkdir -p "$RPM_BUILD_ROOT"/usr/bin
cp -r deployment/conf/etc "$RPM_BUILD_ROOT"/
install -m 755 deployment/conf/usr/bin/vnctl "$RPM_BUILD_ROOT"/usr/bin/
%if 0%{?el6}
cp -r deployment/conf.el6/etc/* "$RPM_BUILD_ROOT"/etc/
%else
install -m 755 -d "$RPM_BUILD_ROOT"%{_unitdir}
cp deployment/conf.el7/systemd/*.service "$RPM_BUILD_ROOT"%{_unitdir}
install -m 755 -d "$RPM_BUILD_ROOT"/etc/sysconfig
cp deployment/conf.el7/sysconfig/* "$RPM_BUILD_ROOT"/etc/sysconfig
%endif
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
cp -r vnet/vendor "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r vnet/.bundle "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet/
cp -r vnet/rack "$RPM_BUILD_ROOT"/opt/axsh/openvnet/vnet
cp -r client/vnctl "$RPM_BUILD_ROOT"/opt/axsh/openvnet/client/

#
# openvnet-common package
#

%package common
Summary: Common code for all OpenVNet services.

# We turn off automatic dependecy detection because rpmbuild will see some
# things in ruby gems under vendor that it wrongly detects as a dependency.
AutoReqProv: no

Requires: zeromq3
%if 0%{?el6}
Requires: mysql-libs
%else
Requires: mysql-community-libs
%endif
Requires: openvnet-ruby

# The zeromq3-devel package is required because it provides the /usr/lib64/libzmq.so file.
# That file is just a symlink to /usr/lib64/libzmq.so.3.0.0 which is provided by the zerom13
# runtime package but we will need it for our 0mq client to work. Why this symlink is included
# in the development package instead of the runtime package is beyond me.
Requires: zeromq3-devel
# for yum-builddep
BuildRequires: zeromq3-devel

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
%if 0%{?el6}
%config(noreplace) /etc/default/openvnet
%endif
#
# openvnet-webapi package
#

%package webapi
Summary: OpenVNet's RESTful WebAPI.
BuildArch: noarch

Requires: openvnet-common
%if 0%{?el6} == 0
%{systemd_requires}
%endif

%description webapi
This package contains OpenVNet's Restful WebAPI. Users can interact with OpenVNet by sending HTTP requests to this API.

%files webapi
/opt/axsh/openvnet/vnet/rack
%config(noreplace) /etc/openvnet/webapi.conf
%if 0%{?el6}
%config(noreplace) /etc/default/vnet-webapi
%config /etc/init/vnet-webapi.conf
%else
%config(noreplace) /etc/sysconfig/vnet-webapi
%config %{_unitdir}/vnet-webapi.service
%endif

%post webapi
user="vnet-webapi"

if ! id "$user" > /dev/null 2>&1 ; then
    adduser --system --no-create-home --shell /bin/false "$user"
fi

%if 0%{?el6}
logfile="/var/log/openvnet/webapi.log"
touch "$logfile"
chown "$user"."$user" "$logfile"
%else
%systemd_post vnet-webapi.service

%preun webapi
%systemd_preun vnet-webapi.service

%postun webapi
%systemd_postun vnet-webapi.service
%endif

#
# openvnet-vnmgr package
#

%package vnmgr
Summary: Virtual Network Manager for OpenVNet.
BuildArch: noarch

Requires: openvnet-common
%if 0%{?el6} == 0
%{systemd_requires}
%endif

%description vnmgr
This package contains OpenVNet's VNMGR process. This process acts as a frontend for the MySQL database and broadcasts commands to VNA processes.

%files vnmgr
/opt/axsh/openvnet/vnet/bin/vnmgr
%config(noreplace) /etc/openvnet/vnmgr.conf
%if 0%{?el6}
%config(noreplace) /etc/default/vnet-vnmgr
%config /etc/init/vnet-vnmgr.conf
%else
%config %{_unitdir}/vnet-vnmgr.service
%endif

%post vnmgr
user="vnet-vnmgr"

if ! id "$user" > /dev/null 2>&1 ; then
    adduser --system --no-create-home --shell /bin/false "$user"
fi

%if 0%{?el6}
logfile="/var/log/openvnet/vnmgr.log"
touch "$logfile"
chown "$user"."$user" "$logfile"
%else
%systemd_post vnet-vnmgr.service

%preun vnmgr
%systemd_preun vnet-vnmgr.service

%postun vnmgr
%systemd_postun vnet-vnmgr.service
%endif

#
# openvnet-vna package
#

%package vna

Summary: Virtual network agent for OpenVNet.
BuildArch: noarch

Requires: openvnet-common
Requires: openvswitch = 2.3.1
%if 0%{?el6} == 0
%{systemd_requires}
%endif

%description vna
This package contains OpenVNet's VNA process. This is an OpenFlow controller that sends commands to Open vSwitch to implement virtual networks.

%files vna
/opt/axsh/openvnet/vnet/bin/vna
/opt/axsh/openvnet/vnet/bin/vnflows-monitor
%config(noreplace) /etc/openvnet/vna.conf
%if 0%{?el6}
%config(noreplace) /etc/default/vnet-vna
%config /etc/init/vnet-vna.conf
%else
%config %{_unitdir}/vnet-vna.service
%endif


%if 0%{?el6} == 0
%post vna
%systemd_post vnet-vna.service

%preun vna
%systemd_preun vnet-vna.service

%postun vna
%systemd_postun vnet-vna.service
%endif

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
%config(noreplace) /etc/openvnet/vnctl.conf
