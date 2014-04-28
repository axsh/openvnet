# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "lease_policy" do
  context "when ipv4 addresses are allocated for vms" do
    it "enable vm1 to reach vm3 with the allocated ipv4 address" do
      expect(vm1).to be_reachable_to(vm3)
    end

    it "enable vm1 to reach vm5 with the allocated ipv4 address" do
      expect(vm1).to be_reachable_to(vm5)
    end
  end

  context "when an allocated ipv4 addresses are released" do
    before(:all) do
      vm1.interfaces.first.mac_leases.first.ip_leases.first.destroy
      vm1.restart_network
    end

    it "disable vm1 to reach vm3" do
      expect(vm1).not_to be_reachable_to(vm3)
    end

    it "disable vm1 to reach vm5" do
      expect(vm1).not_to be_reachable_to(vm5)
    end
  end

  context "when ipv4 addresses are allocated again" do
    before(:all) do
      Vnspec::Models::LeasePolicy.find("lp-1").tap do |lease_policy|
        lease_policy.remove_interface(vm1.interfaces.first.uuid)
        lease_policy.add_interface(vm1.interfaces.first.uuid)
      end
      vm1.restart_network
    end

    it "enable vm1 to reach vm3 with the allocated ipv4 address" do
      expect(vm1).to be_reachable_to(vm3)
    end

    it "enable vm1 to reach vm5 with the allocated ipv4 address" do
      expect(vm1).to be_reachable_to(vm5)
    end
  end
end
