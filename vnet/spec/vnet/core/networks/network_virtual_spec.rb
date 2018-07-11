# -*- coding: utf-8 -*-
require 'spec_helper'
require 'ipaddr'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Core::Networks::Virtual do

  before(:all) do
    Fabricate('vnet_1')
    Fabricate('datapath_1')
  end

  describe "install vnet_1 without mac_address" do
    let(:vnet_map) { Vnet::ModelWrappers::Network['nw-aaaaaaaa'] }
    let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
    let(:dp_info) { datapath.dp_info }
    let(:flow_options) { {:cookie => vnet_map.id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)} }
    let(:network_md) { subject.md_create(:network => vnet_map.id) }
    let(:tunnel_md) {
      { :metadata => METADATA_VALUE_PAIR_TYPE | METADATA_VALUE_PAIR_FLAG | ((vnet_map.id << 32) & METADATA_VALUE_PAIR_FIRST_MASK),
        :metadata_mask => METADATA_VALUE_PAIR_FLAG | METADATA_VALUE_PAIR_FIRST_MASK | METADATA_VALUE_PAIR_TYPE
      }
    }
    let(:flows) { dp_info.added_flows }

    subject { Vnet::Core::Networks::Virtual.new(dp_info: dp_info, map: vnet_map) }

    it "has flows for destination filtering" do
      subject.install

      expect(flows).to include Vnet::Openflow::Flow.create(
        TABLE_TUNNEL_IDS,
        20,
        {:tunnel_id => (vnet_map.id & TUNNEL_ID_MASK) | TUNNEL_NETWORK},
        nil,
        flow_options.merge(tunnel_md).merge(:goto_table => TABLE_INTERFACE_INGRESS_NW_IF))
      expect(flows).to include Vnet::Openflow::Flow.create(
        TABLE_NETWORK_SRC_CLASSIFIER,
        30,
        network_md,
        nil,
        flow_options.merge(:goto_table => TABLE_ROUTE_INGRESS_INTERFACE))
      expect(flows).to include Vnet::Openflow::Flow.create(
        TABLE_NETWORK_DST_CLASSIFIER,
        30,
        network_md,
        nil,
        flow_options.merge(:goto_table => TABLE_NETWORK_DST_MAC_LOOKUP))
    end
  end
end
