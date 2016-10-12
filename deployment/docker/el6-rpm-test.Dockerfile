FROM centos:6
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
RUN yum install -y epel-release
ADD deployment/docker/yum.repo/dev.repo /etc/yum.repos.d/
