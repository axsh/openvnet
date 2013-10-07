# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Interface do
  before do
    network = Fabricate(:network)

    interface = Fabricate(:interface,
                          owner_datapath: Fabricate(:datapath_1))

    Fabricate(:ip_lease_any, interface: interface, ip_address: Fabricate(:ip_address_1, network: network))
    Fabricate(:ip_lease_any, interface: interface, ip_address: Fabricate(:ip_address_2, network: network))
    Fabricate(:mac_lease, interface: interface, mac_address: 3)
    Fabricate(:mac_lease, interface: interface, mac_address: 4)
  end

  subject { Vnet::Models::Interface.first }

  describe "ipv4_address" do
    it { expect(subject.ipv4_address).to eq 1 }
  end
end
