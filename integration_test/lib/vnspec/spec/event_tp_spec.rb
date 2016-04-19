# -*- coding: utf-8 -*-

require_relative "spec_helper"

shared_examples_for "vm(reachable)" do |vm|
  describe "#{vm.name}(#{vm.network})" do
    context "mac2mac" do
      it "reachable to vm3(vnet1)" do
        expect(vm).to be_reachable_to(vm3)
      end
      it "reachable to vm4(vnet2)" do
        expect(vm).to be_reachable_to(vm4)
      end
    end

    context "tunnel" do
      it "reachable to vm5(vnet1)" do
        expect(vm).to be_reachable_to(vm5)
      end

      it "reachable to vm6(vnet2)" do
        expect(vm).to be_reachable_to(vm6)
      end
    end
  end
end

shared_examples_for "vm(unreachable)" do |vm|
  describe "#{vm.name}(#{vm.network})" do
    context "mac2mac" do
      it "not reachable to vm3(vnet1)" do
        expect(vm1).not_to be_reachable_to(vm3)
      end

      it "not reachable to vm4(vnet2)" do
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

describe "event" do
  describe "datapath" do
    before(:each) do
      vms.parallel { |vm| vm.clear_arp_cache }
    end

    describe "remove" do
      before(:all) do
        datapath = Vnspec::Models::Datapath.find("dp-1")
        datapath.destroy
        sleep(1)
      end

      context "from vm1(vnet1)" do
        it_behaves_like "vm(unreachable)", vm1
      end
    end

    # TODO: Enable once topology manager supports updates to host
    # interface.

    # describe "add" do
    #   before(:all) do
    #     datapath = Vnspec::Models::Datapath.create(
    #       uuid: "dp-new",
    #       node_id: "vna1",
    #       display_name: "node1",
    #       dpid: "0x0000aaaaaaaaaaaa",
    #     )

    #     sleep(1)

    #     Vnspec::Models::Interface.find("if-dp1eth0").update_host_interface("dp-new", "eth0")

    #     sleep(1)

    #     vm1.restart_network

    #     sleep(1)
    #   end

    #   it_behaves_like "vm(reachable)", vm1
    # end
  end
end
