# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/wanedge.rb'

# TODO: Add multiple networks and use all vm's.

describe 'wanedge_tp', :vms_enable_vm => :vm_1_5_7 do
  let(:ping_tries) { 5 }

  include_examples 'wanedge topology examples', 'nw-global', pending_gre: true
end
