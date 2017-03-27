FROM centos:6

WORKDIR /var/tmp/openvnet/

ADD deployment/docker/fastestmirror.conf /etc/yum/pluginconf.d/

RUN ["yum", "install", "-y", "epel-release"]
RUN ["yum", "install", "-y", "rsync", "bridge-utils", "qemu-kvm", "qemu-system-x86", "parted", "sudo", "openssh-clients", "ncat", "git", "which", "file"]
RUN ["yum", "install", "-y", "nfs-utils", "nfs-utils-lib" ]
RUN mkdir /var/tmp/openvnet
RUN mkdir /opt/axsh/openvnet
RUN mkdir /repos
RUN mkdir /cache

ARG BRANCH
ARG RELEASE_SUFFIX
ARG BUILD_URL
ARG ISO8601_TIMESTAMP
ARG LONG_SHA

LABEL "jp.axsh.vendor"="Axsh Co. LTD"  \
      "jp.axsh.project"="OpenVNet" \
      "jp.axsh.task"="rspec/rpm build" \
      "jp.axsh.branch"="$BRANCH" \
      "jp.axsh.release_suffix"="$RELEASE_SUFFIX" \
      "jp.axsh.buildtime"="$ISO8601_TIMESTAMP" \
      "jp.axsh.build_url"="$BUILD_URL" \
      "jp.axsh.git_commit"="$LONG_SHA"

VOLUME /cache
VOLUME /repos

# This directory is shared with the kvm maachine
COPY [".", "/opt/axsh/openvnet"]

COPY [".", "/var/tmp/openvnet"]
ENTRYPOINT ["ci/ci.el6/rspec_rpmbuild/run_build.sh"]

