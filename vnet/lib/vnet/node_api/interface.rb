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

        # TODO dispatch_event
        #if interface.ip_leases.present?
        #  interface.ip_leases.each do |ip_lease|
        #    dispatch_event(LeasedIpv4Address, target_id: ip_lease.interface_id, ip_lease_id: ip_lease.id)
        #  end
        #end

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
        super
        # TODO dispatch_event
      end
    end
  end
end
