FROM centos:7
WORKDIR /var/tmp

ADD ci/ci.el7/rspec_rpmbuild/fastestmirror.conf /etc/yum/pluginconf.d/
RUN ["yum", "install", "-y", "epel-release", "centos-release-scl"]
ADD ci/ci.el7/rspec_rpmbuild/yum.repo/dev.repo /etc/yum.repos.d/

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

COPY ["ci/ci.el7/rpmtest/rpm-install.sh", "/var/tmp/"]
ENTRYPOINT ["./rpm-install.sh"]