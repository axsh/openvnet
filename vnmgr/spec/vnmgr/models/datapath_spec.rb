# -*- coding: utf-8 -*-
require 'spec_helper'
require 'pp'

describe Vnmgr::Models::Datapath do
  before(:each) do
    # @datapath_1 = Fabricate(:datapath_1)
    # @datapath_2 = Fabricate(:datapath_2)
    # @datapath_3 = Fabricate(:datapath_3)
    @datapath_1 = Fabricate(:datapath_network) do
      datapath { Fabricate(:datapath_1) }
      network_id 1
    end.datapath
    @datapath_2 = Fabricate(:datapath_network) do
      datapath { Fabricate(:datapath_2) }
      network_id 1
    end.datapath
    @datapath_3 = Fabricate(:datapath_network) do
      datapath { Fabricate(:datapath_3) }
      network_id 2
    end.datapath
  end

  describe "datapath_networks_on_segment" do
    subject { Vnmgr::Models::DatapathNetwork.on_segment(@datapath_1).all }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Vnmgr::Models::DatapathNetwork }
    it { expect(subject.first.datapath.id).to eq @datapath_2.id }
  end

  describe "datapath_networks_on_other_segment" do
    subject { Vnmgr::Models::DatapathNetwork.on_other_segment(@datapath_1).all }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Vnmgr::Models::DatapathNetwork }
    it { expect(subject.first.datapath_id).to eq @datapath_3.id }
  end
end
