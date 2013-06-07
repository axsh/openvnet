# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnmgr::ModelWrappers::Network do
  let(:network) do
    Fabricate(:network).tap do |n|
      n.add_vif(Fabricate(:vif))
    end
  end

  context "with real proxy" do
    subject { Vnmgr::ModelWrappers::Network.batch[network.canonical_uuid].vifs.first.commit }
    it { expect(subject).to be_a Vnmgr::ModelWrappers::Vif }
    it { expect(subject.uuid).to eq network.vifs.first.canonical_uuid }
    it { expect(subject.mac_addr).to eq "08:00:27:a8:9e:6b".delete(":").hex }
  end
end
