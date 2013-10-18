# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::ModelWrappers::VlanTranslation do
  let(:vlan_translation) do
    Fabricate(:vlan_translation) do
      mac_address 0
      vlan_id 1
      network_id 1
    end
  end

  subject { Vnet::ModelWrappers::VlanTranslation.batch[vlan_translation.id].commit }
  it { expect(subject).to be_a Vnet::ModelWrappers::VlanTranslation }
  it { expect(subject.mac_address).to eq 0 }
  it { expect(subject.vlan_id).to eq 1 }
  it { expect(subject.network_id).to eq 1 }
end
