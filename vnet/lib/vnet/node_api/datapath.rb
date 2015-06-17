# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class Datapath < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(DATAPATH_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(DATAPATH_DELETED_ITEM, id: model.id, node_id: model.node_id)

        default_filter = { datapath_id: model.id }
        tunnel_filter = Sequel.|({ src_datapath_id: model.id },
                                 { dst_datapath_id: model.id })

        # 0001_origin
        ActiveInterface.dispatch_deleted_where(default_filter, model.deleted_at)
        # datapath_network: ignore, handled by main event
        # datapath_route_link: ignore, handled by main event
        InterfacePort.dispatch_deleted_where(default_filter, model.deleted_at)
        Tunnel.dispatch_deleted_where(tunnel_filter, model.deleted_at)
      end

      def associate_network(uuid, network_uuid, interface_uuid, broadcast_mac_address)
        transaction do
          datapath  = Vnet::Models::Datapath[uuid]
          network   = Vnet::Models::Network[network_uuid]
          interface = Vnet::Models::Interface[interface_uuid]

          if broadcast_mac_address.nil?
            broadcast_mac_address = generate_new_mac_address
          end

          Models::DatapathNetwork.create({datapath_id: datapath.id,
                                           interface_id: interface.id,
                                           network_id: network.id,
                                           broadcast_mac_address: broadcast_mac_address
                                         })
        end
      end

      private
      def generate_new_mac_address
        # TODO: replace with lease policy manager to ask new address.
        retry_count = 10
        begin
          new_addr = [0x00, 0x16, 0x3e,
                      Random.rand(0x7F),
                      Random.rand(0xFF),
                      Random.rand(0xFF)
                      ].pack("C*")
          if Models::MacAddress.filter(mac_address: new_addr).empty?
            return new_addr
          end
          retry_count -= 1
        end while retry_count > 0
      end
    end
  end
end
