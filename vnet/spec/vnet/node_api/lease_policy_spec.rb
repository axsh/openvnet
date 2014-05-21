require 'spec_helper'
require 'ipaddress'

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
        10.times {
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
        expect(IPAddress::IPv4.parse_u32(ipv4_address).to_s).to eq "10.102.0.101"
      end
    end

    context "when allocation_type is :decremental" do
      let(:ip_range_group) do
        Fabricate(:ip_range_group_with_range) { allocation_type "decremental" }
      end

      it "returns an ipv4 address by decremental order" do
        ipv4_address = Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group)
        expect(IPAddress::IPv4.parse_u32(ipv4_address).to_s).to eq "10.102.0.110"
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

    # network:
    #   ipv4_address: 10.102.0.100
    #   prefix 30
    #
    # ip_range:
    #   begin: 10.102.0.100
    #   end: 10.102.0.110
    #
    # result:
    #   begin: 10.102.0.101
    #   end: 10.102.0.102
    #
    context "when ip_range's range includes network's range" do
      let(:network) { Fabricate(:network_with_prefix_30) }
      let(:ip_range_group) do
        Fabricate(:ip_range_group_with_range) { allocation_type "incremental" }
      end

      it "returns the ip addresses within the network's subnet" do

        Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group).tap do |ipv4_address|
          expect(IPAddress::IPv4.parse_u32(ipv4_address).to_s).to eq "10.102.0.101"
          Vnet::Models::IpAddress.create(network: network, ipv4_address: ipv4_address)
        end

        Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group).tap do |ipv4_address|
          expect(IPAddress::IPv4.parse_u32(ipv4_address).to_s).to eq "10.102.0.102"
          Vnet::Models::IpAddress.create(network: network, ipv4_address: ipv4_address)
        end

        expect { Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group) }.to raise_error(/Run out of dynamic IP addresses/)
      end
    end

    # network:
    #   ipv4_address: 10.102.0.100
    #   prefix 30
    #   begin: 10.102.0.101
    #   end:   10.102.0.102
    #
    # ip_range:
    #   begin: 192.168.100.10
    #   end:   192.168.100.200
    #
    # result: raise error
    context "when ip_range's range doesn't match ip_range's range" do
      let(:network) { Fabricate(:network_with_prefix_30) }
      let(:ip_range_group) { Fabricate(:ip_range_group_with_range2) }

      it "raise Run out of dynamic IP addresses" do
        expect { Vnet::NodeApi::LeasePolicy.schedule(network, ip_range_group) }.to raise_error(/Run out of dynamic IP addresses/)
      end
    end
  end

  describe ".allocate_ip" do
    let(:lease_policy) { Fabricate(:lease_policy_with_network) }

    it "create ip_lease" do
      ip_lease = Vnet::NodeApi::LeasePolicy.allocate_ip(lease_policy_uuid: lease_policy.canonical_uuid)

      expect(IPAddress::IPv4.parse_u32(ip_lease.ipv4_address).to_s).to eq "10.102.0.101"
      expect(MockEventHandler.handled_events).to be_empty
    end

    context "with lease_time and grace_time" do
      let(:lease_policy) do
        Fabricate(:lease_policy_with_network) do
          lease_time 3600
          grace_time 1800
        end
      end

      it "creates an ip_lease with an ip_retention" do
        now = Time.now
        allow(Time).to receive(:now).and_return(now)

        ip_lease = Vnet::NodeApi::LeasePolicy.allocate_ip(lease_policy_uuid: lease_policy.canonical_uuid)

        expect(IPAddress::IPv4.parse_u32(ip_lease.ipv4_address).to_s).to eq "10.102.0.101"
        expect(ip_lease.lease_time_expired_at.to_i).to eq (now + lease_policy.lease_time).to_i

        events = MockEventHandler.handled_events
        expect(events.size).to eq 1

        expect(events[0][:event]).to eq Vnet::Event::IP_RETENTION_CREATED_ITEM
        expect(events[0][:options][:id]).to eq ip_lease.ip_retention.id
        expect(events[0][:options][:ip_lease_id]).to eq ip_lease.id
      end
    end

    context "with interface_uuid" do
      let(:interface) { Fabricate(:interface_w_mac_lease) }

      it "creates an ip_lease for an interface" do
        Vnet::NodeApi::LeasePolicy.allocate_ip(
          lease_policy_uuid: lease_policy.canonical_uuid,
          interface_uuid: interface.canonical_uuid
        )

        ip_lease = interface.ip_leases.first
        expect(IPAddress::IPv4.parse_u32(ip_lease.ipv4_address).to_s).to eq "10.102.0.101"

        events = MockEventHandler.handled_events
        expect(events.size).to eq 1

        expect(events[0][:event]).to eq Vnet::Event::INTERFACE_LEASED_IPV4_ADDRESS
        expect(events[0][:options][:id]).to eq interface.id
        expect(events[0][:options][:ip_lease_id]).to eq ip_lease.id
      end
    end

    context "with ip_lease_container_uuid" do
      let(:ip_lease_container) { Fabricate(:ip_lease_container) }

      it "creates an ip_lease and add it to an ip_lease_container" do
        ip_lease = Vnet::NodeApi::LeasePolicy.allocate_ip(
          lease_policy_uuid: lease_policy.canonical_uuid,
          ip_lease_container_uuid: ip_lease_container.canonical_uuid
        )

        expect(IPAddress::IPv4.parse_u32(ip_lease.ipv4_address).to_s).to eq "10.102.0.101"
        expect(ip_lease.ip_lease_containers.size).to eq 1
        expect(ip_lease.ip_lease_containers.first).to eq ip_lease_container

        expect(MockEventHandler.handled_events).to be_empty
      end
    end

    context "when lease_policy has ip_lease_containers" do
      let(:lease_policy) do
        Fabricate(:lease_policy_with_network) do
          ip_lease_containers(count: 2) do
            Fabricate(:ip_lease_container)
          end
        end
      end

      it "creates an ip_lease and add it to ip_lease_containers" do
        ip_lease = Vnet::NodeApi::LeasePolicy.allocate_ip(lease_policy_uuid: lease_policy.canonical_uuid)

        expect(IPAddress::IPv4.parse_u32(ip_lease.ipv4_address).to_s).to eq "10.102.0.101"
        expect(ip_lease.ip_lease_containers.size).to eq 2
        expect(ip_lease.ip_lease_containers).to eq lease_policy.ip_lease_containers

        expect(MockEventHandler.handled_events).to be_empty
      end
    end
  end
end
