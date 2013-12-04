# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "security groups" do
  describe "rule" do
    describe "tcp:22:10.101.0.11" do
      it "accepts incoming tcp packets on port 22 from '10.101.0.11/32'" do
        expect(vm3).to be_reachable_to(vm1)
      end

      it "blocks everything else" do
        expect(vm5).not_to be_reachable_to(vm1)
      end
    end
  end

  describe "connection tracking" do
    it "accepts incoming packets on ports that outgoing tcp packets passed through" do
      expect(vm1).to be_reachable_to(vm3)
    end
  end
end
