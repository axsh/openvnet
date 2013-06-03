# -*- coding: utf-8 -*-
require 'spec_helper'

module Vnmgr::ModelWrappers
  class Test < Base; end
end

describe Vnmgr::ModelWrappers::Base do
  describe "single method" do
    let(:model) do
      double(:model).tap do |model|
        model.should_receive(:all).and_return([{uuid: "test-uuid"}])
      end
    end

    let(:proxy) do
      double(:proxy).tap do |proxy|
        proxy.should_receive(:test).and_return(model)
      end
    end

    before(:each) do
      Vnmgr::ModelWrappers::Test.stub(:_proxy).and_return(proxy)
    end

    subject do
      Vnmgr::ModelWrappers::Test.all
    end

    it { expect(subject).to be_a Array }
    it { expect(subject.size).to eq 1 }
    it { expect(subject.first).to be_a Vnmgr::ModelWrappers::Test }
    it { expect(subject.first.uuid).to eq "test-uuid" }
  end

  describe "method chain" do
    let(:model) do
      double(:model).tap do |model|
        model.should_receive(:execute_batch).with([:all], [:delete]).and_return(3)
      end
    end

    let(:proxy) do
      double(:proxy).tap do |proxy|
        proxy.should_receive(:test).and_return(model)
      end
    end
    before(:each) do
      Vnmgr::ModelWrappers::Test.stub(:_proxy).and_return(proxy)
    end

    subject do
      Vnmgr::ModelWrappers::Test.batch.all.delete.commit
    end

    it { expect(subject).to eq 3}
  end
end
