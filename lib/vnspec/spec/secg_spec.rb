# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "security groups" do
  before(:all) { vms.peach { |vm| vm.close_all_listening_ports } }

  describe "rule" do
    describe "tcp:22:10.101.0.12" do
      # No need to listen on tcp port 22 since SSH is already up there
      before(:all) { vm1.tcp_listen(1222) }
      after(:all) { vm1.tcp_close(1222) }

      it "accepts incoming tcp packets on port 22 from '10.101.0.12/32'" do
        expect(vm3).to be_reachable_to(vm1)
      end

      it "blocks other ip addresses" do
        expect(vm5).not_to be_reachable_to(vm1)
      end

      it "Blocks other ports" do
        expect(vm3).not_to be_able_to_send_tcp(vm1, 1222)
      end
    end

    describe "icmp:-1:10.101.0.12" do
      it "accepts incoming icmp from '10.101.0.12/32'" do
        expect(vm3).to be_able_to_ping(vm1)
      end

      it "blocks everything else" do
        expect(vm5).not_to be_able_to_ping(vm1)
      end
    end

    describe "udp:1344:10.101.0.12" do
      # Using before each instead of before all because netcat binds its
      # UDP process to the source ip/port of the first datagram it receives.
      before(:each) { vm1.udp_listen(1344) }
      after(:each) { vm1.udp_close(1344) }

      # This one's only used in one example so it can go in the :all hooks
      before(:all) { vm1.udp_listen(1345) }
      after(:all) { vm1.udp_close(1345) }

      it "accepts incoming udp packets on port 1344 from '10.101.0.12/32'" do
        expect(vm3).to be_able_to_send_udp(vm1, 1344)
      end

      it "Blocks other ports" do
        expect(vm3).not_to be_able_to_send_udp(vm1, 1345)
      end

      it "Blocks other ip addresses" do
        expect(vm5).not_to be_able_to_send_udp(vm1, 1344)
      end
    end

    describe "icmp:-1:0.0.0.0/0" do
      before(:all) do
        vm2.tcp_listen(1456)
        vm2.udp_listen(1456)
      end

      after(:all) do
        vm2.tcp_close(1456)
        vm2.udp_close(1456)
      end

      it "accepts incoming icmp from everywhere" do
        expect(vm4).to be_able_to_ping(vm2)
        expect(vm6).to be_able_to_ping(vm2)
      end

      it "Blocks other traffic" do
        expect(vm4).not_to be_able_to_send_tcp(vm2, 1456)
        expect(vm5).not_to be_able_to_send_udp(vm2, 1456)
      end
    end

    describe "udp:678:10.101.0.0/24" do
      before(:all) do
        vm5.udp_listen(1678)
        vm5.udp_listen(1466)
        vm5.tcp_listen(1466)
      end

      after(:all) do
        vm5.udp_close(1678)
        vm5.udp_close(1466)
        vm5.tcp_close(1466)
      end

      it "accepts incoming udp packets on port 1678 from '10.101.0.0/24'" do
        expect(vm1).to be_able_to_send_udp(vm5, 1678)
        expect(vm3).to be_able_to_send_udp(vm5, 1678)
      end

      it "blocks other traffic" do
        expect(vm1).not_to be_able_to_send_udp(vm5, 1466)
        expect(vm3).not_to be_able_to_send_tcp(vm5, 1466)
        expect(vm3).not_to be_able_to_ping(vm5)
      end
    end
  end

  describe "connection tracking" do
    it "accepts incoming packets on ports that outgoing tcp packets passed through" do
      expect(vm1).to be_reachable_to(vm6)
    end
  end

  describe "isolation" do
    it "accepts all traffic between interfaces in the same security group" do
      expect(vm3).to be_reachable_to(vm4)
    end

    it "doesn't allow other interfaces to do the same" do
      expect(vm5).not_to be_reachable_to(vm4)
    end
  end

end
