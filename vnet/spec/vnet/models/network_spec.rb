# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Network do
  describe "network_services" do
    before do
      network = Fabricate(:network)
      vif1 = Fabricate(:interface, network: network)
      vif2 = Fabricate(:interface, network: network)
      network_service1 = Fabricate(:network_service, interface: vif1)
      network_service2 = Fabricate(:network_service, interface: vif1)
      network_service3 = Fabricate(:network_service, interface: vif2)
      network_service4 = Fabricate(:network_service, interface: vif2)
    end

    it "retunr network_services with eager load" do
      network = Vnet::Models::Network.first
      expect(network.network_services.size).to eq 4
      network.network_services.each do |ns|
        # no sql query will be executed
        ns.interface.to_hash
      end
    end
  end
end
