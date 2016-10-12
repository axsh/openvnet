FROM centos:7
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
RUN yum install -y yum-utils createrepo rpm-build rpmdevtools rsync sudo
RUN yum install -y make gcc gcc-c++ git \
    mariadb-devel sqlite-devel libpcap-devel
RUN mkdir /var/tmp/openvnet
ADD deployment/docker/yum.repo/dev.repo /etc/yum.repos.d/
# Only enables "openvnet-third-party" repo.
RUN yum-config-manager --disable openvnet
