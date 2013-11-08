# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "router_v2v" do
  before(:all) do
    # add routes
    [vm1, vm3, vm5].each do |vm|
      vm.ssh_on_guest("ip route add default via 10.101.0.1")
    end

    [vm2, vm4, vm6].each do |vm|
      vm.ssh_on_guest("ip route add default via 10.102.0.1")
    end
  end

  describe "vnet1" do
    context "mac2mac" do
      it "reachable to vnet1" do
        expect(vm1).to be_reachable_to(vm3)
        expect(vm3).to be_reachable_to(vm1)
      end

      it "reachable to vnet2" do
        expect(vm1).to be_reachable_to(vm2)
        expect(vm1).to be_reachable_to(vm4)
        expect(vm3).to be_reachable_to(vm2)
        expect(vm3).to be_reachable_to(vm4)
        expect(vm5).to be_reachable_to(vm6)
      end
    end

    context "tunnel" do
      it "reachable to vnet1" do
        expect(vm1).to be_reachable_to(vm5)
        expect(vm3).to be_reachable_to(vm5)
        expect(vm5).to be_reachable_to(vm1)
        expect(vm5).to be_reachable_to(vm3)
      end

      it "reachable to vnet2" do
        expect(vm1).to be_reachable_to(vm6)
        expect(vm3).to be_reachable_to(vm6)
        expect(vm5).to be_reachable_to(vm2)
        expect(vm5).to be_reachable_to(vm4)
      end
    end
  end

  describe "vnet2" do
    context "mac2mac" do
      it "reachable to vnet1" do
        expect(vm2).to be_reachable_to(vm1)
        expect(vm2).to be_reachable_to(vm1)
        expect(vm4).to be_reachable_to(vm3)
        expect(vm4).to be_reachable_to(vm3)
        expect(vm6).to be_reachable_to(vm5)
      end

      it "reachable to vnet2" do
        expect(vm2).to be_reachable_to(vm4)
        expect(vm4).to be_reachable_to(vm2)
      end
    end

    context "tunnel" do
      it "reachable to vnet1" do
        expect(vm2).to be_reachable_to(vm5)
        expect(vm4).to be_reachable_to(vm5)
        expect(vm6).to be_reachable_to(vm1)
        expect(vm6).to be_reachable_to(vm3)
      end

      it "reachable to vnet2" do
        expect(vm2).to be_reachable_to(vm6)
        expect(vm4).to be_reachable_to(vm6)
        expect(vm6).to be_reachable_to(vm2)
        expect(vm6).to be_reachable_to(vm4)
      end
    end
  end
end
