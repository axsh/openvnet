# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "edge" do
  before(:all) do
    setup_legacy_machine

    # Make sure legacy machine has set up flows before the first test
    # sends an arp packet.
    sleep 5
  end

  describe "mac2mac" do
    it "reachable to vnet1" do
      expect(legacy1).to be_reachable_to(vm1, timeout: 40)
    end

    it "not reachable to vnet2" do
      expect(legacy1).not_to be_reachable_to(vm2)
    end

    it "reachable to edge from vnet1" do
      expect(vm1).to be_reachable_to(legacy1)
    end

    it "not reachable to edge from vnet2" do
      expect(vm2).not_to be_reachable_to(legacy1)
    end

    # context "tunnel" do
    #   it "reachable to vnet1" do
    #     expect(legacy1).to be_reachable_to(vm5)
    #   end

    #   it "not reachable to vnet2" do
    #     expect(legacy1).not_to be_reachable_to(vm6)
    #   end
    # end
  end
end
