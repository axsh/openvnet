# -*- coding: utf-8 -*-
require 'spec_helper'
require 'ipaddr'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::Networks::Virtual do

  before(:all) do
    Fabricate('vnet_1')
    Fabricate('datapath_1')
  end

  describe "install vnet_1 without broadcast_mac_address" do

    let(:vnet_map) { Vnet::ModelWrappers::Network['nw-aaaaaaaa'] }
    let(:datapath) { MockDatapath.new(double(:ofc), ("a" * 16).to_i) }
    let(:flow_options) { {:cookie => vnet_map.network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)} }
    let(:network_md) { flow_options.merge(subject.md_network(:network)) }
    let(:flows) { datapath.added_flows }

    subject { Vnet::Openflow::Networks::Virtual.new(datapath, vnet_map) }

    it "has flows for destination filtering" do
      subject.install
      expect(flows[0]).to eq Vnet::Openflow::Flow.create(
        TABLE_TUNNEL_NETWORK_IDS,
        30,
        {:tunnel_id => 1 | TUNNEL_FLAG_MASK},
        nil,
        network_md.merge(:goto_table => TABLE_NETWORK_SRC_CLASSIFIER))
      expect(flows[1]).to eq Vnet::Openflow::Flow.create(
        TABLE_NETWORK_SRC_CLASSIFIER,
        40,
        subject.md_network(:network),
        nil,
        flow_options.merge(:goto_table => TABLE_VIRTUAL_SRC))
      expect(flows[2]).to eq Vnet::Openflow::Flow.create(
        TABLE_NETWORK_DST_CLASSIFIER,
        40,
        subject.md_network(:network),
        nil,
        flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))
    end
  end
end
