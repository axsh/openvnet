# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Interface do
  before do
    Fabricate(:datapath_1)
    Fabricate(:datapath_2)
    ip_address_1 = Fabricate(:ip_address_1)
    ip_address_2 = Fabricate(:ip_address_2)
    network = Fabricate(:network)
    iface = Fabricate(:iface, network: network)
    Fabricate(:ip_lease_1, interface: iface, ip_address: ip_address_1)
    Fabricate(:ip_lease_2, interface: iface, ip_address: ip_address_2)
    Fabricate(:mac_lease, interface: iface)
  end

  subject { Vnet::Models::Interface.first }

  it "returns mac address" do
    expect(subject.mac_addr).to eq 1
  end

  it "has active_datapath_id 1" do
    expect(subject.active_datapath.id).to eq 1
  end

  it "has owner_datapath_id 2" do
    expect(subject.owner_datapath.id).to eq 2
  end

  it "should find an entry by name" do
    expect(Vnet::Models::Interface.find(:name => 'vif-test')).to eq subject
  end

  it "has multiple ip lease entries" do
    expect(subject.ipv4_address.size).to eq 2
    expect(subject.ipv4_address[0]).to eq 1
    expect(subject.ipv4_address[1]).to eq 2
  end
end
