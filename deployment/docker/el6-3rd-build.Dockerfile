FROM centos:6
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
RUN yum install -y epel-release upstart
RUN yum groupinstall -y "Development Tools"
RUN yum install -y yum-utils rpmdevtools createrepo
RUN mkdir /var/tmp/openvnet
# Openvswitch build dependencies.
RUN yum install -y redhat-lsb openssl-devel
# Ruby build dependencies.
RUN yum install -y libffi-devel libyaml-devel ncurses-devel readline-devel chrpath
