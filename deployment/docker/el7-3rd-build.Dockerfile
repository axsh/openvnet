FROM centos:7
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
RUN yum install -y epel-release
RUN yum groupinstall -y "Development Tools"
RUN yum install -y yum-utils rpmdevtools
RUN mkdir /var/tmp/openvnet
