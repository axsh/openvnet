# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Interface < Base
    class << self
      def create(options)
        options = options.dup
        interface = transaction do
          network_id = options.delete(:network_id)
          ipv4_address = options.delete(:ipv4_address)
          mac_address = options.delete(:mac_address)
          model_class.create(options).tap do |i|
            if mac_address
              i.add_mac_lease(model_class(:mac_lease).create(:mac_address => mac_address)).tap do |mac_lease|
                if network_id && ipv4_address
                  i.add_ip_lease(model_class(:ip_lease).create(
                    mac_lease: mac_lease,
                    network_id: network_id,
                    ipv4_address: ipv4_address
                  ))
                end
              end
            end
          end
        end

        dispatch_event(
          ADDED_INTERFACE,
          id: interface.id,
          port_name: interface.port_name
        )

        interface
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
          dispatch_event(UPDATED_INTERFACE,
                         event: :updated,
                         id: interface.id,
                         port_name: interface.port_name,
                         changed_columns: options)
        end
      end

      def update_active_datapath(uuid, datapath_id)
        transaction do
          model_class[uuid].tap do |i|
            return unless i
            i.active_datapath_id = datapath_id
            i.save_changes
          end
        end
      end

      def destroy(uuid)
        interface = super

        dispatch_event(REMOVED_INTERFACE, id: interface.id)

        model_class(:mac_lease).with_deleted.where(interface_id: interface.id).each do |mac_lease|
          dispatch_event(RELEASED_MAC_ADDRESS, id: interface.id,
                                               mac_lease_id: mac_lease.id)
        end

        nil
      end
    end
  end
end
