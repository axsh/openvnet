# -*- coding: utf-8 -*-

require 'spec_helper'
require 'vnet/node_api/direct_proxy'
require 'vnet/node_api/rpc_proxy'

describe Vnet::NodeApi do
  describe Vnet::NodeApi::RpcProxy do
    let(:node) { double(:node) }
    let(:actor) { double(:actor) }
    let(:actor_node_id) { 'test_vnmgr' }

    before(:each) {
      mock_dcell_rpc(node, actor, actor_node_id)
    }

    subject {
      expect(actor).to receive(:execute).with(:network, :all).and_return([{uuid: "test-uuid"}])
      Vnet::NodeApi::RpcProxy.new.network.all
    }

    it { expect(subject).to be_a Array }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Hash }
    it { expect(subject.first[:uuid]).to eq "test-uuid" }
  end

  describe Vnet::NodeApi::DirectProxy do
    describe "without options" do
      before(:each) {
        allow(Vnet::Models::Network).to receive(:all).and_return([{uuid: "test-uuid"}])
      }

      subject {
        Vnet::NodeApi::DirectProxy.new.network.all
      }

      it { expect(subject).to be_a Array }
      it { expect(subject.size).to eq 1 }
      it { expect(subject.first).to be_a Hash }
      it { expect(subject.first[:uuid]).to eq "test-uuid" }
    end

    describe "raise_on_error" do
      subject { Vnet::NodeApi::DirectProxy.new.network.foo }
      it "raises an execption" do
        Vnet::NodeApi.raise_on_error = true
        expect { subject }.to raise_error
      end

      it "does not raise any exception" do
        Vnet::NodeApi.raise_on_error = false
        expect { subject }.not_to raise_error
      end
    end
  end
end
