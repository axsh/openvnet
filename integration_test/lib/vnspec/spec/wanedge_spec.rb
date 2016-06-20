# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "wanedge" do
  describe "from vnet1" do
    it "reaches to the gateway" do
      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return("10.210.0.1")

      expect(vm1).to be_able_to_ping(to_gw, 10)
    end
  end
end
