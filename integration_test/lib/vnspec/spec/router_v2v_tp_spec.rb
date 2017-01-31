# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/router.rb'

describe 'router_v2v_tp' do
  include_examples 'router examples'

  # Since no vm's do dhcp requests there is nothing to ensure that
  # the vna's have properly loaded the segments and other
  # information.
  sleep 30
end
