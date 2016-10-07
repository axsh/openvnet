%define rubyver 2.3.1
%{?build_rubyver:%define rubyver %{build_rubyver}}
%define _prefix /opt/axsh/openvnet/ruby
%undefine _enable_debug_packages

# When rpmdev-setuptree runs, it creates $HOME/.rpmmacros then
# the rpmbuild command is modified to run /usr/lib/rpm/check-* scripts.
# This package installs the binaries to /opt so I want to suppress
# build errors from these standard checks.
%define __arch_install_post %{nil}

Name:           openvnet-ruby
Version:        %{rubyver}
Release:        1.axsh0%{?dist}
Vendor:         Axsh Co. LTD <dev@axsh.net>
License:        Ruby License/GPL - see COPYING
URL:            http://www.ruby-lang.org/
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       readline ncurses gdbm glibc openssl libyaml libffi zlib
BuildRequires:  readline-devel ncurses-devel gdbm-devel glibc-devel gcc openssl-devel make libyaml-devel libffi-devel zlib-devel chrpath file findutils rpmdevtools
Source0:        http://ftp.ruby-lang.org/pub/ruby/ruby-%{rubyver}.tar.gz
Summary:        The Ruby virtual machine(For OpenVNet bundle)
Group:          Development/Languages

%description
The Ruby binary package for OpenVNet. Key changes are:
- No docs.
- -O0 optimization (On EL6).
- RPATH is enabled and fixed to %{_libdir}.
- bundler gem is installed.
- Debug info is not stripped from the binaries.

%prep
%setup -n ruby-%{rubyver}

%build
%if %{defined el6}
export CFLAGS="$RPM_OPT_FLAGS -Wall -fno-strict-aliasing -O0 -ggdb3"
%else
export CFLAGS="$RPM_OPT_FLAGS -Wall -fno-strict-aliasing"
%endif

%configure \
  --enable-shared \
  --enable-rpath \
  --disable-install-doc \
  --without-X11 \
  --without-tk \
  --includedir=%{_includedir}/ruby \
  --libdir=%{_libdir}

make %{?_smp_mflags}

%install
# installing binaries ...
make install DESTDIR=$RPM_BUILD_ROOT

# man pages are installed under /usr.
rm -rf $RPM_BUILD_ROOT/usr

export LD_LIBRARY_PATH=$RPM_BUILD_ROOT%{_libdir}
export RUBYLIB=$(find $RPM_BUILD_ROOT%{_libdir}/ruby -type d | tr '\n' ':')
export GEM_HOME=$RPM_BUILD_ROOT%{_libdir}/ruby/gems
HACK_230=$(set +e;
  rpmdev-vercmp 2.3.0 %{rubyver} > /dev/null;
  if [ ! $? -eq 11 ]; then
    # 2.3.1 fails to load "rake/early_time.rb" due to the symbol error.
    echo "-rsingleton"
  fi
)
$RPM_BUILD_ROOT%{_prefix}/bin/ruby ${HACK_230} $RPM_BUILD_ROOT%{_prefix}/bin/gem install bundler --no-ri --no-rdoc

# Update rpath in the ELF binaries.
#for i in $(find $RPM_BUILD_ROOT -type f -and -executable); do
#  if file -b "$i" | grep -q '^ELF ' > /dev/null; then
#    chrpath --replace %{_libdir} "$i" || :
#  fi
#done

# Rewrite shebang
#for i in $(find $RPM_BUILD_ROOT%{_bindir} -type f -and -executable); do
#  if file -b "$i" | grep "script text executable" > /dev/null; then
#    t=$(mktemp)
#    cp -p $i $t
#    echo "#!/opt/axsh/openvnet/ruby/bin/ruby" > $i
#    tail -n +2 $t >> $i
#    rm -f $t
#  fi
#done

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
%{_prefix}/*
