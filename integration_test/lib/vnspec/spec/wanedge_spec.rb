# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/wanedge.rb'

# TODO: Add multiple networks and use all vm's.

describe 'wanedge', :vms_enable_vm => :vm_1_7 do
  # before(:all) { sleep 120 }

  include_examples 'wanedge examples', 'nw-global', pending_gre: true
end
