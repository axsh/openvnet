# -*- coding: utf-8 -*-
require 'spec_helper'
require 'ipaddr'
require 'trema'

include Vnet::Constants::Openflow

include Vnet::Constants::Openflow
include Vnet::Constants::OpenflowFlows

describe Vnet::Openflow::NetworkVirtual do

  before(:all) do
    Fabricate('vnet_1')
    Fabricate('datapath_1')
  end

  describe "install vnet_1 without broadcast_mac_addr" do

    let(:vnet_map) { Vnet::ModelWrappers::Network['nw-aaaaaaaa'] }
    let(:datapath) { MockDatapath.new(double(:ofc), ("a" * 16).to_i) }
    let(:flow_options) { {:cookie => vnet_map.network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)} }
    let(:flood_md) { flow_options.merge(subject.md_network(:virtual_network, :flood => nil)) }
    let(:any_network_md) { flow_options.merge(subject.md_network(:virtual_network)) }
    let(:flows) { datapath.added_flows }

    subject { Vnet::Openflow::NetworkVirtual.new(datapath, vnet_map) }

    it "has flows for destination filtering" do
      subject.install
      expect(flows[0]).to eq Vnet::Openflow::Flow.create(
        TABLE_TUNNEL_NETWORK_IDS,
        30,
        {:tunnel_id => 1 | TUNNEL_FLAG_MASK},
        {},
        any_network_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))
      
      expect(flows[1]).to eq Vnet::Openflow::Flow.create(
        TABLE_NETWORK_CLASSIFIER,
        40,
        subject.md_network(:virtual_network),
        {},
        flow_options.merge(:goto_table => TABLE_VIRTUAL_SRC))
      
      expect(flows[2]).to eq Vnet::Openflow::Flow.create(
        TABLE_VIRTUAL_DST,
        40,
        subject.md_network(:virtual_network, :local => nil).merge!(:eth_dst => MAC_BROADCAST),
        {},
        flood_md.merge(:goto_table => TABLE_METADATA_ROUTE))
      
      expect(flows[3]).to eq Vnet::Openflow::Flow.create(
        TABLE_VIRTUAL_DST,
        30,
        subject.md_network(:virtual_network, :remote => nil).merge!(:eth_dst => MAC_BROADCAST),
        {},
        flood_md.merge(:goto_table => TABLE_METADATA_LOCAL))
    end
  end

  # describe "install vnet_1 with broadcast_mac_addr" do
  #   before(:all) do
  #     Fabricate('datapath_network_1_1')
  #   end

  #   let(:vnet_map) { Vnet::ModelWrappers::Network['nw-aaaaaaaa'] }
  #   let(:vnet) { Vnet::Openflow::NetworkVirtual.new(datapath, vnet_map).install }

  #   let(:datapath) do
  #     MockDatapath.new(double(:ofc), ("a" * 16).to_i).tap do |dp|
  #       datapath_map = Vnet::ModelWrappers::Datapath[:dpid => ("0x#{'a'*16}")
  #       dpn_map = Vnet::ModelWrappers::DatapathNetwork
  #       dp.set_datapath_of_bridge(datapath_map, dpn_map, false)
  #     end
  #   end

  #   it "has 7 flows" do
  #     expect(flows.size).to eq 7
  #   end

  #   it "has flows for broadcasting" do
  #     expect(flows[4]).to eq Vnet::Openflow::Flow.create(
  #       TABLE_HOST_PORTS,
  #       30,
  #       {:eth_dst => subject.broadcast_mac_addr},
  #       {:eth_dst => MAC_BROADCAST},
  #       any_network_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))
  #   end
  # end
end
