# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::ModelWrappers::Network do
  let(:network) do
    Fabricate(:network).tap do |n|
      n.add_iface(Fabricate(:iface))
    end
  end

  context "with real proxy" do
    subject { Vnet::ModelWrappers::Network.batch[network.canonical_uuid].ifaces.first.commit }
    it { expect(subject).to be_a Vnet::ModelWrappers::Iface }
    it { expect(subject.uuid).to eq network.ifaces.first.canonical_uuid }
    it { expect(subject.mac_addr).to eq 0 }
  end
end
