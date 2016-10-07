FROM centos:6
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
RUN yum install -y epel-release upstart
RUN yum groupinstall -y "Development Tools"
RUN yum install -y yum-utils rpmdevtools
RUN mkdir /var/tmp/openvnet
