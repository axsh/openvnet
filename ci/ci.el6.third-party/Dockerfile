FROM centos:6
WORKDIR /var/tmp/openvnet
RUN mkdir -p /var/tmp/openvnet
ADD ci/ci.el6/rspec_rpmbuild/fastestmirror.conf /etc/yum/pluginconf.d/

RUN ["yum", "install", "-y", "epel-release", "upstart"]
RUN ["yum",  "groupinstall", "-y", "Development Tools"]
RUN ["yum", "install", "-y", "yum-utils", "rpmdevtools", "createrepo", "redhat-lsb", "openssl-devel", "libffi-devel", "libyaml-devel", "ncurses-devel", "readline-devel", "chrpath"]

ARG BRANCH
ARG VERSOIN
ARG RELEASE_SUFFIX
ARG BUILD_URL
ARG ISO8601_TIMESTAMP
ARG LONG_SHA

LABEL "jp.axsh.vendor"="Axsh Co. LTD"  \
      "jp.axsh.project"="OpenVNet" \
      "jp.axsh.task"="el6.third-party" \
      "jp.axsh.branch"="$BRANCH" \
      "jp.axsh.release_suffix"="$RELEASE_SUFFIX" \
      "jp.axsh.buildtime"="$ISO8601_TIMESTAMP" \
      "jp.axsh.build_url"="$BUILD_URL" \
      "jp.axsh.git_commit"="$LONG_SHA"

VOLUME /repos

COPY [".", "/var/tmp/openvnet"]
ENTRYPOINT ["ci/ci.el6.third-party/build_packages_third_party.sh"]
