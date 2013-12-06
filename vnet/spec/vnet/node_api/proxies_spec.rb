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
      Vnet::NodeApi::RpcProxy.new.network.all
    end

    it { expect(subject).to be_a Array }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Hash }
    it { expect(subject.first[:uuid]).to eq "test-uuid" }
  end

  describe Vnet::NodeApi::DirectProxy do
    describe "without options" do
      before(:each) do
        Vnet::Models::Network.stub(:all).and_return([{uuid: "test-uuid"}])
      end

      subject do
        Vnet::NodeApi::DirectProxy.new.network.all
      end

      it { should be_a Array }
      it { expect(subject.size).to eq 1 }
      it { expect(subject.first).to be_a Hash }
      it { expect(subject.first[:uuid]).to eq "test-uuid" }
    end

    describe "raise_on_error" do
      it "raises an execption" do
        options = { raise_on_error: true }
        expect { Vnet::NodeApi::DirectProxy.new(options).network.foo }.to raise_error
      end

      it "does not raise any exception" do
        options = { raise_on_error: false }
        expect { Vnet::NodeApi::DirectProxy.new(options).network.foo }.not_to raise_error
      end
    end
  end
end
