# -*- coding: utf-8 -*-

require 'spec_helper'

include Vnet::Constants::Openflow

describe Vnet::Core::ServiceManager do

  use_mock_event_handler

  let(:datapath) { create_mock_datapath }

  let(:service_manager) do
    datapath.dp_info.service_manager
  end

  let(:interface_manager) do
    datapath.dp_info.interface_manager
  end

  describe "dns" do
    let!(:network_service) do
      interface = Fabricate(:interface, mode: "simulated")
      mac_lease = Fabricate(:mac_lease_any) do
        interface { interface }
        mac_address 1
      end
      ip_lease = Fabricate(:ip_lease_any) do
        mac_lease { mac_lease }
        ip_address do
          Fabricate(:ip_address) do
            ipv4_address IPAddr.new("192.168.1.3").to_i
            network do
              Fabricate(:network) do
                network_mode 'virtual'
              end
            end
          end
        end
      end

      Fabricate(:network_service_dns, interface: interface)
    end

    let!(:dns_service) do
      Fabricate(
        :dns_service,
        network_service: network_service,
        dns_records: [ Fabricate(:dns_record) ]
      )
    end

    describe "when ADDED_SERVICE is published" do
      it "should create a network service with a dns service" do
        interface_manager.load_shared_interface(1)
        expect(interface_manager.wait_for_loaded({id: 1}, 3)).not_to be_nil

        service_manager.publish(Vnet::Event::SERVICE_CREATED_ITEM,
                                id: 1,
                                interface_id: 1,
                                type: 'dns')
        expect(service_manager.wait_for_loaded({id: 1}, 3)).not_to be_nil

        service_manager.send(:internal_detect, id: network_service.id).tap do |item|
          expect(item.dns_service[:public_dns]).to eq "8.8.8.8,8.8.4.4"
          expect(item.records["foo."].first[:ipv4_address]).to eq IPAddr.new("192.168.1.10")
          expect(item.dns_server_for(1)).to eq IPAddr.new("192.168.1.3").to_s
        end

        expect(datapath.added_flows).to be_any { |flow|
          flow.params[:table_id] == TABLE_OUT_PORT_INTERFACE_INGRESS
          flow.params[:priority] == 30
          flow.params[:match][:eth_type] == 0x0800
          flow.params[:match][:ip_proto] == 0x11
          flow.params[:match][:udp_dst] == 53
        }

        expect(datapath.added_flows).to be_any { |flow|
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
        interface_manager.load_shared_interface(1)
        expect(interface_manager.wait_for_loaded({id: 1}, 3)).not_to be_nil

        service_manager.publish(Vnet::Event::SERVICE_CREATED_ITEM,
                                id: 1,
                                interface_id: 1,
                                type: 'dns')
        expect(service_manager.wait_for_loaded({id: network_service.id}, 3)).not_to be_nil

        network_service.destroy
        service_manager.publish(Vnet::Event::SERVICE_DELETED_ITEM, id: network_service.id)
        expect(service_manager.wait_for_unloaded({id: network_service.id}, 3)).not_to be_nil

        expect(service_manager.retrieve(id: network_service.id)).to be_nil

        expect(datapath.deleted_flows).to be_any { |flow|
          flow.params[:table_id] == TABLE_OUT_PORT_INTERFACE_INGRESS
          flow.params[:priority] == 30
          flow.params[:match][:eth_type] == 0x0800
          flow.params[:match][:ip_proto] == 0x11
          flow.params[:match][:udp_dst] == 53
        }

        expect(datapath.deleted_flows).to be_any { |flow|
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
