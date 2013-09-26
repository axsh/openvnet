# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::VlanTranslation do
  before do
    Fabricate(:vlan_translation) do
      mac_address 0
      vlan_id 1
      network_id 1
    end
  end

  it "creates an entry" do
    expect(Vnet::Models::VlanTranslation.first.mac_address).to eq 0
    expect(Vnet::Models::VlanTranslation.first.vlan_id).to eq 1
    expect(Vnet::Models::VlanTranslation.first.network_id).to eq 1
  end
end
