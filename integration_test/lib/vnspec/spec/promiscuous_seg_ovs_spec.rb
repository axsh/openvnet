# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/promiscuous.rb'

describe 'promiscuous_seg_ovs', :vms_enable_vm => [:vm1, :vm7], :vms_disable_dhcp => true do
  include_examples 'promiscuous segment examples'
end
