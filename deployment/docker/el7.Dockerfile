FROM centos:7
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
ARG SCL_RUBY=rh-ruby23
ADD deployment/docker/fastestmirror.conf /etc/yum/pluginconf.d/
RUN yum install -y centos-release-scl
# Determine the SCL Ruby version here
RUN yum install -y ${SCL_RUBY}-build
RUN yum install -y epel-release
RUN yum install -y zeromq3-devel
RUN yum install -y yum-utils createrepo rpm-build rpmdevtools rsync sudo
RUN yum install -y make gcc gcc-c++ git \
    mariadb-devel sqlite-devel libpcap-devel mariadb
RUN mkdir /var/tmp/openvnet
ADD deployment/docker/yum.repo/dev.repo /etc/yum.repos.d/
# Only enables "openvnet-third-party" repo.
RUN yum-config-manager --disable openvnet
RUN yum install -y mariadb-server
RUN mysql_install_db
RUN chown mysql:mysql -R /var/lib/mysql