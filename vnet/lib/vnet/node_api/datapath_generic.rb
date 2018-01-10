# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class DatapathGeneric < EventBase
    class << self
      private

      def create_with_transaction(options)
        options = options.dup
        each_active_filter = options.delete(:each_active_filter)

        transaction {
          if each_active_filter.nil?
            create_single(options)
          else
            # TODO: Add a separate method for this.
            r = nil
            active_dataset.where(each_active_filter).each { |active|
              model = create_single(options.merge!(datapath_id: active.datapath_id))
              r = model if model
            }
            r
          end
        }
      end

      def create_single(options)
        options = options.dup
        lease_detection = options.delete(:lease_detection)

        if lease_detection
          lease_detection.merge!(datapath_id: options[:datapath_id])
          options[:interface_id], options[:ip_lease_id] = detect_ip_lease(lease_detection)

          return if options[:interface_id].nil? || options[:ip_lease_id].nil?

        elsif options[:ip_lease_id].nil?
          options[:ip_lease_id] = find_ip_lease_id(options[:interface_id])
        end

        mac_address_random_assign(options)
        internal_create(options)
      end

      def destroy_with_transaction(datapath_id: datapath_id, generic_id: generic_id)
        internal_destroy(model_class[destroy_filter(datapath_id, generic_id)])
      end

      def model_to_event_hash(model)
        model.to_hash.tap { |event_hash|
          prepare_event_hash(event_hash)
        }
      end

      def find_ip_lease_id(interface_id)
        return if interface_id.nil?

        ip_lease = M::IpLease.dataset.where(interface_id: interface_id).first
        ip_lease && ip_lease.id
      end

      def detect_ip_lease(params)
        datapath_id = params[:datapath_id] || return
        network_id = params[:network_id]
        interface_id = params[:interface_id]
        topology_id = params[:topology_id]

        ds = M::IpLease.dataset

        case
        when network_id && interface_id.nil? && topology_id.nil?
          ds = ds.where_datapath_id_and_interface_mode(datapath_id, Vnet::Constants::Interface::MODE_HOST)
          ds.each { |ip_lease|
            next if ip_lease.network_id != network_id

            return ip_lease.interface_id, ip_lease.id
          }

        when network_id.nil? && interface_id && topology_id.nil?
          ds = ds.where(ip_leases__interface_id: interface_id)
          ds = ds.where_datapath_id_and_interface_mode(datapath_id, Vnet::Constants::Interface::MODE_HOST)
          
          lease = ds.first

          return interface_id, (lease && lease.id)

        when interface_id.nil? && topology_id
          ds = ds.where_topology_id(topology_id)
          ds = ds.where_datapath_id_and_interface_mode(datapath_id, Vnet::Constants::Interface::MODE_HOST)
          ds.each { |ip_lease|
            next if network_id && ip_lease.network_id != network_id

            return ip_lease.interface_id, ip_lease.id
          }

        end

        return nil
      end

    end
  end

  class DatapathNetwork < DatapathGeneric
    class << self
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

      def active_dataset
        M::ActiveNetwork.dataset
      end

    end
  end

  class DatapathSegment < DatapathGeneric
    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(ADDED_DATAPATH_SEGMENT, prepare_event_hash(model))
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(REMOVED_DATAPATH_SEGMENT, prepare_event_hash(model))
      end

      def destroy_filter(datapath_id, generic_id)
        { datapath_id: datapath_id, segment_id: generic_id }
      end

      def prepare_event_hash(model)
        model.to_hash.tap { |event_hash|
          event_hash[:dpseg_id] = event_hash[:id]
          event_hash[:id] = event_hash[:datapath_id]
        }
      end

      def active_dataset
        M::ActiveSegment.dataset
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

      def active_dataset
        M::ActiveRouteLink.dataset
      end

    end
  end

end
