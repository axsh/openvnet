# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class DatapathGeneric < EventBase
    class << self
      private

      def create_with_transaction(options)
        if options[:ip_lease_id].nil?
          options = options.dup
          options[:ip_lease_id] = find_ip_lease_id(options[:interface_id])
        end

        internal_create(options)
      end

      def destroy_with_transaction(datapath_id: datapath_id, generic_id: generic_id)
        internal_destroy(model_class[datapath_id, generic_id])
      end

      def model_to_event_hash(model)
        model.to_hash.tap { |event_hash|
          prepare_event_hash(event_hash)
        }
      end

      def find_ip_lease_id(interface_id)
        return if interface_id.nil?

        ip_lease = model_class(:ip_lease).dataset.where(interface_id: interface_id).first
        ip_lease && ip_lease.id
      end

    end
  end

  class DatapathNetwork < DatapathGeneric
    class << self
      def associate_network(datapath_uuid, network_uuid, interface_uuid, broadcast_mac_address)
        transaction do
          datapath = Vnet::Models::Datapath[datapath_uuid]
          network = Vnet::Models::Network[network_uuid]
          interface = Vnet::Models::Interface[interface_uuid]
          if broadcast_mac_address.nil?
            broadcast_mac_address = generate_new_mac_address
          end

          dpn = Vnet::Models::DatapathNetwork.create({datapath_id: datapath.id,
                                                       interface_id: interface.id,
                                                       network_id: network.id,
                                                       broadcast_mac_address: broadcast_mac_address
                                                     })
          dispatch_created_for_model(dpn)
        end
      end

      private
      def generate_new_mac_address
        # TODO: replace with lease policy manager to ask new address.
        retry_count = 10
        begin
          new_addr = (Vnet::Configurations::Vnmgr.conf.datapath_broadcast_mac_vendor_address +
                      [Random.rand(0x7F),
                       Random.rand(0xFF),
                       Random.rand(0xFF)
                      ]).pack("C*")
          if Vnet::Models::MacAddress.filter(mac_address: new_addr).empty?
            return new_addr
          end
          retry_count -= 1
        end while retry_count > 0
        raise "Exceeds retry to generate MAC address for broadcast."
      end

      private

      def dispatch_created_item_events(model)
        dispatch_event(ADDED_DATAPATH_NETWORK, prepare_event_hash(model))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(REMOVED_DATAPATH_NETWORK, prepare_event_hash(model))
      end

      def destroy_filter(datapath_id, generic_id)
        { datapath_id: datapath_id, network_id: generic_id }
      end

      def prepare_event_hash(model)
        model.to_hash.tap { |event_hash|
          event_hash[:dpn_id] = event_hash[:id]
          event_hash[:id] = event_hash[:datapath_id]
        }
      end

    end
  end

  class DatapathRouteLink < DatapathGeneric
    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(ADDED_DATAPATH_ROUTE_LINK, prepare_event_hash(model))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(REMOVED_DATAPATH_ROUTE_LINK, prepare_event_hash(model))
      end

      def destroy_filter(datapath_id, generic_id)
        { datapath_id: datapath_id, route_link_id: generic_id }
      end

      def prepare_event_hash(model)
        model.to_hash.tap { |event_hash|
          event_hash[:dprl_id] = event_hash[:id]
          event_hash[:id] = event_hash[:datapath_id]
        }
      end

    end
  end

end
