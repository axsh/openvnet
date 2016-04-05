# -*- coding: utf-8 -*-
require 'spec_helper'

module Vnet::NodeApi
  class TestModel < Base; end
end

module Vnet::Models
  class TestModel < Base
    attr_accessor :name, :friend, :rival
    def self.aaa
      self.new(:name => :aaa)
    end

    def to_hash
      super.tap {|h| h[:name] = self.name}
    end
  end
end

describe Vnet::NodeApi::Base do
  describe "single method" do
    subject { Vnet::NodeApi::TestModel.execute(:aaa) }

    context "model method not found" do
      it { expect(subject).to be_a Hash }
      it { expect(subject[:name]).to eq :aaa }
    end
  end

  describe "method chain" do
    let(:models) do
      model = Vnet::Models::TestModel.new(name: :aaa)
      model.friend = Vnet::Models::TestModel.new(name: :bbb)
      model.rival = Vnet::Models::TestModel.new(name: :ccc)
      model.rival.friend = Vnet::Models::TestModel.new(name: :ddd)
      model.rival.rival = Vnet::Models::TestModel.new(name: :eee)
      [model]
    end

    before do
      allow(Vnet::Models::TestModel).to receive_message_chain(:all, :active).and_return(models)
    end

    context "without options" do
      subject { Vnet::NodeApi::TestModel.execute_batch([:all], [:active]) }

      it { expect(subject).to be_a Array }
      it { expect(subject.size).to eq 1 }
      it { expect(subject.first).to be_a Hash }
      it { expect(subject.first[:class_name]).to eq "TestModel" }
      it { expect(subject.first[:name]).to eq :aaa }
      it { expect(subject.first[:friend]).to be_nil }
    end

    context "fill" do
      subject { Vnet::NodeApi::TestModel.execute_batch([:all], [:active], { :fill => [ :friend, { :rival => [ :friend, :rival ] } ] }) }

      it { expect(subject).to be_a Array }
      it { expect(subject.size).to eq 1 }
      it { expect(subject.first[:name]).to eq :aaa }
      it { expect(subject.first[:friend][:name]).to eq :bbb }
      it { expect(subject.first[:rival][:name]).to eq :ccc }
      it { expect(subject.first[:rival][:friend][:name]).to eq :ddd }
      it { expect(subject.first[:rival][:rival][:name]).to eq :eee }
    end
  end
end
