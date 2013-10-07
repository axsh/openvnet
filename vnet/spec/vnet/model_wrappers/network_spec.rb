# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::ModelWrappers::Network do
  let(:network) do
    Fabricate(:network, :ip_addresses => [Fabricate(:ip_address)])
  end

  context "with real proxy" do
    subject { Vnet::ModelWrappers::Network.batch[network.canonical_uuid].ip_addresses.first.commit }
    it { expect(subject).to be_a Vnet::ModelWrappers::IpAddress }
    it { expect(subject.id).to eq network.ip_addresses.first.id }
  end
end
