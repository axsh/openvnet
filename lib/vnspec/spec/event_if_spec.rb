# -*- coding: utf-8 -*-
require_relative "spec_helper"

shared_examples "vm1(unreachable)" do
  describe "vm1(vnet1)" do
    context "mac2mac" do
      it "not reachable to vm3(vnet1)" do
        expect(vm1).not_to be_reachable_to(vm3)
      end

      it "not reachable to vm4(vnet1)" do
        expect(vm1).not_to be_reachable_to(vm4)
      end
    end

    context "tunnel" do
      it "not reachable to vm5(vnet1)" do
        expect(vm1).not_to be_reachable_to(vm5)
      end

      it "not reachable to vm6(vnet2)" do
        expect(vm1).not_to be_reachable_to(vm6)
      end
    end
  end
end

describe "event_if" do
  describe "ip_lease" do
    describe "release" do
      before(:all) do
        vm1.interfaces.first.mac_leases.first.ip_leases.first.destroy
      end

      it_behaves_like "vm1(unreachable)"
    end

    describe "lease ipv4_address(vnet2)" do
      before(:all) do
        # change to vnet2
        vm1.interfaces.first.mac_leases.first.add_ip_lease(network_uuid: "nw-vnet2", ipv4_address: "10.101.0.20")
        vm1.restart_network
      end

      describe "vm1(vnet2)" do
        context "mac2mac" do
          it "not reachable to vm3(vnet1)" do
            expect(vm1).not_to be_reachable_to(vm3)
          end
          it "reachable to vm4(vnet2)" do
            expect(vm1).to be_reachable_to(vm4)
          end
        end

        context "tunnel" do
          it "not reachable to vm5(vnet1)" do
            expect(vm1).not_to be_reachable_to(vm5)
          end

          it "reachable to vm6(vnet2)" do
            expect(vm1).to be_reachable_to(vm6)
          end
        end
      end
    end
  end

  describe "mac_lease" do
    describe "release" do
      before(:all) do
        vm1.interfaces.first.mac_leases.first.destroy
      end

      it_behaves_like "vm1(unreachable)"
    end

    describe "lease" do
      before(:all) do
        # TODO change to other mac address
        vm1.interfaces.first.add_mac_lease(mac_address: "02:00:00:00:00:01")
        sleep(1)
        # change to vnet1
        vm1.interfaces.first.mac_leases.first.add_ip_lease(network_uuid: "nw-vnet1", ipv4_address: "10.101.0.10")
        vm1.restart_network
      end

      describe "vm1(vnet1)" do
        context "mac2mac" do
          it "reachable to vm3(vnet1)" do
            expect(vm1).to be_reachable_to(vm3)
          end
          it "not reachable to vm4(vnet2)" do
            expect(vm1).not_to be_reachable_to(vm4)
          end
        end

        context "tunnel" do
          it "reachable to vm5(vnet1)" do
            expect(vm1).to be_reachable_to(vm5)
          end

          it "not reachable to vm6(vnet2)" do
            expect(vm1).not_to be_reachable_to(vm6)
          end
        end
      end
    end
  end

  # 
  # pending
  #
  #describe "interface" do
  #  describe "release" do
  #    before(:all) do
  #      vm1.remove_interface("if-v1")
  #    end
  #
  #    it_behaves_like "vm1(unreachable)"
  #  end
  #
  #  describe "lease" do
  #    before(:all) do
  #      vm1.add_interface(
  #        uuid: "if-v1",
  #        mac_address: "02:00:00:00:00:01",
  #        network_uuid: "nw-vnet1",
  #        ipv4_address: "10.101.0.10"
  #      )
  #
  #      sleep(3)
  #
  #      vm1.restart_network
  #    end
  #
  #    describe "vm1(vnet1)" do
  #      context "mac2mac" do
  #        it "reachable to vm3(vnet1)" do
  #          expect(vm1).to be_reachable_to(vm3)
  #        end
  #        it "not reachable to vm4(vnet2)" do
  #          expect(vm1).not_to be_reachable_to(vm4)
  #        end
  #      end
  #
  #      context "tunnel" do
  #        it "reachable to vm5(vnet1)" do
  #          expect(vm1).to be_reachable_to(vm5)
  #        end
  #
  #        it "not reachable to vm6(vnet2)" do
  #          expect(vm1).not_to be_reachable_to(vm6)
  #        end
  #      end
  #    end
  #  end
  #end
end
