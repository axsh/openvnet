# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Interface < EventBase
    valid_update_fields [:display_name]

    class << self

      private

      def create_with_transaction(options)
        options = options.dup

        datapath_id = options.delete(:owner_datapath_id)
        port_name = options.delete(:port_name)

        segment_id = options.delete(:segment_id)

        network_id = options.delete(:network_id)
        ipv4_address = options.delete(:ipv4_address)

        mac_address = options.delete(:mac_address)
        mac_range_group_id = options.delete(:mac_range_group_id)

        # TODO: Raise rollback if any step fails.
        transaction {
          handle_new_uuid(options)

          internal_create(options).tap { |model|
            next if model.nil?

            create_interface_port(model, datapath_id, port_name)

            mac_lease = add_mac_lease(model, mac_address, mac_range_group_id, segment_id)
            ip_lease = add_ip_lease(model, mac_lease, network_id, ipv4_address)

            InterfaceSegment.update_assoc(model.id, mac_lease.segment_id) if mac_lease
            InterfaceNetwork.update_assoc(model.id, ip_lease.network_id) if ip_lease
          }
        }
      end

      def dispatch_created_item_events(model)
        # TODO: Send has not just id.
        dispatch_event(INTERFACE_CREATED_ITEM, id: model.id)

        filter = { interface_id: model.id }

        # 0001_origin
        InterfacePort.dispatch_created_where(filter, model.created_at)

        # 0011_assoc_interface
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(INTERFACE_DELETED_ITEM, id: model.id)

        filter = { interface_id: model.id }

        # 0001_origin
        ActiveInterface.dispatch_deleted_where(filter, model.deleted_at)
        # datapath_networks: :destroy,
        # datapath_route_links: :destroy,
        InterfacePort.dispatch_deleted_where(filter, model.deleted_at)
        # ip_leases: verify
        MacLease.dispatch_deleted_where(filter, model.deleted_at)
        # network_services: add
        # routes: add
        # src_tunnels: :destroy,
        # dst_tunnels: :destroy,
        Translation.dispatch_deleted_where(filter, model.deleted_at)
        # 0002_services
        # lease_policy_base_interfaces: :destroy,
        # 0009_topologies
        TopologyDatapath.dispatch_deleted_where(filter, model.deleted_at)
        # 0011_assoc_interface
        # TODO: Make the assoc managers subscribe to INTERFACE_DELETED_ITEM(?).
        InterfaceNetwork.dispatch_deleted_where(filter, model.deleted_at)
        InterfaceSegment.dispatch_deleted_where(filter, model.deleted_at)
        InterfaceRouteLink.dispatch_deleted_where(filter, model.deleted_at)
      end

      def dispatch_updated_item_events(model, old_values)
        # dispatch_event(INTERFACE_UPDATED, get_changed_hash(model, old_values.keys))

        dispatch_event(INTERFACE_UPDATED,
                       event: :updated,
                       id: model.id,
                       changed_columns: get_changed_hash(model, old_values.keys))


        if old_values.has_key?(:enable_filtering)
          case model[:enable_filtering]
          when true
            dispatch_event(INTERFACE_ENABLED_FILTERING2, id: model.id)
          when false
            dispatch_event(INTERFACE_DISABLED_FILTERING2, id: model.id)
          end
        end
      end

      def create_interface_port(interface, datapath_id, port_name)
        singular = (datapath_id || port_name) ? true : nil

        options = {
          interface_id: interface.id,
          interface_mode: interface.mode,
          datapath_id: datapath_id,

          port_name: port_name,
          singular: singular
        }

        M::InterfacePort.create(options)
      end

      def add_ip_lease(interface, mac_lease, network_id, ipv4_address)
        return if network_id.nil? || ipv4_address.nil?

        ip_lease = M::IpLease.create(mac_lease: mac_lease,
                                     network_id: network_id,
                                     ipv4_address: ipv4_address) || return
        interface.add_ip_lease(ip_lease) || return

        ip_lease
      end

      def add_mac_lease(model, mac_address, mac_range_group_id, segment_id)
        if mac_address
          mac_lease = M::MacLease.create(interface_id: model.id,
                                         segment_id: segment_id,
                                         mac_address: mac_address)
          return mac_lease
        end

        return if mac_range_group_id.nil?

        mac_range_group = M::MacRangeGroup[id: mac_range_group_id] || return
        mac_range_group.lease_random(model.id)
      end

    end
  end
end
