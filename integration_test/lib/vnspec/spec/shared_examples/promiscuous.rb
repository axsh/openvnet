# -*- coding: utf-8 -*-

require_relative 'wanedge'

shared_examples 'promiscuous segment examples' do
  before(:all) do
    vm1.change_ipv4_address('10.210.0.10')
    vm7.change_ipv4_address('10.210.0.17')

    vm1.route_default_via(config[:physical_network_gw_ip])
    vm7.route_default_via(config[:physical_network_gw_ip])
  end

  include_examples 'wanedge examples', 'seg-global', pending_local: true, pending_gre: true
end
