# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/simple'

describe 'simple_seg', :vms_disable_dhcp => true do
  before(:all) do
    vm1.change_ipv4_address('10.101.0.10')
    vm2.change_ipv4_address('10.101.0.10')
    vm3.change_ipv4_address('10.101.0.11')
    vm4.change_ipv4_address('10.101.0.11')
    vm5.change_ipv4_address('10.101.0.12')
    vm6.change_ipv4_address('10.101.0.12')

    # Since no vm's do dhcp requests there is nothing to ensure that
    # the vna's have properly loaded the segments and other
    # information.
    sleep 20
  end

  include_examples 'simple examples'
end
