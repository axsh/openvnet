CURDIR ?= $(PWD)
RUBYDIR = $(CURDIR)/ruby/current
#An empty string for DSTDIR will install Wakame-VNet under /opt/axsh/wakame-vnet
DSTDIR ?= ""

all: build-ruby install-bundle

dev: build-ruby install-bundle-dev update-config

build-ruby:
	ruby_ver=$(RUBY_VERSION) $(CURDIR)/deployment/rubybuild/build_ruby.sh

install-bundle:
	$(RUBYDIR)/bin/gem install bundler
	(cd $(CURDIR)/vnet; $(RUBYDIR)/bin/bundle install --path vendor/bundle --without development test)

install-bundle-dev:
	$(RUBYDIR)/bin/gem install bundler
	(cd $(CURDIR)/vnet; $(RUBYDIR)/bin/bundle install --path vendor/bundle)

install: update-config
	mkdir -p $(DSTDIR)/opt/axsh/wakame-vnet
	mkdir -p $(DSTDIR)/tmp/log
	mkdir -p $(DSTDIR)/var/run/wakame-vnet/log
	mkdir -p $(DSTDIR)/var/run/wakame-vnet/pid
	mkdir -p $(DSTDIR)/var/run/wakame-vnet/sock
	cp -r vnet vnctl ruby deployment $(DSTDIR)/opt/axsh/wakame-vnet


uninstall: remove-config
	rm -rf $(DSTDIR)/opt/axsh/wakame-vnet
	rm -rf $(DSTDIR)/tmp/log
	rm -rf $(DSTDIR)/var/run/wakame-vnet

reinstall: uninstall install

update-config:
	mkdir -p $(DSTDIR)/etc/wakame-vnet
	cp -r deployment/conf_files/etc/wakame-vnet $(DSTDIR)/etc/
	cp -r deployment/conf_files/etc/default $(DSTDIR)/etc
	cp -r deployment/conf_files/etc/init $(DSTDIR)/etc

remove-config:
	rm -rf $(DSTDIR)/etc/wakame-vnet
	rm $(DSTDIR)/etc/default/vnet-vna
	rm $(DSTDIR)/etc/default/vnet-vnmgr
	rm $(DSTDIR)/etc/default/vnet-webapi
	rm $(DSTDIR)/etc/default/wakame-vnet
	rm $(DSTDIR)/etc/init/vnet-vna.conf
	rm $(DSTDIR)/etc/init/vnet-vnmgr.conf
	rm $(DSTDIR)/etc/init/vnet-webapi.conf

clean:
	rm -rf $(RUBYDIR)
	rm -rf $(CURDIR)/vnet/vendor
	rm -rf $(CURDIR)/vnet/.bundle

build-rpm: DSTDIR = /tmp/vnet-rpmbuild
build-rpm: build-ruby install-bundle reinstall
	(cd $(CURDIR)/deployment/packagebuild; $(RUBYDIR)/bin/bundle install --path vendor/bundle --binstubs)
	(cd $(DSTDIR);	fpm_path="$(CURDIR)/deployment/packagebuild/bin/fpm" $(DSTDIR)/opt/axsh/wakame-vnet/deployment/packagebuild/build_package.sh)
