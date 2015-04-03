# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Interface < EventBase
    class << self
      # TODO dispatch_event
      def update(uuid, options)
        options = options.dup

        transaction {
          model_class[uuid].tap do |i|
            return unless i
            i.update(options)
          end
        }.tap do |interface|
          dispatch_event(INTERFACE_UPDATED,
                         event: :updated,
                         id: interface.id,
                         changed_columns: options)


          # TODO: Checking for 'true' or 'false' is insufficient.
          case options[:ingress_filtering_enabled]
          when "true"
            dispatch_event(INTERFACE_ENABLED_FILTERING, id: interface.id)
          when "false"
            dispatch_event(INTERFACE_DISABLED_FILTERING, id: interface.id)
          end

        end
      end

      # TODO: Move to base.
      def rename(old_uuid, new_uuid)
        old_trimmed = model_class.trim_uuid(old_uuid)
        new_trimmed = model_class.trim_uuid(new_uuid)

        # TODO: Make error:
        return '' if old_trimmed.nil? || new_trimmed.nil?

        update_count = model_class.with_deleted.where(uuid: old_trimmed).update(uuid: new_trimmed)

        # TODO: Send event if not deleted.
        # TODO: Error if count is not 1.

        (update_count == 1) ? new_uuid : ''
      end

      #
      # Internal methods:
      #

      private

      def create_with_transaction(options)
        options = options.dup

        datapath_id = options.delete(:owner_datapath_id)
        port_name = options.delete(:port_name)

        network_id = options.delete(:network_id)
        ipv4_address = options.delete(:ipv4_address)
        mac_address = options.delete(:mac_address)

        # TODO: Raise rollback if any step fails.
        transaction {
          model = internal_create(options) || next
          create_interface_port(model, datapath_id, port_name)

          add_lease(model, mac_address, network_id, ipv4_address)

          model
        }
      end

      def dispatch_created_item_events(model)
        # TODO: Send has not just id.
        dispatch_event(INTERFACE_CREATED_ITEM, id: model.id)

        filter = { interface_id: model.id }

        # 0001_origin
        InterfacePort.dispatch_created_where(filter, model.created_at)
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
        SecurityGroupInterface.dispatch_deleted_where(filter, model.deleted_at)
        # src_tunnels: :destroy,
        # dst_tunnels: :destroy,
        Translation.dispatch_deleted_where(filter, model.deleted_at)
        # 0002_services
        # lease_policy_base_interfaces: :destroy,
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

        model_class(:interface_port).create(options)
      end

      def add_lease(interface, mac_address, network_id, ipv4_address)
        return true if mac_address.nil?

        mac_lease = model_class(:mac_lease).create(mac_address: mac_address) || return
        interface.add_mac_lease(mac_lease) || return

        return true if network_id.nil? || ipv4_address.nil?

        ip_lease = model_class(:ip_lease).create(mac_lease: mac_lease,
                                                 network_id: network_id,
                                                 ipv4_address: ipv4_address) || return
        interface.add_ip_lease(ip_lease) || return

        return true
      end

    end
  end
end
