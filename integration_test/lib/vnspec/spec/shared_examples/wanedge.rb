# -*- coding: utf-8 -*-

shared_examples 'wanedge examples' do |local_name, pending_local: false|

  describe "local vm7 in #{local_name}" do
    it 'reaches the gateway' do
      if pending_local
        pending('support for both local and remote flows requires a new filtering mode')
      end

      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:physical_network_gw_ip])

      expect(vm7).to be_able_to_ping(to_gw, 10)
    end

    it 'reaches the internet' do
      if pending_local
        pending('support for both local and remote flows requires a new filtering mode')
      end

      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:pseudo_global_ip])

      expect(vm7).to be_able_to_ping(to_gw, 10)
    end
  end

  describe "remote vm1 in #{local_name} using MAC2MAC" do
    it 'reaches the gateway' do
      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:physical_network_gw_ip])

      expect(vm1).to be_able_to_ping(to_gw, 10)
    end

    it 'reaches a global IP' do
      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:pseudo_global_ip])

      expect(vm1).to be_able_to_ping(to_gw, 10)
    end
  end

  describe "remote vm5 in #{local_name} using GRE" do
    it 'reaches the gateway' do
      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:physical_network_gw_ip])

      expect(vm5).to be_able_to_ping(to_gw, 10)
    end

    it 'reaches a global IP' do
      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:pseudo_global_ip])

      expect(vm5).to be_able_to_ping(to_gw, 10)
    end
  end

  describe "vm7 in #{local_name}" do
    it 'reaches vm1 on node1 using MAC2MAC' do
      expect(vm7).to be_reachable_to(vm1)
    end

    it 'reaches vm5 on node3 using GRE' do
      expect(vm7).to be_reachable_to(vm5)
    end
  end

end
