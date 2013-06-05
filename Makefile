CURDIR ?= $(PWD)
RUBYDIR = $(CURDIR)/ruby
#An empty string for DSTDIR will install Wakame-VNet under /opt/axsh/wakame-vnet
DSTDIR ?= ""

define BUNDLE_CFG
---
BUNDLE_PATH: vendor/bundle
BUNDLE_DISABLE_SHARED_GEMS: '1'
endef
# We're exporting this as a shell variable because otherwise Make can't echo multiline strings into a file
export BUNDLE_CFG

all: build-ruby install-bundle

dev: build-ruby install-bundle-dev

build-ruby:
	$(CURDIR)/deployment/rubybuild/build_ruby.sh

install-bundle:
	$(RUBYDIR)/bin/gem install bundler
	(cd $(CURDIR)/vnmgr; mkdir .bundle; echo "$$BUNDLE_CFG" > .bundle/config)
	(cd $(CURDIR)/vnmgr; $(RUBYDIR)/bin/bundle install --without development test)

install-bundle-dev:
	$(RUBYDIR)/bin/gem install bundler
	(cd $(CURDIR)/vnmgr; mkdir .bundle; echo "$$BUNDLE_CFG" > .bundle/config)
	(cd $(CURDIR)/vnmgr; $(RUBYDIR)/bin/bundle install)

install:
	mkdir -p $(DSTDIR)/opt/axsh/wakame-vnet
	mkdir -p $(DSTDIR)/etc/wakame-vnet
	cp -r vnmgr vnctl ruby deployment $(DSTDIR)/opt/axsh/wakame-vnet
	cp -r deployment/conf_files/etc/default $(DSTDIR)/etc
	cp -r deployment/conf_files/etc/init $(DSTDIR)/etc
	cp -r deployment/conf_files/etc/wakame-vnet $(DSTDIR)/etc


uninstall:
	rm -rf $(DSTDIR)/opt/axsh/wakame-vnet
	rm $(DSTDIR)/etc/default/vnet-dba
	rm $(DSTDIR)/etc/default/vnet-vna
	rm $(DSTDIR)/etc/default/vnet-vnmgr
	rm $(DSTDIR)/etc/default/wakame-vnet
	rm $(DSTDIR)/etc/init/vnet-dba.conf
	rm $(DSTDIR)/etc/init/vnet-vna.conf
	rm $(DSTDIR)/etc/init/vnet-vnmgr.conf

remove-config:
	rm -rf $(DSTDIR)/etc/wakame-vnet

clean:
	rm -rf $(RUBYDIR)
	rm -rf $(CURDIR)/vnmgr/vendor/bundle
	(cd $(CURDIR)/vnmgr/vendor/cache; ls --ignore racket-1.0.12.gem --ignore rant-0.5.9.gem | xargs rm -f)
	rm -rf $(CURDIR)/vnmgr/.bundle

build-rpm: DSTDIR = /tmp/vnet-rpmbuild
build-rpm: clean build-ruby install-bundle install
	$(RUBYDIR)/bin/gem install fpm
	(cd $(DSTDIR);	fpm_path="$(RUBYDIR)/bin/fpm" $(DSTDIR)/opt/axsh/wakame-vnet/deployment/packagebuild/build_package.sh)
