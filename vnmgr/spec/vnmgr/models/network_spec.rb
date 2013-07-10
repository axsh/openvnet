# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnmgr::Models::Network do
  describe "network_services" do
    before do
      network = Fabricate(:network)
      vif1 = Fabricate(:vif, network: network)
      vif2 = Fabricate(:vif, network: network)
      network_service1 = Fabricate(:network_service, vif: vif1)
      network_service2 = Fabricate(:network_service, vif: vif1)
      network_service3 = Fabricate(:network_service, vif: vif2)
      network_service4 = Fabricate(:network_service, vif: vif2)
    end

    it "retunr network_services with eager load" do
      network = Vnmgr::Models::Network.first
      expect(network.network_services.size).to eq 4
      network.network_services.each do |ns|
        # no sql query will be executed
        ns.vif.to_hash
      end
    end
  end
end
