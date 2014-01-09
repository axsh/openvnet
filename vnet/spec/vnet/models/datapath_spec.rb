# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Datapath do
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
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_1.id, :network_id => 1)
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_1.id, :network_id => 2)
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_2.id, :network_id => 1)
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_2.id, :network_id => 2).destroy
    Vnet::Models::DatapathNetwork.create(:datapath_id => datapath_3.id, :network_id => 2)
  end

  describe "peers" do
    context "non-deleted datapath" do
      it "returns non-deleted peers" do
        expect(datapath_1.peers).to eq [datapath_2, datapath_3]
        expect(datapath_2.peers).to eq [datapath_1]
        expect(datapath_3.peers).to eq [datapath_1]
      end
    end

    context "deleted datapath" do
      before(:each) do
        datapath_1.destroy
      end

      it "returns non-deleted peers" do
        expect(datapath_1.peers).to eq [datapath_2, datapath_3]
        expect(datapath_2.peers).to eq []
        expect(datapath_3.peers).to eq []
      end
    end
  end
end
