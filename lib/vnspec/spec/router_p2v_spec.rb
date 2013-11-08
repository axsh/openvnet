# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "router_p2v" do
  before(:all) do
    # add routes
    [vm1, vm3].each do |vm|
      vm.ssh_on_guest("ip route add default via #{config[:dataset_options][:public_router_ipv4_address]}")
    end

    [vm5].each do |vm|
      vm5.ssh_on_guest("ip route add default via 10.101.0.1")
    end

    [vm2, vm4, vm6].each do |vm|
      vm.ssh_on_guest("ip route add default via 10.102.0.1")
    end
  end

  describe "pnet" do
    context "mac2mac" do
      it "reachable to pnet" do
        expect(vm1).to be_reachable_to(vm3)
        expect(vm3).to be_reachable_to(vm1)
      end

      it "reachable to vnet" do
        expect(vm1).to be_reachable_to(vm2)
        expect(vm1).to be_reachable_to(vm4)
        expect(vm3).to be_reachable_to(vm2)
        expect(vm3).to be_reachable_to(vm4)
      end
    end

    context "tunnel" do
      it "reachable to vnet" do
        expect(vm1).to be_reachable_to(vm6)
        expect(vm3).to be_reachable_to(vm6)
      end
    end
  end

  describe "vnet" do
    context "mac2mac" do
      it "reachable to pnet" do
        expect(vm2).to be_reachable_to(vm1)
        expect(vm2).to be_reachable_to(vm3)
        expect(vm4).to be_reachable_to(vm1)
        expect(vm4).to be_reachable_to(vm3)
      end

      it "reachable to vnet" do
        expect(vm2).to be_reachable_to(vm4)
        expect(vm4).to be_reachable_to(vm2)
      end
    end

    context "tunnel" do
      it "reachable to pnet" do
        expect(vm6).to be_reachable_to(vm1)
        expect(vm6).to be_reachable_to(vm3)
      end

      it "reachable to vnet" do
        expect(vm2).to be_reachable_to(vm6)
        expect(vm4).to be_reachable_to(vm6)
        expect(vm6).to be_reachable_to(vm2)
        expect(vm6).to be_reachable_to(vm4)
      end
    end
  end
end
