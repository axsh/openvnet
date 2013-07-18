# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi do
  describe Vnet::NodeApi::RpcProxy do
    let(:actor) { double(:actor) }

    before(:each) do
      DCell::Global.stub(:[]).with(:rpc).and_return(actor)
    end

    subject do
      actor.should_receive(:execute).with(:network, :all).and_return([{uuid: "test-uuid"}])
      Vnet::NodeApi::RpcProxy.new(double(:conf)).network.all
    end

    it { expect(subject).to be_a Array }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Hash }
    it { expect(subject.first[:uuid]).to eq "test-uuid" }
  end

  describe Vnet::NodeApi::DirectProxy do
    let(:conf) do
      double(:conf)
    end

    before(:each) do
      Vnet::Models::Network.stub(:all).and_return([{uuid: "test-uuid"}])
    end

    subject do
      Vnet::NodeApi::DirectProxy.new(conf).network.all
    end

    it { should be_a Array }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Hash }
    it { expect(subject.first[:uuid]).to eq "test-uuid" }
  end
end
