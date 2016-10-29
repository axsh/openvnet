# -*- coding: utf-8 -*-

shared_examples 'wanedge examples' do |local_name|

  describe "local vm7 in #{local_name}" do
    it 'reaches the gateway' do
      pending('support for both local and remote flows requires a new filtering mode')

      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:physical_network_gw_ip])

      expect(vm7).to be_able_to_ping(to_gw, 10)
    end

    it 'reaches the internet' do
      pending('support for both local and remote flows requires a new filtering mode')

      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:pseudo_global_ip])

      expect(vm7).to be_able_to_ping(to_gw, 10)
    end
  end

  describe "remote vm1 in #{local_name}" do
    it 'reaches the gateway' do
      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:physical_network_gw_ip])

      expect(vm1).to be_able_to_ping(to_gw, 10)
    end

    it 'reaches the internet' do
      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:pseudo_global_ip])

      expect(vm1).to be_able_to_ping(to_gw, 10)
    end
  end

  describe "vm1 and vm7 in #{local_name}" do
    context 'vm1 on node1' do
      it 'reachable to vm7 on promiscuous node' do
        expect(vm1).to be_reachable_to(vm7)
      end
    end
  end

end
