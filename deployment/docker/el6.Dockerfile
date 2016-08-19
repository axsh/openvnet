FROM centos:6
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
RUN yum install -y yum-utils createrepo rpm-build rpmdevtools rsync sudo
RUN yum install -y make gcc gcc-c++ git \
    mysql-devel sqlite-devel libpcap-devel
RUN mkdir /var/tmp/openvnet