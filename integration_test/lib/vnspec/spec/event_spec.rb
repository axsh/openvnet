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
  describe "ip_lease" do
    describe "release" do
      before(:all) do
        vm1.interfaces.first.mac_leases.first.ip_leases.first.destroy
      end

      it_behaves_like "vm(unreachable)", vm1
    end

    describe "lease ipv4_address(vnet2)" do
      before(:all) do
        # change to vnet2
        vm1.interfaces.first.mac_leases.first.add_ip_lease(network_uuid: "nw-vnet2", ipv4_address: "10.102.0.20")
        sleep(2)
        vm1.restart_network
      end

      it_behaves_like "vm(reachable)", vm1
    end
  end

  describe "mac_lease" do
    describe "release" do
      before(:all) do
        vm1.interfaces.first.mac_leases.first.destroy
      end

      it_behaves_like "vm(unreachable)", vm1
    end

    describe "lease" do
      before(:all) do
        # TODO change to other mac address
        vm1.interfaces.first.add_mac_lease(mac_address: "02:00:00:00:00:01")
        # change to vnet1
        vm1.interfaces.first.mac_leases.first.add_ip_lease(network_uuid: "nw-vnet1", ipv4_address: "10.101.0.10")
        sleep(2)
        vm1.restart_network
      end

      it_behaves_like "vm(reachable)", vm1
    end
  end

  describe "interface" do
    describe "remove" do
      before(:all) do
        vm1.remove_interface("if-v1")
      end

      it_behaves_like "vm(unreachable)", vm1
    end

    describe "add" do
      before(:all) do
        vm1.add_interface(
          uuid: "if-v1",
          mac_address: "02:00:00:00:00:01",
          network_uuid: "nw-vnet1",
          ipv4_address: "10.101.0.10",
          port_name: "if-v1"
        )

        sleep(3)

        vm1.restart_network
      end

      it_behaves_like "vm(reachable)", vm1
    end
  end

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

    describe "add" do
      before(:all) do
        datapath = Vnspec::Models::Datapath.create(
          uuid: "dp-new",
          node_id: "vna1",
          display_name: "node1",
          dpid: "0x0000aaaaaaaaaaaa",
        )

        datapath.add_datapath_network(
          "nw-public1",
          interface_uuid: "if-dp1eth0",
          mac_address: "02:00:00:aa:01:01"
        )

        datapath.add_datapath_network(
          "nw-vnet1",
          interface_uuid: "if-dp1eth0",
          mac_address: "02:00:00:aa:00:01"
        )

        datapath.add_datapath_network(
          "nw-vnet2",
          interface_uuid: "if-dp1eth0",
          mac_address: "02:00:00:aa:00:02"
        )

        sleep(1)

        Vnspec::Models::Interface.find("if-dp1eth0").update_host_interface("dp-new", "eth0")

        sleep(1)

        vm1.restart_network

        sleep(1)
      end

      it_behaves_like "vm(reachable)", vm1
    end
  end
end
