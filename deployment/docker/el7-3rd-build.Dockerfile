FROM centos:7
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
RUN yum install -y epel-release
RUN yum groupinstall -y "Development Tools"
RUN yum install -y yum-utils rpmdevtools createrepo
RUN mkdir /var/tmp/openvnet
# Openvswitch build dependencies.
RUN yum install -y redhat-lsb autoconf openssl-devel automake libtool \
  groff graphviz python-twisted-core python-zope-interface PyQt4 \
  checkpolicy libcap-ng-devel selinux-policy-devel
# Ruby build dependencies.
RUN yum install -y openssl-devel libffi-devel libyaml-devel ncurses-devel readline-devel chrpath
