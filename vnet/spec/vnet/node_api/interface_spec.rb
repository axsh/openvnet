# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi::Interface do
  describe "create" do
    it "success" do
      mac_address = random_mac_i
      network = Fabricate(:network)
      ipv4_address = random_ipv4_i

      interface = Vnet::NodeApi::Interface.create(
        mac_address: mac_address,
        network_id: network.id,
        ipv4_address: ipv4_address
      )

      expect(interface[:network_id]).to eq network.id
      expect(interface[:mac_address]).to eq mac_address
      expect(interface[:ipv4_address]).to eq ipv4_address
    end
  end
end
