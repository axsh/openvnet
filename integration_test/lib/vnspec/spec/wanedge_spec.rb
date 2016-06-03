# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "wanedge" do
  describe "from vnet1 to the internet" do
    it "reaches to 8.8.8.8" do
      to_dns = double()
      allow(to_dns).to receive(:ipv4_address).and_return("8.8.8.8")

      expect(vm1).to be_able_to_ping(to_dns, 10)
    end
  end
end
