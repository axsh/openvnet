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

  describe "datapath_networks_on_segment" do
    subject { Vnet::Models::DatapathNetwork.on_segment(datapath_1).where(:network_id => 1).all }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Vnet::Models::DatapathNetwork }
    it { expect(subject.first.datapath.id).to eq datapath_2.id }
  end

  describe "datapath_networks_on_other_segment" do
    subject { Vnet::Models::DatapathNetwork.on_other_segment(datapath_1).where(:network_id => 1).all }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Vnet::Models::DatapathNetwork }
    it { expect(subject.first.datapath.id).to eq datapath_3.id }
  end

  describe "datapath_networks_on_specific_datapath" do
    subject { Vnet::Models::DatapathNetwork.on_specific_datapath(datapath_1).all }
    it { expect(subject.size).to eq 2 }
    it { expect(subject.first).to be_a Vnet::Models::DatapathNetwork }
    it { expect(subject.first.mac_address).to eq mac_address_1_1 }
  end
end
