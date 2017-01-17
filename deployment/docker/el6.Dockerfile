FROM centos:6
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
ARG SCL_RUBY=rh-ruby22
RUN yum install -y centos-release-scl
# Determine the SCL Ruby version here
RUN yum install -y ${SCL_RUBY}-ruby-devel
RUN yum install -y yum-utils createrepo rpm-build rpmdevtools rsync sudo
RUN yum install -y make gcc gcc-c++ git \
    mysql-devel sqlite-devel libpcap-devel
RUN mkdir /var/tmp/openvnet
ADD deployment/docker/yum.repo/dev.repo /etc/yum.repos.d/
# Only enables "openvnet-third-party" repo.
RUN yum-config-manager --disable openvnet
