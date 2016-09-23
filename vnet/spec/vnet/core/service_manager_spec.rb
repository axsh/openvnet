# -*- coding: utf-8 -*-

require 'spec_helper'

include Vnet::Constants::Openflow

describe Vnet::Core::ServiceManager do
  # before(:each) { use_mock_event_handler }

  # let(:events) { MockEventHandler.handled_events }

  let(:datapath) { create_mock_datapath }
  let(:dp_info) { datapath.dp_info }

  let(:network) { Fabricate(:network, network_mode: 'virtual') }

  let(:service_interface) {
    Fabricate(:interface, mode: "simulated")
  }
  let(:service_ip_lease) {
    Fabricate(:ip_lease_any,
      interface: service_interface,
      mac_lease: Fabricate(:mac_lease_any,
        interface: service_interface,
        mac_address: random_mac_i),
      ip_address: Fabricate(:ip_address,
        ipv4_address: IPAddr.new("192.168.1.3").to_i,
        network: network))
  }

  let(:service_manager) { datapath.dp_info.service_manager }
  let(:interface_manager) { datapath.dp_info.interface_manager }

  describe "dns" do
    let(:network_service) {
      Fabricate(:network_service_dns, interface: service_interface)
    }
    let(:dns_service) {
      Fabricate(:dns_service,
        network_service: network_service,
        dns_records: [ Fabricate(:dns_record) ])
    }

    describe "when ADDED_SERVICE is published" do
      it "should create a network service with a dns service" do
        service_ip_lease

        interface_manager.load_shared_interface(service_interface.id)

        # TODO: Add helper methods for loading.
        expect(interface_manager.wait_for_loaded({id: service_interface.id}, 3)).not_to be_nil
        expect(service_manager.wait_for_loaded({id: dns_service.network_service_id}, 3)).not_to be_nil

        service_manager.send(:internal_detect, id: network_service.id).tap do |item|
          expect(item.dns_service[:public_dns]).to eq "8.8.8.8,8.8.4.4"
          expect(item.records["foo."].first[:ipv4_address]).to eq IPAddr.new("192.168.1.10")
          expect(item.dns_server_for(network.id)).to eq IPAddr.new("192.168.1.3").to_s
        end

        expect(dp_info.added_flows).to be_any { |flow|
          flow.params[:table_id] == TABLE_OUT_PORT_INTERFACE_INGRESS
          flow.params[:priority] == 30
          flow.params[:match][:eth_type] == 0x0800
          flow.params[:match][:ip_proto] == 0x11
          flow.params[:match][:udp_dst] == 53
        }

        expect(dp_info.added_flows).to be_any { |flow|
          flow.params[:table_id] == TABLE_FLOOD_SIMULATED
          flow.params[:priority] == 30
          flow.params[:match][:eth_type] == 0x0800
          flow.params[:match][:ip_proto] == 0x11
          flow.params[:match][:udp_dst] == 53
        }
      end
    end

    describe "when REMOVED_SERVICE is published" do
      it "should remove a network service" do
        service_ip_lease

        interface_manager.load_shared_interface(service_interface.id)

        expect(interface_manager.wait_for_loaded({id: service_interface.id}, 3)).not_to be_nil
        expect(service_manager.wait_for_loaded({id: dns_service.network_service_id}, 3)).not_to be_nil

        network_service.destroy
        service_manager.publish(Vnet::Event::SERVICE_DELETED_ITEM, id: network_service.id)

        expect(service_manager.wait_for_unloaded({id: dns_service.network_service_id}, 3)).not_to be_nil
        expect(service_manager.retrieve(id: network_service.id)).to be_nil

        expect(dp_info.deleted_flows).to be_any { |flow|
          flow.params[:table_id] == TABLE_OUT_PORT_INTERFACE_INGRESS
          flow.params[:priority] == 30
          flow.params[:match][:eth_type] == 0x0800
          flow.params[:match][:ip_proto] == 0x11
          flow.params[:match][:udp_dst] == 53
        }

        expect(dp_info.deleted_flows).to be_any { |flow|
          flow.params[:table_id] == TABLE_FLOOD_SIMULATED
          flow.params[:priority] == 30
          flow.params[:match][:eth_type] == 0x0800
          flow.params[:match][:ip_proto] == 0x11
          flow.params[:match][:udp_dst] == 53
        }
      end
    end
  end
end
