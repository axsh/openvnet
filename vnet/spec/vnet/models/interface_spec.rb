# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Interface do
  before do
    Fabricate(:datapath_1)
    Fabricate(:datapath_2)
    network = Fabricate(:network)
    iface = Fabricate(:iface, network: network)
    Fabricate(:ip_lease, interface: iface)
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
end
