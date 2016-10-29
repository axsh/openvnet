# -*- coding: utf-8 -*-

require_relative 'shared_examples/simple'

describe 'simple_seg', :vms_disable_dhcp => true do
  before(:all) do
    vm1.change_ipv4_address('10.101.0.10')
    vm2.change_ipv4_address('10.101.0.10')
    vm3.change_ipv4_address('10.101.0.11')
    vm4.change_ipv4_address('10.101.0.11')
    vm5.change_ipv4_address('10.101.0.12')
    vm6.change_ipv4_address('10.101.0.12')
  end

  include_examples 'simple examples'
end
