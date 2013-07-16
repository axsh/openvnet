# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::DataAccess do
  describe Vnet::DataAccess::DbaProxy do
    let(:conf) do
      double(:conf).tap do |conf|
        conf.stub(:dba_node_id).and_return("dba")
        conf.stub(:dba_actor_name).and_return("dba")
      end
    end

    let(:actor) { double(:actor) }

    let(:node) do
      double(:node).tap do |node|
        node.stub(:[]).with("dba").and_return(actor)
      end
    end

    before(:each) do
      DCell::Node.stub(:[]).with("dba").and_return(node)
    end

    subject do
      actor.should_receive(:execute).with(:network, :all).and_return([{uuid: "test-uuid"}])
      Vnet::DataAccess::DbaProxy.new(conf).network.all
    end

    it { expect(subject).to be_a Array }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Hash }
    it { expect(subject.first[:uuid]).to eq "test-uuid" }
  end

  describe Vnet::DataAccess::DirectProxy do
    let(:conf) do
      double(:conf)
    end

    before(:each) do
      Vnet::Models::Network.stub(:all).and_return([{uuid: "test-uuid"}])
    end

    subject do
      Vnet::DataAccess::DirectProxy.new(conf).network.all
    end

    it { should be_a Array }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Hash }
    it { expect(subject.first[:uuid]).to eq "test-uuid" }
  end
end
