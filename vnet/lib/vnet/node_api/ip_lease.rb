# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class IpLease < Base
    class << self
      def create(options)
        options = options.dup
        ipv4_address = options.delete(:ipv4_address)
        ip_lease = transaction do
          model_class.new(options).tap do |model|
            model.ip_address = model_class(:ip_address).create(ipv4_address: ipv4_address)
          end.save
        end

        dispatch_event(LeasedIpv4Address, interface_id: ip_lease.interface_id, ip_lease_id: ip_lease.id, mac_address: ip_lease.interface.mac_address)
        to_hash(ip_lease)
      end

      def update(uuid, options)
        options = options.dup
        ipv4_address = options.delete(:ipv4_address)
        deleted_ip_address = nil

        ip_lease = transaction do
          model_class[uuid].tap do |model|
            if model.ip_address.ipv4_address != ipv4_address
              model.ip_address.destroy
              deleted_ip_address = model.ip_address
              model.ip_address = model_class(:ip_address).create(ipv4_address: ipv4_address)
            end
            model.set(options)
            model.save_changes
            model
          end
        end

        if deleted_ip_address
          dispatch_event(ReleasedIpv4Address, interface_id: ip_lease.interface_id, ip_lease_id: ip_lease.id, mac_address: ip_lease.interface.mac_address)
          dispatch_event(LeasedIpv4Address, interface_id: ip_lease.interface_id, ip_lease_id: ip_lease.id, mac_address: ip_lease.interface.mac_address)
          to_hash(ip_lease)
        end
      end

      def destroy(uuid)
        ip_lease = model_class[uuid].tap do |model|
          transaction do
            model.destroy
          end
        end

        dispatch_event(ReleasedIpv4Address, interface_id: ip_lease.interface_id, ip_lease_id: ip_lease.id, mac_address: ip_lease.interface.mac_address)
        to_hash(ip_lease)
      end
    end
  end
end
