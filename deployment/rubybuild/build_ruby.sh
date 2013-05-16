#!/bin/bash

ruby_ver="1.9.3-p385"
whereami="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
vnet_path="$( cd $whereami/../.. && pwd )"
ruby_install_dir=${ruby_install_dir:-$vnet_path/ruby}
tmp_dir=${tmp_dir:-/tmp}

RUBY_BUILD_REPO_URI="https://github.com/sstephenson/ruby-build.git"
RUBY_MIRROR_SITE="http://core.ring.gr.jp/archives/lang/ruby/"
LIBYAML_MIRROR_SITE="http://pyyaml.org/download/libyaml/"
RUBYGEMS_MIRROR_SITE="http://production.cf.rubygems.org/rubygems/"

[ -d "$ruby_install_dir" ] || {
  mkdir $ruby_install_dir
}

(cd $tmp_dir; git clone $RUBY_BUILD_REPO_URI)
(cd $tmp_dir/ruby-build; sed -i s,http://ftp.ruby-lang.org/pub/ruby/,$RUBY_MIRROR_SITE, share/ruby-build/*)
(cd $tmp_dir/ruby-build; sed -i s,http://pyyaml.org/download/libyaml/,$LIBYAML_MIRROR_SITE, share/ruby-build/*)
(cd $tmp_dir/ruby-build; sed -i s,http://production.cf.rubygems.org/rubygems/,$RUBYGEMS_MIRROR_SITE, share/ruby-build/*)
(cd $tmp_dir/ruby-build; ./bin/ruby-build $ruby_ver $ruby_install_dir)
