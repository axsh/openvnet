CURDIR ?= $(PWD)
#An empty string for DSTDIR will install Wakame-VNet under /opt/axsh/wakame-vnet
DSTDIR ?= ""

all: install-bundle

dev: install-bundle-dev update-config

install-bundle:
	(cd $(CURDIR)/vnet; bundle install --path vendor/bundle --without development test)

clean-bundle:
	(cd $(CURDIR)/vnet; bundle clean)

install-bundle-dev:
	(cd $(CURDIR)/vnet; bundle install --path vendor/bundle)

install: update-config
	mkdir -p $(DSTDIR)/opt/axsh/wakame-vnet
	mkdir -p $(DSTDIR)/var/run/wakame-vnet/log
	mkdir -p $(DSTDIR)/var/run/wakame-vnet/pid
	mkdir -p $(DSTDIR)/var/run/wakame-vnet/sock
	cp -r vnet vnctl deployment $(DSTDIR)/opt/axsh/wakame-vnet


uninstall: remove-config
	rm -rf $(DSTDIR)/opt/axsh/wakame-vnet
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
	rm -rf $(CURDIR)/vnet/vendor
	rm -rf $(CURDIR)/vnet/.bundle

build-rpm: DSTDIR = /tmp/vnet-rpmbuild
build-rpm: reinstall install-bundle clean-bundle
	(cd $(CURDIR)/deployment/packagebuild; bundle install --path vendor/bundle --binstubs)
	(cd $(DSTDIR); $(DSTDIR)/opt/axsh/wakame-vnet/deployment/packagebuild/build_package.sh)

test-rpm-install: DSTDIR = /tmp/vnet-rpmbuild
test-rpm-install: reinstall
	(cd $(DSTDIR); $(DSTDIR)/opt/axsh/wakame-vnet/deployment/packagebuild/test-rpm-install.sh)
