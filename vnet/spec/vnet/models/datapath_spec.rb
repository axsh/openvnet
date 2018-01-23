# -*- coding: utf-8 -*-

require 'spec_helper'

describe Vnet::Models::Datapath do
  let(:datapath_1) { Fabricate(:datapath_1) }
  let(:datapath_2) { Fabricate(:datapath_2) }
  let(:datapath_3) { Fabricate(:datapath_3) }

  let(:network_1) { Fabricate(:vnet_1) }
  let(:network_2) { Fabricate(:vnet_2) }

  let(:route_link_1) { Fabricate(:route_link_1) }
  let(:route_link_2) { Fabricate(:route_link_2) }

  before(:each) do
    datapath_1
    datapath_2
    datapath_3
    network_1
    network_2
    route_link_1
    route_link_2
  end

  describe "datapath_networks" do
    before(:each) do
      Fabricate(:datapath_network, datapath_id: datapath_1.id, network_id: network_1.id)
      Fabricate(:datapath_network, datapath_id: datapath_1.id, network_id: network_2.id)
      Fabricate(:datapath_network, datapath_id: datapath_2.id, network_id: network_1.id)
      Fabricate(:datapath_network, datapath_id: datapath_2.id, network_id: network_2.id).destroy
      Fabricate(:datapath_network, datapath_id: datapath_3.id, network_id: network_2.id)
    end

    context "non-deleted datapath" do
      it "returns non-deleted datapaths" do
        expect(network_1.datapath_networks.map(&:datapath)).to eq [datapath_1, datapath_2]
        expect(network_2.datapath_networks.map(&:datapath)).to eq [datapath_1, datapath_3]
      end
    end

    context "deleted datapath" do
      before(:each) do
        datapath_1.destroy
      end

      it "returns non-deleted datapaths" do
        expect(network_1.datapath_networks.map(&:datapath)).to eq [datapath_2]
        expect(network_2.datapath_networks.map(&:datapath)).to eq [datapath_3]
      end
    end
  end

  describe "datapath_route_links" do
    before(:each) do
      Fabricate(:datapath_route_link, datapath_id: datapath_1.id, route_link_id: route_link_1.id)
      Fabricate(:datapath_route_link, datapath_id: datapath_1.id, route_link_id: route_link_2.id)
      Fabricate(:datapath_route_link, datapath_id: datapath_2.id, route_link_id: route_link_1.id)
      Fabricate(:datapath_route_link, datapath_id: datapath_2.id, route_link_id: route_link_2.id).destroy
      Fabricate(:datapath_route_link, datapath_id: datapath_3.id, route_link_id: route_link_2.id)
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
