%bcond_without pgm

Name:           openvnet-zeromq4
Version:        4.2.3
Release:        1%{?dist}
Summary:        Software library for fast, message-based applications

Group:          System Environment/Libraries
License:        LGPLv3+ with exceptions
URL:            http://www.zeromq.org
Source0:        https://github.com/zeromq/libzmq/releases/download/v%{version}/zeromq-%{version}.tar.gz
BuildRequires:  glib2-devel
BuildRequires:  libuuid-devel
%if %{with pgm}
BuildRequires:  openpgm-devel
%endif


%description
The 0MQ lightweight messaging kernel is a library which extends the
standard socket interfaces with features traditionally provided by
specialized messaging middle-ware products. 0MQ sockets provide an
abstraction of asynchronous message queues, multiple messaging
patterns, message filtering (subscriptions), seamless access to
multiple transport protocols and more.

This package contains the ZeroMQ shared library for versions 4.x.


%package devel
Summary:        Development files for %{name}
Group:          Development/Libraries
Requires:       %{name}%{?_isa} = %{version}-%{release}
Conflicts:      zeromq-devel%{?_isa}


%description devel
The %{name}-devel package contains libraries and header files for 
developing applications that use %{name} 4.x.


%prep
%setup -qn zeromq-%{version}

# remove all files in foreign except Makefiles
#rm -v $(find foreign -type f | grep -v Makefile)


%build
%configure \
%if %{with pgm}
            --with-system-pgm \
%endif
            --disable-static
make %{?_smp_mflags}


%install
make install DESTDIR=%{buildroot} INSTALL="install -p"

# remove *.la and create libzmq.so
rm %{buildroot}%{_libdir}/libzmq.la
ln -s libzmq.so.5 %{buildroot}%{_libdir}/libzmq.so


%check
make check \
%ifarch s390 s390x
    || :
%else
    %{nil}
%endif


%post -p /sbin/ldconfig


%postun -p /sbin/ldconfig


%files
%doc AUTHORS ChangeLog COPYING COPYING.LESSER NEWS
%{_bindir}/curve_keygen
%{_libdir}/libzmq.so.*

%files devel
%{_libdir}/libzmq.so
%{_libdir}/pkgconfig/libzmq.pc
%{_includedir}/zmq*
%{_mandir}/man3/zmq*.3*
%{_mandir}/man7/zmq*.7*


%changelog
* Fri Sep 28 2018 Jari Sundell <sundell.software at gmail.com> - 4.2.3-1
- update to 4.2.3

* Sat Feb 21 2015 Jose Pedro Oliveira <jose.p.oliveira.oss at gmail.com> - 3.2.5-1
- update to 3.2.5

* Sat Dec 13 2014 Dan Horák <dan[at]danny.cz> - 3.2.4-4
- ignore test results on s390(x), the timeouts don't work reliably (related #1116795)

* Mon Aug 18 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 3.2.4-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_22_Mass_Rebuild

* Sat Jun 07 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 3.2.4-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Fri Sep 20 2013 Jose Pedro Oliveira <jpo at di.uminho.pt> - 3.2.4-1
- update to 3.2.4

* Thu Aug  8 2013 Thomas Spura <tomspur@fedoraproject.org> - 3.2.3-4
- correct license to contain classpath exceptions (#921384)

* Sun Aug 04 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 3.2.3-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_20_Mass_Rebuild

* Fri May 17 2013 Thomas Spura <tomspur@fedoraproject.org> - 3.2.3-2
- Rebuilt for openpgm-5.2 and sed correct version into configure (#963894)

* Tue May  7 2013 Thomas Spura <tomspur@fedoraproject.org> - 3.2.3-1
- update to 3.2.3 (fixes #914985)

* Fri Feb 15 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 3.2.2-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Mon Jan 14 2013 Thomas Spura <tomspur@fedoraproject.org> - 3.2.2-3
- delete foreign files with dubious license in %%prep (#892111)


* Fri Dec 14 2012 Thomas Spura <tomspur@fedoraproject.org> - 3.2.2-2
- add bcond_without pgm macro (Jose Pedro Oliveira, #867182)
- remove bundled pgm
- add zeromq-3 git repository

* Tue Nov 27 2012 Andrew Niemantsverdriet <andrewniemants@gmail.com - 3.2.2-1
- update to 3.2.2

* Wed Oct 17 2012 Thomas Spura <tomspur@fedoraproject.org> - 3.2.1-0.1.rc2
- update to 3.2.1-rc2 (#867182)

* Fri Oct 12 2012 Thomas Spura <tomspur@fedoraproject.org> - 3.2.0-0.3.20121009git1ef63bc
- remove defattr and rm -rf buildroot

* Wed Oct 10 2012 Thomas Spura <tomspur@fedoraproject.org> - 3.2.0-0.2.20121009git1ef63bc
- delete defattr and remove (>el5) macro to only target el6+ and fc17+
- conflict with zeromq-devel
- use proper version

* Wed Oct 10 2012 Thomas  Spura <tomspur@fedoraproject.org> - 3.2.0-0.1
- update to 3.2.0 past rc1

* Sun Jul 22 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.2.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Thu Apr 26 2012 Thomas Spura <tomspur@fedoraproject.org> - 2.2.0-1
- update to 2.2.0

* Sat Jan  7 2012 Thomas Spura <tomspur@fedoraproject.org> - 2.1.11-1
- update to 2.1.11 (as part of rebuilding with gcc-4.7)

* Tue Sep 20 2011 Thomas Spura <tomspur@fedoraproject.org> - 2.1.9-1
- update to 2.1.9
- add check section

* Wed Apr  6 2011 Thomas Spura <tomspur@fedoraproject.org> - 2.1.4-1
- update to new version (#690199)

* Wed Mar 23 2011 Thomas Spura <tomspur@fedoraproject.org> - 2.1.3-1
- update to new version (#690199)
- utils subpackage was removed upstream
  (obsolete it)

* Tue Feb 08 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.0.10-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Thu Jan 13 2011 Pavel Zhukov <pavel@zhukoff.net> - 2.0.10-1
- update version
- add rpath delete
- change includedir filelist

* Fri Aug 27 2010 Thomas Spura <tomspur@fedoraproject.org> - 2.0.8-1
- update to new version

* Fri Jul 23 2010 Thomas Spura <tomspur@fedoraproject.org> - 2.0.7-4
- upstream VCS changed
- remove buildroot / %%clean
- change descriptions

* Tue Jul 20 2010 Thomas Spura <tomspur@fedoraproject.org> - 2.0.7-3
- move binaries to seperate utils package

* Sat Jun 12 2010 Thomas Spura <tomspur@fedoraproject.org> - 2.0.7-2
- remove BR: libstdc++-devel
- move man3 to the devel package
- change group to System Environment/Libraries

* Sat Jun 12 2010 Thomas Spura <tomspur@fedoraproject.org> - 2.0.7-1
- initial package (based on upstreams example one)
