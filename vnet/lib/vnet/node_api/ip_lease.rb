# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class IpLease < Base
    class << self
      include Vnet::Helpers::Event

      def create(options)
        options = options.dup
        ip_lease = transaction do
          model_class.create(options)
        end

        dispatch_event(INTERFACE_LEASED_IPV4_ADDRESS, id: ip_lease.interface_id, ip_lease_id: ip_lease.id)

        ip_lease.interface.security_groups.each do |group|
          dispatch_update_sg_ip_addresses(group)
        end

        ip_lease
      end

      def update(uuid, options)
        options = options.dup
        ipv4_address = options.delete(:ipv4_address)
        deleted_ip_address = nil

        ip_lease = transaction do
          model_class[uuid].tap do |model|
            if model.ip_address.ipv4_address != ipv4_address && ipv4_address
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
          dispatch_event(INTERFACE_RELEASED_IPV4_ADDRESS, id: ip_lease.interface_id, ip_lease_id: ip_lease.id)
          dispatch_event(INTERFACE_LEASED_IPV4_ADDRESS, id: ip_lease.interface_id, ip_lease_id: ip_lease.id)
        end

        ip_lease.interface.security_groups.each do |group|
          dispatch_update_sg_ip_addresses(group)
        end

        ip_lease
      end

      def destroy(uuid)
        ip_lease = model_class[uuid].tap do |model|
          transaction do
            model.destroy
          end
        end

        ip_lease.interface.security_groups.each do |group|
          dispatch_update_sg_ip_addresses(group)
        end

        dispatch_event(INTERFACE_RELEASED_IPV4_ADDRESS, id: ip_lease.interface_id, ip_lease_id: ip_lease.id)

        ip_lease
      end
    end
  end
end
