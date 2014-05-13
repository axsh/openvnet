# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class IpLease < Base
    class << self
      include Vnet::Helpers::Event

      def create(options)
        options = options.dup
        lease_time = options.delete(:lease_time)
        grace_time = options.delete(:grace_time)
        ip_lease = transaction do
          model_class.create(options).tap do |il|
            if lease_time
              il.ip_retention = model_class(:ip_retention).create(
                ip_lease_id: il.id,
                ip_address_id: il.ip_address_id,
                lease_time_expired_at: Time.now + lease_time,
                grace_time: grace_time
              )
            end
          end
        end

        dispatch_event(INTERFACE_LEASED_IPV4_ADDRESS, id: ip_lease.interface_id, ip_lease_id: ip_lease.id)

        if lease_time
          dispatch_event(IP_RETENTION_CREATED_ITEM, id: ip_lease.ip_retention.id, ip_lease_id: ip_lease.id, lease_time_expired_at: ip_lease.ip_retention.lease_time_expired_at, grace_time: grace_time)
        end

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
        ip_lease = model_class[uuid]
        ip_retention = ip_lease.ip_retention

        transaction do
          ip_lease.destroy
          ip_retention.expire if ip_retention
        end

        ip_lease.interface.security_groups.each do |group|
          dispatch_update_sg_ip_addresses(group)
        end

        if ip_retention
          dispatch_event(IP_RETENTION_EXPIRED_ITEM, id: ip_retention.id, grace_time_expired_at: ip_retention.grace_time_expired_at)
        end

        dispatch_event(INTERFACE_RELEASED_IPV4_ADDRESS, id: ip_lease.interface_id, ip_lease_id: ip_lease.id)

        ip_lease
      end
    end
  end
end
