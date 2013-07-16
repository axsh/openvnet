# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi do
  describe Vnet::NodeApi::RpcProxy do
    let(:conf) do
      double(:conf).tap do |conf|
        conf.stub(:rpc_node_id).and_return("vnmgr")
        conf.stub(:rpc_actor_name).and_return("rpc")
      end
    end

    let(:actor) { double(:actor) }

    let(:node) do
      double(:node).tap do |node|
        node.stub(:[]).with("rpc").and_return(actor)
      end
    end

    before(:each) do
      DCell::Node.stub(:[]).with("vnmgr").and_return(node)
    end

    subject do
      actor.should_receive(:execute).with(:network, :all).and_return([{uuid: "test-uuid"}])
      Vnet::NodeApi::RpcProxy.new(conf).network.all
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
