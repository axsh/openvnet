# -*- coding: utf-8 -*-

require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Core::TranslationManager do
  describe "update" do
    before do
      Fabricate(:vlan_translation) do
        vlan_id 1
        network_id 1
      end
    end
    let(:datapath) { MockDatapath.new(double, ("a"*16).to_i(16)) }

    subject { Vnet::Core::TranslationManager.new(datapath) }

    it "creates strip vlan id flow" do
    end
  end
end
