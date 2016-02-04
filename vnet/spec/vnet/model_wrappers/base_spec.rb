# -*- coding: utf-8 -*-
require 'spec_helper'

module Vnet::ModelWrappers
  class Parent < Base; end
  class Child < Base; end
  class ChildFriend < Base; end
  class GrandChild < Base; end
  class GrandChildFriend < Base; end
end

describe Vnet::ModelWrappers::Base do
  let(:parent) { {id: 1, uuid: "p-xxx", class_name: "Parent"} }
  let(:child) { {id: 1, uuid: "c-xxx", class_name: "Child"} }
  let(:child_friend) { {id: 1, uuid: "cf-xxx", class_name: "ChildFriend"} }
  let(:grand_child) { {id: 1, uuid: "gc-xxx", class_name: "GrandChild"} }
  let(:grand_child_friend) { {id: 1, uuid: "gcf-xxx", class_name: "GrandChildFriend"} }

  describe "class method" do
    describe "single execution" do
      let(:model) do
        double(:model).tap do |model|
          allow(model).to receive(:execute).with(:all).and_return([parent])
        end
      end

      let(:proxy) do
        double(:proxy).tap do |proxy|
          allow(proxy).to receive(:parent).at_least(:once).and_return(model)
        end
      end

      before(:each) do
        allow(Vnet::ModelWrappers::Parent).to receive(:_proxy).and_return(proxy)
      end

      subject do
        Vnet::ModelWrappers::Parent.all
      end

      it { expect(subject).to be_a Array }
      it { expect(subject.size).to eq 1 }
      it { expect(subject.first).to be_a Vnet::ModelWrappers::Parent }
      it { expect(subject.first.uuid).to eq "p-xxx" }
    end

    describe "batch" do
      let(:model) do
        double(:model).tap do |model|
          allow(model).to receive(:execute_batch).with([:[], "p-xxx"], [:children], [:first], {}).and_return(child)
        end
      end

      let(:proxy) do
        double(:proxy).tap do |proxy|
          allow(proxy).to receive(:parent).and_return(model)
        end
      end

      before(:each) do
        allow(Vnet::ModelWrappers::Parent).to receive(:_proxy).and_return(proxy)
      end

      subject do
        Vnet::ModelWrappers::Parent.batch["p-xxx"].children.first.commit
      end

      it { expect(subject).to be_a Vnet::ModelWrappers::Child }
      it { expect(subject.uuid).to eq "c-xxx" }
    end

    describe "commit" do
      let(:grand_child_with_friends) do
        grand_child.tap {|h| h[:friends] = [grand_child_friend] }
      end

      let(:child_with_children_and_friends) do
        child.tap {|h| h[:children] = [grand_child_with_friends] }
        child.tap {|h| h[:friends] = [child_friend] }
      end

      let(:model) do
        double(:model).tap do |model|
          allow(model).to receive(:execute_batch).with([:[], "p-xxx"], [:children], [:first], {:fill => [:friends, {:children => :friends}] }).and_return(child_with_children_and_friends)
        end
      end

      let(:proxy) do
        double(:proxy).tap do |proxy|
          allow(proxy).to receive(:parent).and_return(model)
        end
      end

      before(:each) do
        allow(Vnet::ModelWrappers::Parent).to receive(:_proxy).and_return(proxy)
      end

      subject do
        Vnet::ModelWrappers::Parent.batch["p-xxx"].children.first.commit(:fill => [:friends, {:children => :friends}])
      end

      it { expect(subject).to be_a Vnet::ModelWrappers::Child }
      it { expect(subject.friends).to be_a Array }
      it { expect(subject.friends.size).to eq 1 }
      it { expect(subject.friends.first).to be_a Vnet::ModelWrappers::ChildFriend }
      it { expect(subject.friends.first.uuid).to eq "cf-xxx" }
      it { expect(subject.children).to be_a Array }
      it { expect(subject.children.size).to eq 1 }
      it { expect(subject.children.first).to be_a Vnet::ModelWrappers::GrandChild }
      it { expect(subject.children.first.uuid).to eq "gc-xxx" }
      it { expect(subject.children.first.friends).to be_a Array }
      it { expect(subject.children.first.friends.size).to eq 1 }
      it { expect(subject.children.first.friends.first).to be_a Vnet::ModelWrappers::GrandChildFriend }
      it { expect(subject.children.first.friends.first.uuid).to eq "gcf-xxx" }
    end
  end

  describe "instance method" do
    describe "batch" do
      let(:model) do
        double(:model).tap do |model|
          allow(model).to receive(:execute).with(:[], "p-xxx").and_return(parent)
          allow(model).to receive(:execute_batch).with([:[], 1], [:update, {:name => "parent"}], {}).and_return(parent.merge(name: "parent"))
        end
      end

      let(:proxy) do
        double(:proxy).tap do |proxy|
          allow(proxy).to receive(:parent).twice.and_return(model)
        end
      end

      before(:each) do
        allow(Vnet::ModelWrappers::Parent).to receive(:_proxy).and_return(proxy)
      end

      it "execute batch" do
        parent = Vnet::ModelWrappers::Parent["p-xxx"]
        parent = parent.batch.update(:name => "parent").commit
        expect(parent).to be_a Vnet::ModelWrappers::Parent
        expect(parent.name).to eq "parent"
      end
    end
  end
end
