require 'spec_helper'
require 'ipaddr'

describe Vnet::NodeApi::LeasePolicy do
  before do
    use_mock_event_handler
  end

  describe ".schedule" do
    let(:network) { Fabricate(:network_for_range) }

    context "when running out of ip addresses" do
      let(:ip_range_group) do
        Fabricate(:ip_range_group_with_range) { allocation_type "incremental" }
      end

      before do
        3.times { 
          ipv4_address = Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group)
          Vnet::Models::IpAddress.create(network: network, ipv4_address: ipv4_address)
        }
      end

      it "raise 'Run out of dynamic IP addresses' error" do
        expect { Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group) }.to raise_error(/Run out of dynamic IP addresses/)
      end
    end

    context "when allocation_type is :incremental" do
      let(:ip_range_group) do
        Fabricate(:ip_range_group_with_range) { allocation_type "incremental" }
      end

      it "returns an ipv4 address by incremental order" do
        ipv4_address = Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group)
        expect(IPAddr.new(ipv4_address, Socket::AF_INET).to_s).to eq "10.102.0.100"
      end
    end

    context "when allocation_type is :decremental" do
      let(:ip_range_group) do
        Fabricate(:ip_range_group_with_range) { allocation_type "decremental" }
      end

      it "returns an ipv4 address by decremental order" do
        ipv4_address = Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group)
        expect(IPAddr.new(ipv4_address, Socket::AF_INET).to_s).to eq "10.102.0.102"
      end
    end

    context "when allocation_type is :random" do
      let(:ip_range_group) do
        Fabricate(:ip_range_group_with_range) { allocation_type "random" }
      end

      it "raise NotImplementedError" do
        expect { Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe ".allocate_ip" do
    let(:lease_policy) { Fabricate(:lease_policy_with_network) }
    let(:interface) { Fabricate(:interface_w_mac_lease) }

    it "allocate new ip to an interface" do
      Vnet::NodeApi::LeasePolicy.allocate_ip(
        lease_policy_id: lease_policy.id,
        interface_id: interface.id
      )

      ip_lease = interface.ip_leases.first
      expect(IPAddr.new(ip_lease.ipv4_address, Socket::AF_INET).to_s).to eq "10.102.0.100"

      event = MockEventHandler.handled_events.first
      expect(event[:event]).to eq Vnet::Event::INTERFACE_LEASED_IPV4_ADDRESS
      expect(event[:options][:id]).to eq interface.id
      expect(event[:options][:ip_lease_id]).to eq ip_lease.id
    end
  end
end
