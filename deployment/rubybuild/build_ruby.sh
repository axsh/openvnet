#!/bin/bash

#ruby_ver="1.9.3-p385"
ruby_ver=${ruby_ver:-2.0.0-p247}
whereami="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
vnet_path="$( cd $whereami/../.. && pwd )"
ruby_install_dir=${ruby_install_dir:-$vnet_path/ruby}
tmp_dir=${tmp_dir:-/tmp}

RUBY_BUILD_REPO_URI="https://github.com/sstephenson/ruby-build.git"
RUBY_MIRROR_SITE="http://core.ring.gr.jp/archives/lang/ruby/"
LIBYAML_MIRROR_SITE="http://pyyaml.org/download/libyaml/"
RUBYGEMS_MIRROR_SITE="http://production.cf.rubygems.org/rubygems/"

# The devel packages are needed to build certain functionality into ruby that we'll use in certain gems later
dependencies=(make git gcc gcc-c++ zlib-devel openssl-devel zeromq-devel mysql-devel sqlite-devel)

function check_dep() {
  local dep=$1
  rpm -q $dep &> /dev/null
  if [ ! "$?" == "0" ]; then
    echo "Missing dependencies."
    echo "Make sure all of the following are installed:"
    echo ${dependencies[@]}
    exit 1
  fi
}

for dep in ${dependencies[*]}; do
 check_dep $dep
done

[ -d "$ruby_install_dir" ] || {
  mkdir $ruby_install_dir
}


[[ -d ${tmp_dir}/ruby-build ]] || (cd $tmp_dir; git clone $RUBY_BUILD_REPO_URI ruby-build)
(cd $tmp_dir/ruby-build; git pull;)
(cd $tmp_dir/ruby-build; sed -i s,http://ftp.ruby-lang.org/pub/ruby/,$RUBY_MIRROR_SITE, share/ruby-build/*)
(cd $tmp_dir/ruby-build; sed -i s,http://pyyaml.org/download/libyaml/,$LIBYAML_MIRROR_SITE, share/ruby-build/*)
(cd $tmp_dir/ruby-build; sed -i s,http://production.cf.rubygems.org/rubygems/,$RUBYGEMS_MIRROR_SITE, share/ruby-build/*)
(cd $tmp_dir/ruby-build; ./bin/ruby-build $ruby_ver $ruby_install_dir)
