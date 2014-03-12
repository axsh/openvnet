CURDIR ?= $(PWD)
#An empty string for DSTDIR will install OpenVNet under /opt/axsh/openvnet
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
	mkdir -p $(DSTDIR)/opt/axsh/openvnet
	mkdir -p $(DSTDIR)/var/run/openvnet/log
	mkdir -p $(DSTDIR)/var/run/openvnet/pid
	mkdir -p $(DSTDIR)/var/run/openvnet/sock
	cp -r vnet vnctl deployment $(DSTDIR)/opt/axsh/openvnet


uninstall: remove-config
	rm -rf $(DSTDIR)/opt/axsh/openvnet
	rm -rf $(DSTDIR)/var/run/openvnet

reinstall: uninstall install

update-config:
	mkdir -p $(DSTDIR)/etc/openvnet
	cp -r deployment/conf_files/etc/openvnet $(DSTDIR)/etc/
	cp -r deployment/conf_files/etc/default $(DSTDIR)/etc
	cp -r deployment/conf_files/etc/init $(DSTDIR)/etc

remove-config:
	rm -rf $(DSTDIR)/etc/openvnet
	rm $(DSTDIR)/etc/default/vnet-vna
	rm $(DSTDIR)/etc/default/vnet-vnmgr
	rm $(DSTDIR)/etc/default/vnet-webapi
	rm $(DSTDIR)/etc/default/openvnet
	rm $(DSTDIR)/etc/init/vnet-vna.conf
	rm $(DSTDIR)/etc/init/vnet-vnmgr.conf
	rm $(DSTDIR)/etc/init/vnet-webapi.conf

clean:
	rm -rf $(CURDIR)/vnet/vendor
	rm -rf $(CURDIR)/vnet/.bundle

build-rpm: build-rpm-vnet build-rpm-third-party

build-rpm-vnet: install-bundle clean-bundle
	(cd $(CURDIR)/deployment/packagebuild; bundle install --path vendor/bundle --binstubs)
	$(CURDIR)/deployment/packagebuild/build_packages_vnet.sh

build-rpm-third-party:
	(cd $(CURDIR)/deployment/packagebuild; bundle install --path vendor/bundle --binstubs)
	$(CURDIR)/deployment/packagebuild/build_packages_third_party.sh

test-rpm-install:
	$(CURDIR)/deployment/packagebuild/test-rpm-install.sh
