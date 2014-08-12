# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class IpLease < EventBase
    class << self
      include Vnet::Helpers::Event

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
          dispatch_created_item_events(ip_lease)
        end

        ip_lease.interface.security_groups.each do |group|
          dispatch_update_sg_ip_addresses(group)
        end

        ip_lease
      end

      def release(uuid)
        ip_lease = model_class[uuid]
        interface = ip_lease.interface

        ip_lease.interface_id = nil
        ip_lease.mac_lease_id = nil
        transaction do
          ip_lease.save_changes
          current_time = Time.now
          ip_lease.ip_retentions.each do |ip_retention|
            ip_retention.released_at = current_time
            ip_retention.save_changes
          end
        end

        if interface
          interface.security_groups.each do |group|
            dispatch_update_sg_ip_addresses(group)
          end
        end

        dispatch_event(INTERFACE_RELEASED_IPV4_ADDRESS, id: interface.id, ip_lease_id: ip_lease.id)
        # re-add released ip_retentions
        ip_lease.ip_retentions.each do |ip_retention|
          dispatch_event(
            IP_RETENTION_CONTAINER_ADDED_IP_RETENTION,
            id: ip_retention.ip_retention_container_id,
            ip_retention_id: ip_retention.id,
            ip_lease_id: ip_retention.ip_lease_id,
            leased_at: ip_retention.leased_at,
            released_at: ip_retention.released_at
          )
        end

        ip_lease
      end

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        if model.interface_id
          dispatch_event(INTERFACE_LEASED_IPV4_ADDRESS, prepare_event_hash(model))
        end

        dispatch_security_group_item_events(model)
      end

      def dispatch_deleted_item_events(model)
        if model.interface_id
          dispatch_event(INTERFACE_RELEASED_IPV4_ADDRESS, id: model.interface_id, ip_lease_id: model.id)
        end

        filter = { ip_lease_id: model.id }

        # 0001_origin
        # datapath_networks: :destroy,
        # datapath_route_links: :destroy,
        # ip_address: :destroy,
        # ip_lease_container_ip_leases: :destroy,

        dispatch_security_group_item_events(model)

        # 0002_services
        IpRetention.dispatch_deleted_where(filter, model.deleted_at)
      end

      def dispatch_security_group_item_events(model)
        model.interface.tap { |interface|
          next if interface.nil?

          interface.security_groups.each { |group|
            dispatch_update_sg_ip_addresses(group)
          }
        }
      end

      def prepare_event_hash(model)
        model.to_hash.tap { |event_hash|
          event_hash[:ip_lease_id] = event_hash[:id]
          event_hash[:id] = event_hash[:interface_id]
        }
      end

    end
  end
end
