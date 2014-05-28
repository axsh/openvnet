# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "security groups" do
  before(:all) { vms.parallel { |vm| vm.close_all_listening_ports } }

  describe "reference" do
    describe "sg-reffer1" do

      it "accepts ssh traffic from interfaces in sg-reffee1" do
        expect(vm2).to be_reachable_to(vm1)
        expect(vm3).to be_reachable_to(vm1)
      end

      it "blocks ssh traffic from other interfaces" do
        expect(vm4).not_to be_reachable_to(vm1)
        expect(vm5).not_to be_reachable_to(vm1)
      end

      it "dynamically updates the ip lists in the referenced groups" do
        vm2.remove_security_group('sg-reffee1')
        expect(vm2).not_to be_reachable_to(vm1)

        vm4.add_security_group('sg-reffee1')
        vm5.add_security_group('sg-reffee1')

        expect(vm4).to be_reachable_to(vm1)
        expect(vm5).to be_reachable_to(vm1)
      end
    end
  end
end
