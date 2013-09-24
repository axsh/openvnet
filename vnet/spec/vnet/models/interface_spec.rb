# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Interface do
  before do
    network = Fabricate(:network)

    interface = Fabricate(:interface,
                          network: network,
                          owner_datapath: Fabricate(:datapath_1))

    Fabricate(:ip_lease_any, interface: interface, ip_address: Fabricate(:ip_address_1), network: network)
    Fabricate(:ip_lease_any, interface: interface, ip_address: Fabricate(:ip_address_2), network: network)
    Fabricate(:mac_lease, interface: interface, mac_address: Fabricate(:mac_address))
  end

  subject { Vnet::Models::Interface.first }

  it "returns mac address" do
    expect(subject.mac_address).to eq 1
  end

  it "has owner_datapath_id 2" do
    expect(subject.owner_datapath.id).to eq 1
  end

  it "has multiple ip lease entries" do
    expect(subject.ipv4_address.size).to eq 2
    expect(subject.ipv4_address[0]).to eq 1
    expect(subject.ipv4_address[1]).to eq 2
  end
end
