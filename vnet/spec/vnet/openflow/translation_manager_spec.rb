# -*- coding: utf-8 -*-

require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::TranslationManager do
  describe "update" do
    before do
      Fabricate(:vlan_translation) do
        vlan_id 1
        network_id 1
      end
    end
    let(:datapath) { MockDatapath.new(double, ("a"*16).to_i(16)) }

    subject { Vnet::Openflow::TranslationManager.new(datapath) }

    it "creates strip vlan id flow" do
      subject.update
      expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
        TABLE_VLAN_TRANSLATION,
        2,
        {:dl_vlan => 1},
        {:strip_vlan => true},
        {:metadata => 1 | METADATA_TYPE_NETWORK,
         :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK,
         :goto_table => TABLE_VIF_PORTS})
    end
  end
end
