# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/promiscuous.rb'

describe 'promiscuous_seg_of', :vms_enable_vm => :vm1_5_7, :vms_disable_dhcp => true do
  let(:ping_tries) { 60 }

  include_examples 'promiscuous segment examples'
end
