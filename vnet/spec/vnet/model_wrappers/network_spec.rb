# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::ModelWrappers::Network do
  let(:network) do
    Fabricate(:network).tap do |n|
      interface = Fabricate(:interface, owner_datapath: Fabricate(:datapath_1))
      Fabricate(:mac_lease, interface: interface, _mac_address: Fabricate(:mac_address))
      n.add_interface(interface)
    end
  end

  context "with real proxy" do
    subject { Vnet::ModelWrappers::Network.batch[network.canonical_uuid].interfaces.first.commit }
    it { expect(subject).to be_a Vnet::ModelWrappers::Interface }
    it { expect(subject.uuid).to eq network.interfaces.first.canonical_uuid }
  end
end
