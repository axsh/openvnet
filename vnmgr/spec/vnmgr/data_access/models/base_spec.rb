# -*- coding: utf-8 -*-
require 'spec_helper'

module Vnmgr::DataAccess::Models
  class TestModel < Base; end
end

module Vnmgr::Models
  class TestModel < Base
    attr_accessor :name
    def self.aaa
      self.new(:name => :aaa)
    end
    def to_hash
      super.tap {|h| h[:name] = self.name}
    end
  end
end

describe Vnmgr::DataAccess::Models::Base do
  describe "single method" do
    subject { Vnmgr::DataAccess::Models::TestModel.new.aaa }

    context "model method not found" do
      it { expect(subject).to be_a Hash }
      it { expect(subject[:name]).to eq :aaa }
    end

    context "model method implemented" do
      before do
        Vnmgr::DataAccess::Models::TestModel.any_instance.stub(:aaa).and_return(:bbb)
      end
      it { expect(subject).to eq :bbb }
    end
  end

  describe "method chain" do
    let(:dataset) do
      double(:dataset).tap do |dataset|
        dataset.should_receive(:delete).and_return(3)
      end
    end

    before do
      Vnmgr::Models::TestModel.stub(:all).and_return(dataset)
    end

    subject { Vnmgr::DataAccess::Models::TestModel.new.execute_batch([:all], [:delete]) }

    it { expect(subject).to eq 3 }
  end
end
