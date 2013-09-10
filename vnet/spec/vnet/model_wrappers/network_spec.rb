# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::ModelWrappers::Network do
  let(:network) do
    Fabricate(:network).tap do |n|
      n.add_vif(Fabricate(:vif))
    end
  end

  context "with real proxy" do
    subject { Vnet::ModelWrappers::Network.batch[network.canonical_uuid].vifs.first.commit }
    it { expect(subject).to be_a Vnet::ModelWrappers::Vif }
    it { expect(subject.uuid).to eq network.vifs.first.canonical_uuid }
    it { expect(subject.mac_address).to eq 0 }
  end
end
