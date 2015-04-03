# -*- coding: utf-8 -*-

require 'spec_helper'

describe Vnet::Models::Datapath do
  let(:datapath_1) { Fabricate(:datapath_1) }
  let(:datapath_2) { Fabricate(:datapath_2) }
  let(:datapath_3) { Fabricate(:datapath_3) }

  let(:vnet_1) { Fabricate(:vnet_1) }
  let(:vnet_2) { Fabricate(:vnet_2) }

  let(:route_link_1) { Fabricate(:route_link_1) }
  let(:route_link_2) { Fabricate(:route_link_2) }

  before(:each) do
    datapath_1
    datapath_2
    datapath_3
    vnet_1
    vnet_2
    route_link_1
    route_link_2
  end

  describe "datapath_networks" do
    before(:each) do
      Fabricate(:datapath_network_1_1)
      Fabricate(:datapath_network_1_2)
      Fabricate(:datapath_network_2_1)
      Fabricate(:datapath_network_2_2).destroy
      Fabricate(:datapath_network_3_2)
    end

    context "non-deleted datapath" do
      it "returns non-deleted datapaths" do
        expect(vnet_1.datapath_networks.map(&:datapath)).to eq [datapath_1, datapath_2]
        expect(vnet_2.datapath_networks.map(&:datapath)).to eq [datapath_1, datapath_3]
      end
    end

    context "deleted datapath" do
      before(:each) do
        datapath_1.destroy
      end

      it "returns non-deleted datapaths" do
        expect(vnet_1.datapath_networks.map(&:datapath)).to eq [datapath_2]
        expect(vnet_2.datapath_networks.map(&:datapath)).to eq [datapath_3]
      end
    end
  end

  describe "datapath_route_links" do
    before(:each) do
      Fabricate(:datapath_route_link_1_1)
      Fabricate(:datapath_route_link_1_2)
      Fabricate(:datapath_route_link_2_1)
      Fabricate(:datapath_route_link_2_2).destroy
      Fabricate(:datapath_route_link_3_2)
    end

    context "non-deleted datapath" do
      it "returns non-deleted datapaths" do
        expect(route_link_1.datapath_route_links.map(&:datapath)).to eq [datapath_1, datapath_2]
        expect(route_link_2.datapath_route_links.map(&:datapath)).to eq [datapath_1, datapath_3]
      end
    end

    context "deleted datapath" do
      before(:each) do
        datapath_1.destroy
      end

      it "returns non-deleted datapaths" do
        expect(route_link_1.datapath_route_links.map(&:datapath)).to eq [datapath_2]
        expect(route_link_2.datapath_route_links.map(&:datapath)).to eq [datapath_3]
      end
    end
  end

end
