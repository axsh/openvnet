# -*- coding: utf-8 -*-
require 'spec_helper'

module Vnmgr::ModelWrappers
  class Test < Base; end
  class TestChild < Base; end
  class TestGrandChild < Base; end
end

describe Vnmgr::ModelWrappers::Base do
  let(:test) { {id: 1, uuid: "t-xxx", class_name: "Test"} }
  let(:test_child) { {id: 1, uuid: "tc-xxx", class_name: "TestChild"} }
  let(:test_grand_child) { {id: 1, uuid: "tgc-xxx", class_name: "TestGrandChild"} }

  describe "class method" do
    describe "single execution" do
      let(:model) do
        double(:model).tap do |model|
          model.should_receive(:all).and_return([test])
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
      it { expect(subject.first.uuid).to eq "t-xxx" }
    end

    describe "batch" do
      let(:model) do
        double(:model).tap do |model|
          model.should_receive(:execute_batch).with([:[], "t-xxx"], [:children], [:first], {}).and_return(test_child)
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
        Vnmgr::ModelWrappers::Test.batch["t-xxx"].children.first.commit
      end

      it { expect(subject).to be_a Vnmgr::ModelWrappers::TestChild }
      it { expect(subject.uuid).to eq "tc-xxx" }
    end

    describe "commit" do
      let(:test_child_with_grand_children) do
        test_child.tap {|h| h[:grand_children] = [test_grand_child] }
      end

      let(:model) do
        double(:model).tap do |model|
          model.should_receive(:execute_batch).with([:[], "t-xxx"], [:children], [:first], {:fill => :grand_children}).and_return(test_child_with_grand_children)
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
        Vnmgr::ModelWrappers::Test.batch["t-xxx"].children.first.commit(:fill => :grand_children)
      end

      it { expect(subject).to be_a Vnmgr::ModelWrappers::TestChild }
      it { expect(subject.grand_children).to be_a Array }
      it { expect(subject.grand_children.size).to eq 1 }
      it { expect(subject.grand_children.first).to be_a Vnmgr::ModelWrappers::TestGrandChild }
      it { expect(subject.grand_children.first.uuid).to eq "tgc-xxx" }
    end
  end

  describe "instance method" do
    describe "batch" do
      let(:model) do
        double(:model).tap do |model|
          model.should_receive(:[]).with("t-xxx").and_return(test)
          model.should_receive(:execute_batch).with([:[], 1], [:update, {:name => "test"}], {}).and_return(test.merge(name: "test"))
        end
      end

      let(:proxy) do
        double(:proxy).tap do |proxy|
          proxy.should_receive(:test).twice.and_return(model)
        end
      end

      before(:each) do
        Vnmgr::ModelWrappers::Test.stub(:_proxy).and_return(proxy)
      end

      it "execute batch" do
        test = Vnmgr::ModelWrappers::Test["t-xxx"]
        test = test.batch.update(:name => "test").commit
        expect(test).to be_a Vnmgr::ModelWrappers::Test
        expect(test.name).to eq "test"
      end
    end
  end
end
