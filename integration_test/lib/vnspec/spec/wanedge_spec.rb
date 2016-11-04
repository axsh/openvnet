# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/wanedge.rb'

# TODO: Add multiple networks and use all vm's.

describe 'wanedge', :vms_enable_vm => :vm_1_5_7 do
  before(:all) {
    vms.parallel_each { |vm |
      vm.clear_arp_cache
    }
  }

  include_examples 'wanedge examples', 'nw-global'
end
