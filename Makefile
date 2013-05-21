CURDIR ?= $(PWD)
RUBYDIR = $(CURDIR)/ruby
#An empty string for DSTDIR will install Wakame-VNet under /opt/axsh/wakame-vnet
DSTDIR ?= ""

all: build-ruby install-bundle

build-ruby:
	$(CURDIR)/deployment/rubybuild/build_ruby.sh

install-bundle:
	$(RUBYDIR)/bin/gem install bundler
	(cd $(CURDIR)/vnmgr; $(RUBYDIR)/bin/bundle install --standalone --path vendor/bundle)

install:
	mkdir -p $(DSTDIR)/opt/axsh/wakame-vnet
	mkdir -p $(DSTDIR)/etc/wakame-vnet
	cp -r vnmgr vnctl ruby $(DSTDIR)/opt/axsh/wakame-vnet
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
	rm -rf $(CURDIR)/vnmgr/vendor
