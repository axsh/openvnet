# -*- coding: utf-8 -*-
module Vnet::NodeApi

  class Interface < EventBase
    class << self

      def create(options)
        options = options.dup

        datapath_id = options.delete(:owner_datapath_id)
        port_name = options.delete(:port_name)

        network_id = options.delete(:network_id)
        ipv4_address = options.delete(:ipv4_address)
        mac_address = options.delete(:mac_address)

        interface_port = nil

        transaction {
          interface = super || next
          interface_port = create_interface_port(interface, datapath_id, port_name)

          add_lease(interface, mac_address, network_id, ipv4_address)

          interface

        }.tap { |model|
          next if model.nil?
          # TODO: Create interface_port using InterfacePort.
          dispatch_event(INTERFACE_PORT_CREATED_ITEM, interface_port.to_hash) if interface_port
        }
      end

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

      def rename_uuid(old_uuid, new_uuid)
        old_trimmed = Interface.trim_uuid(old_uuid)
        new_trimmed = Interface.trim_uuid(new_uuid)

        update_count = model_class(:interface).with_deleted.where(uuid: old_trimmed).update(uuid: new_trimmed)

        # TODO: Send event if not deleted.
        # TODO: Error if count is not 1.

        (update_count == 1) ? new_uuid : ''
      end

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        # TODO: Send has not just id.
        dispatch_event(INTERFACE_CREATED_ITEM, id: model.id)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(INTERFACE_DELETED_ITEM, id: model.id)

        ActiveInterface.dispatch_deleted_where({ interface_id: model.id }, model.deleted_at)
        InterfacePort.dispatch_deleted_where({ interface_id: model.id }, model.deleted_at)
        MacLease.dispatch_deleted_where({ interface_id: model.id }, model.deleted_at)
        InterfaceSecurityGroup.dispatch_deleted_where({ interface_id: model.id }, model.deleted_at)
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

        interface_port = model_class(:interface_port).create(options)
      end

      def add_lease(interface, mac_address, network_id, ipv4_address)
        return if mac_address.nil?

        mac_lease = model_class(:mac_lease).create(mac_address: mac_address)
        return if mac_lease.nil?

        interface.add_mac_lease(mac_lease).tap do |mac_lease|
          next if mac_lease.nil?
          next if network_id.nil? || ipv4_address.nil?

          ip_lease = model_class(:ip_lease).create(mac_lease: mac_lease,
                                                   network_id: network_id,
                                                   ipv4_address: ipv4_address)
          interface.add_ip_lease(ip_lease)
        end
      end

    end
  end
end
