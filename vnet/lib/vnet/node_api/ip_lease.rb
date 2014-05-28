# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class IpLease < Base
    class << self
      include Vnet::Helpers::Event

      def create(options)
        options = options.dup
        ip_lease = transaction { model_class.create(options) }

        if ip_lease.interface
          dispatch_event(INTERFACE_LEASED_IPV4_ADDRESS, id: ip_lease.interface_id, ip_lease_id: ip_lease.id)

          ip_lease.interface.security_groups.each do |group|
            dispatch_update_sg_ip_addresses(group)
          end
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
        ip_lease = model_class[uuid]
        ip_retention = ip_lease.ip_retention

        transaction do
          ip_lease.destroy
        end

        ip_lease.interface.security_groups.each do |group|
          dispatch_update_sg_ip_addresses(group)
        end

        if ip_retention
          dispatch_event(IP_RETENTION_CONTAINER_DELETED_IP_RETENTION, id: ip_retention.id)
        end

        dispatch_event(INTERFACE_RELEASED_IPV4_ADDRESS, id: ip_lease.interface_id, ip_lease_id: ip_lease.id)

        ip_lease
      end

      def expire(uuid)
        ip_lease = model_class[uuid]
        interface = ip_lease.interface

        ip_lease.interface_id = nil
        ip_lease.mac_lease_id = nil
        transaction do
          ip_lease.save_changes
        end

        interface.security_groups.each do |group|
          dispatch_update_sg_ip_addresses(group)
        end

        dispatch_event(INTERFACE_RELEASED_IPV4_ADDRESS, id: interface.id, ip_lease_id: ip_lease.id)

        ip_lease
      end
    end
  end
end
