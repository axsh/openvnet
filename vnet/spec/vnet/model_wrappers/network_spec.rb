# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::ModelWrappers::Network do
  let(:network) do
    Fabricate(:network).tap do |n|
      n.add_interface(Fabricate(:iface))
    end
  end

  context "with real proxy" do
    subject { Vnet::ModelWrappers::Network.batch[network.canonical_uuid].interfaces.first.commit }
    it { expect(subject).to be_a Vnet::ModelWrappers::Interface }
    it { expect(subject.uuid).to eq network.interfaces.first.canonical_uuid }
  end
end
