# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "edge" do
  before(:all) do
    setup_legacy_machine
  end

  describe "mac2mac" do
    it "reachable to vnet1" do
      expect(legacy_esxi).to be_reachable_to(vm1, :timeout => 20)
    end

    it "not reachable to vnet2" do
      expect(legacy_esxi).not_to be_reachable_to(vm2)
    end

    it "reachable to edge from vnet1" do
      expect(vm1).to be_reachable_to(legacy_esxi)
    end

    it "not reachable to edge from vnet2" do
      expect(vm2).not_to be_reachable_to(legacy_esxi)
    end

    # context "tunnel" do
    #   it "reachable to vnet1" do
    #     expect(legacy_esxi).to be_reachable_to(vm5)
    #   end

    #   it "not reachable to vnet2" do
    #     expect(legacy_esxi).not_to be_reachable_to(vm6)
    #   end
    # end
  end
end
