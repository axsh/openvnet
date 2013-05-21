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

all: build-ruby

build-ruby:
	$(CURDIR)/deployment/rubybuild/build_ruby.sh
	$(RUBYDIR)/bin/gem install bundler
	(cd $(CURDIR)/vnmgr; mkdir .bundle; echo "$$BUNDLE_CFG" > .bundle/config)
	(cd $(CURDIR)/vnmgr; $(RUBYDIR)/bin/bundle install)

install:
	#TODO: Check if DSTDIR is empty
	mkdir -p $(DSTDIR)/opt/axsh/wakame-vnet
	mkdir -p $(DSTDIR)/etc/wakame-vnet
