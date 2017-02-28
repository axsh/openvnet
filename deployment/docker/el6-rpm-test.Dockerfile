FROM centos:6
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
ADD deployment/docker/fastestmirror.conf /etc/yum/pluginconf.d/
RUN yum install -y epel-release centos-release-scl
ADD deployment/docker/yum.repo/dev.repo /etc/yum.repos.d/
