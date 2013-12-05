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
        transaction do
          network_id = options.delete(:network_id)
          ipv4_address = options.delete(:ipv4_address)
          mac_address = options.delete(:mac_address)

          model_class[uuid].tap do |i|
            return unless i
            i.update(options)
            if mac_address
              mac_lease = i.mac_leases.first
              if mac_lease && mac_lease.mac_address != mac_address
                i.mac_leases.each(&:destroy)
                i.remove_all_mac_leases
              end
              i.add_mac_lease(mac_address: mac_address).tap do |mac_lease|
                if network_id && ipv4_address
                  i.add_ip_lease(mac_lease: mac_lease, network_id: network_id, ipv4_address: ipv4_address)
                end
              end
            end
          end
        end
      end

      def destroy(uuid)
        interface = super

        dispatch_event(REMOVED_INTERFACE, id: interface.id)

        nil
      end
    end
  end
end
