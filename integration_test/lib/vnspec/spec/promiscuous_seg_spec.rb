# -*- coding: utf-8 -*-

require_relative "spec_helper"

describe "promiscuous_seg", :vms_enable_vm => [:vm1, :vm7], :vms_disable_dhcp => true do
  before(:all) do
    vm1.change_ipv4_address('10.210.0.10')
    vm7.change_ipv4_address('10.210.0.17')

    vm1.route_default_via(config[:physical_network_gw_ip])
    vm7.route_default_via(config[:physical_network_gw_ip])
  end

  describe 'local vm7 in seg-global' do
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

  describe "remote vm1 in seg-global" do
    it "reaches the gateway" do
      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:physical_network_gw_ip])

      expect(vm1).to be_able_to_ping(to_gw, 10)
    end

    it "reaches the internet" do
      to_gw = double()
      allow(to_gw).to receive(:ipv4_address).and_return(config[:pseudo_global_ip])

      expect(vm1).to be_able_to_ping(to_gw, 10)
    end
  end

  describe 'vm1 and vm7 in seg-global' do
    context "vm1 on node1" do
      it "reachable to vm7 on promiscuous node" do
        expect(vm1).to be_reachable_to(vm7)
      end
    end
  end

end
