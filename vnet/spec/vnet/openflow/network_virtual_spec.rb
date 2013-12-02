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
    include_context :ofc_double

    let(:vnet_map) { Vnet::ModelWrappers::Network['nw-aaaaaaaa'] }
    let(:datapath) { MockDatapath.new(ofc, ("a" * 16).to_i) }
    let(:flow_options) { {:cookie => vnet_map.id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)} }
    let(:network_md) { subject.md_create(:network => vnet_map.id) }
    let(:fo_network_md) { flow_options.merge(network_md) }
    let(:flows) { datapath.added_flows }

    subject { Vnet::Openflow::Networks::Virtual.new(datapath, vnet_map) }

    it "has flows for destination filtering" do
      subject.install
      expect(flows).to include Vnet::Openflow::Flow.create(
        TABLE_TUNNEL_NETWORK_IDS,
        30,
        {:tunnel_id => vnet_map.id | TUNNEL_FLAG_MASK},
        nil,
        fo_network_md.merge(:goto_table => TABLE_NETWORK_SRC_CLASSIFIER))
      expect(flows).to include Vnet::Openflow::Flow.create(
        TABLE_NETWORK_SRC_CLASSIFIER,
        40,
        network_md,
        nil,
        flow_options.merge(:goto_table => TABLE_VIRTUAL_SRC))
      expect(flows).to include Vnet::Openflow::Flow.create(
        TABLE_NETWORK_DST_CLASSIFIER,
        40,
        network_md,
        nil,
        flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))
    end
  end
end
