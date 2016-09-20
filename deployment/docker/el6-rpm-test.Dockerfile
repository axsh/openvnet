FROM centos:6
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
RUN yum install -y epel-release
ADD deployment/yum_repositories/development/openvnet-third-party.repo /etc/yum.repos.d/
ADD deployment/yum_repositories/development/docker-rpm-test.repo /etc/yum.repos.d/
