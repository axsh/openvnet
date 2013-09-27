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
    Fabricate(:mac_lease, interface: interface, mac_address: 3)
    Fabricate(:mac_lease, interface: interface, mac_address: 4)
  end

  subject { Vnet::Models::Interface.first }

  describe "ipv4_address" do
    it {  expect(subject.ipv4_address).to eq 1 }
  end

  describe "all_mac_addresses" do
    it {  expect(subject.all_ipv4_addresses).to eq [1, 2] }
  end

  describe "mac_address" do
    it {  expect(subject.mac_address).to eq 3 }
  end

  describe "all_mac_addresses" do
    it {  expect(subject.all_mac_addresses).to eq [3, 4] }
  end
end
