# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Interface < Base
    class << self
      def create(options)
        options = options.dup
        interface = transaction do
          network_uuid = options.delete(:network_uuid)
          ipv4_address = options.delete(:ipv4_address)
          mac_address = options.delete(:mac_address)
          model_class.create(options).tap do |i|
            if network_uuid && ipv4_address
              i.add_ip_lease(model_class("IpLease").create(
                :network_uuid => network_uuid,
                :ipv4_address => ipv4_address
              ))
            end
            if mac_address
              i.add_mac_lease(model_class("MacLease").create(:mac_address => mac_address))
            end
          end
        end

        if interface.ip_leases.present?
          interface.ip_leases.each do |ip_lease|
            dispatch_event("network/interface_added", network_id: ip_lease.ip_address.network_id, interface_id: interface.id)
          end
        end

        interface
      end

      def update(uuid, options)
        options = options.dup
        transaction do
          network_uuid = options.delete(:network_uuid)
          ipv4_address = options.delete(:ipv4_address)
          mac_address = options.delete(:mac_address)

          model_class[uuid].tap do |i|
            i.update(options)
            if network_uuid && ipv4_address
              ip_lease = i.ip_leases.first
              if ip_lease && (ip_lease.network_uuid != network_uuid || ip_lease.ipv4_address != ipv4_address)
                i.ip_leases.each(&:destroy)
                i.remove_all_ip_leases
              end
              i.add_ip_lease(network_uuid: network_uuid, ipv4_address: ipv4_address)
            end
            if mac_address
              mac_lease = i.mac_leases.first
              if mac_lease && mac_lease.mac_address != mac_address
                i.mac_leases.each(&:destroy)
                i.remove_all_mac_leases
              end
              i.add_mac_lease(mac_address: mac_address)
            end
          end
        end
      end

      def destroy(uuid)
        # TODO implement me
      end
    end
  end
end
