# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "simple_seg", :vm_skip_dhcp => true do
  before(:all) do
    # vm1.change_ip_address('10.101.0.10')
    # vm2.change_ip_address('10.101.0.10')
    # vm3.change_ip_address('10.101.0.11')
    # vm4.change_ip_address('10.101.0.11')
    # vm5.change_ip_address('10.101.0.12')
    # vm6.change_ip_address('10.101.0.12')
  end

  describe "vnet1" do
    context "mac2mac" do
      it "reachable to vnet1" do
        expect(vm1).to be_reachable_to(vm3)
      end

      it "not reachable to vnet2" do
        expect(vm1).not_to be_reachable_to(vm4)
      end
    end

    context "mac2mac over gre tunnel" do
      it "reachable to vnet1" do
        expect(vm1).to be_reachable_to(vm5)
      end

      it "not reachable to vnet2" do
        expect(vm1).not_to be_reachable_to(vm6)
      end
    end
  end

  describe "vnet2" do
    context "mac2mac" do
      it "reachable to vnet2" do
        expect(vm2).to be_reachable_to(vm4)
      end

      it "not reachable to vnet1" do
        expect(vm2).not_to be_reachable_to(vm3)
      end
    end

    context "mac2mac over gre tunnel" do
      it "reachable to vnet2" do
        expect(vm2).to be_reachable_to(vm6)
      end

      it "not reachable to vnet1" do
        expect(vm2).not_to be_reachable_to(vm5)
      end
    end
  end
end
