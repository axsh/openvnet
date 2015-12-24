require_relative "spec_helper"

describe "filters" do
  before(:all) { vms.parallel { | vm | vm.close_all_listening_ports} }
  
  describe "passthoruh tcp" do
    before(:all) {
      vm3.tcp_listen(7452)
      vm3.tcp_listen(1285)
    }
    after(:all) {
      vm3.tcp_close(7452)
      vm3.tcp_close(1285)
    }
    
    it "vm1 accepts incoming packages on tcp" do
      expect(vm1).to be_reachable_to(vm6)
      expect(vm1).to be_reachable_to(vm5)
    end    
    it "vm1 accepts outgoing packages on tcp" do
      expect(vm6).to be_reachable_to(vm1)
      expect(vm5).to be_reachable_to(vm1)
    end
    it "vm2 blocks incoming packages on tcp" do
      expect(vm2).not_to be_reachable_to(vm6)
      expect(vm2).not_to be_reachable_to(vm5)
    end
    it "vm2 blocks outgoing packages on tcp" do
      expect(vm6).not_to be_reachable_to(vm2)
      expect(vm5).not_to be_reachable_to(vm2)
    end
    it "vm3 accepts incoming packages from 10.101.0.10" do
      expect(vm3).to be_reachable_to(vm1)
    end
    it "vm3 blocks all else" do
      expect(vm3).not_to be_reachable_to(vm6)
      expect(vm3).not_to be_reachable_to(vm5)
    end  
  end

  describe "passthrough udp" do
    before(:each) do 
      vm1.udp_listen(7452)
      vm2.udp_listen(7452)
      vm3.udp_listen(1344)
      vm3.udp_listen(1345)
      vm5.udp_listen(7452)
    end

    after(:each) do
      vm1.udp_close(7452)
      vm2.udp_close(7452)
      vm3.udp_close(1344)
      vm3.udp_close(1345)
      vm5.udp_close(7452)
    end      
    
    it "vm1 accepts incoming packages on udp" do
      expect(vm5).to be_able_to_send_udp(vm1, 7452)
    end    
    it "vm1 accepts outgoing packages on udp" do
      expect(vm1).to be_able_to_send_udp(vm5, 7452)
    end
    it "vm2 blocks incoming packages on udp" do
      expect(vm5).not_to be_able_to_send_udp(vm2, 7452)
    end
    it "vm2 blocks outgoing packages on udp" do
      expect(vm2).not_to be_able_to_send_udp(vm5, 7452)
    end
    it "vm3 accepts incoming packages on udp 10.101.0.13 port 1344" do
      expect(vm4).to be_able_to_send_udp(vm3, 1344)
    end
    it "vm3 blocks non filterd sources packages on udp" do
      expect(vm4).not_to be_able_to_send_udp(vm3, 1345)
      expect(vm1).not_to be_able_to_send_udp(vm3, 1344)
    end
    
  end

  describe "passthrough icmp" do
    it "vm1 accepts packages on icmp" do
      expect(vm6).to be_able_to_ping(vm1)
      expect(vm1).to be_able_to_ping(vm5)
    end
    it "vm2 blocks packages on icmp" do
      expect(vm6).not_to be_able_to_ping(vm2)
      expect(vm2).not_to be_able_to_ping(vm5)
    end
    it "vm3 accepts incoming packages on icmp from 10.101.0.10" do
      expect(vm1).to be_able_to_ping(vm3)
    end
    it "vm3 blocks incoming packages on icmp from othres" do
      expect(vm6).not_to be_able_to_ping(vm3)
      expect(vm5).not_to be_able_to_ping(vm3)
    end
  end

  describe "passthrough all" do
    before(:each) { vm4.udp_listen(7452) }
    after(:each) { vm4.udp_close(7452) }

    it "vm4 accepts on all protocol from vm1" do
      expect(vm4).to be_reachable_to(vm1)
      expect(vm1).to be_able_to_send_udp(vm4, 7452)
      expect(vm1).to be_able_to_ping(vm4)
    end
  end
end
