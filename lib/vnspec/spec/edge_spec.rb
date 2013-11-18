# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "edge" do
  before(:all) do
    setup_legacy_machine
  end

  describe "mac2mac" do
    it "reachable to vnet1" do
      expect(legacy1).to be_reachable_to(vm1)
    end

    it "not reachable to vnet2" do
      expect(legacy1).not_to be_reachable_to(vm2)
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
