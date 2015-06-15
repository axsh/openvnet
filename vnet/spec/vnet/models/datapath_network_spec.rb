# -*- coding: utf-8 -*-

require 'spec_helper'

describe Vnet::Models::DatapathNetwork do
  let(:datapath_1) { Fabricate(:datapath_1) }
  let(:datapath_2) { Fabricate(:datapath_2) }
  let(:datapath_3) { Fabricate(:datapath_3) }

  let(:mac_address_1_1) { Fabricate(:mac_address) }
  let(:mac_address_1_2) { Fabricate(:mac_address) }
  let(:mac_address_2_1) { Fabricate(:mac_address) }
  let(:mac_address_2_2) { Fabricate(:mac_address) }
  let(:mac_address_3_1) { Fabricate(:mac_address) }
  let(:mac_address_3_2) { Fabricate(:mac_address) }

  before(:each) do
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_1.id, :network_id => 1, :mac_address => mac_address_1_1)
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_1.id, :network_id => 2, :mac_address => mac_address_1_2)
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_2.id, :network_id => 1, :mac_address => mac_address_2_1)
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_2.id, :network_id => 2, :mac_address => mac_address_2_2)
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_3.id, :network_id => 1, :mac_address => mac_address_3_1)
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_3.id, :network_id => 2, :mac_address => mac_address_3_2)
  end

  context "unique condition" do
    it "rejects same existing entry" do
      expect {
        Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_1.id, :network_id => 1, :mac_address => mac_address_1_1)
      }.to raise_error Sequel::Error
    end
    it "rejects same broadcast mac address" do
      expect {
        Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_1.id, :network_id => 3, :mac_address => mac_address_1_1)
      }.to raise_error Sequel::Error
    end
  end

  describe "datapath_networks_in_the_same_network" do
    subject { datapath_1.datapath_networks.first.datapath_networks_in_the_same_network }
    it { expect(subject.size).to eq 2 }
    it { expect(subject.map(&:network_id).uniq).to eq [1]}
    it { expect(subject.map(&:datapath_id)).to eq [2, 3]}
  end
end
