# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class IpLease < EventBase
    valid_update_fields [:enable_routing, :interface_id]

    class << self

      # TODO: Use update instead of attach/release.
      def attach_id(options)
        model = model_class[id: options[:id]]
        attach_model(model, options)
      end

      def attach_uuid(options)
        model = model_class[options[:uuid]]
        attach_model(model, options)
      end

      def release_uuid(uuid)
        model = model_class[uuid]
        release_model(model)
      end

      def release(uuid)
        model = model_class[uuid]
        release_model(model)
      end

      def dispatch_deleted_for_network(network_id, deleted_at)
        filter_date = ['deleted_at >= ? || deleted_at = NULL',
                       (deleted_at || Time.now) - 3]

        ip_address_ds = M::IpAddress.with_deleted.where(network_id: network_id)

        M::IpLease.with_deleted.where(ip_address: ip_address_ds).where(*filter_date).each { |lease|
          dispatch_deleted_item_events(lease)
        }
      end

      #
      # Internal methods:
      #

      private

      def create_with_transaction(options)
        options = options.dup

        interface_id = options[:interface_id]
        mac_lease_id = options[:mac_lease_id]

        transaction {
          handle_new_uuid(options)

          if interface_id || mac_lease_id
            interface, mac_lease = get_if_and_ml(interface_id, mac_lease_id)

            options[:interface_id] = interface && interface.id
            options[:mac_lease_id] = mac_lease && mac_lease.id
          end

          internal_create(options).tap { |model|
            next if model.nil?
            InterfaceNetwork.update_assoc(model.interface_id, model.network_id)
          }
        }
      end

      def destroy_with_transaction(filter)
        internal_destroy(model_class[filter]).tap { |model|
          next if model.nil?
          InterfaceNetwork.update_assoc(model.interface_id, model.network_id)
        }
      end

      def dispatch_created_item_events(model)
        if model.interface_id
          dispatch_event(INTERFACE_LEASED_IPV4_ADDRESS, prepare_lease_event(model))
        end
      end

      # TODO: Fix this so it updates 'enable_routing'.
      def dispatch_updated_item_events(model, old_values)
        # dispatch_event(INTERFACE_SEGMENT_UPDATED_ITEM, get_changed_hash(model, changed_keys))
      end

      def dispatch_deleted_item_events(model)
        if model.interface_id
          dispatch_event(INTERFACE_RELEASED_IPV4_ADDRESS, prepare_release_event(model))
        end

        filter = { ip_lease_id: model.id }

        # 0001_origin
        # datapath_networks: :destroy,
        # datapath_route_links: :destroy,
        # ip_address: :destroy,
        # ip_lease_container_ip_leases: :destroy,
        # 0002_services
        IpRetention.dispatch_deleted_where(filter, model.deleted_at)
      end

      def prepare_lease_event(model)
        # model.to_hash.tap { |event_hash|
        #   event_hash[:ip_lease_id] = event_hash[:id]
        #   event_hash[:id] = event_hash[:interface_id]
        # }
        prepare_release_event(model)
      end

      def prepare_release_event(model)
        { id: model.interface_id,
          ip_lease_id: model.id
        }
      end

      #
      # Attach / Detach:
      #

      # TODO: Refactor so we use 'put' from endpoints instead.

      # TODO: Use a filter instead.
      def attach_model(model, options)
        # Verify model is not nil.

        interface_id = options[:interface_id]
        mac_lease_id = options[:mac_lease_id]

        if interface_id.nil? && mac_lease_id.nil?
          raise ArgumentError, 'Need valid interface or mac lease'
        end

        if !model.interface_id.nil? || !model.mac_lease_id.nil?
          raise ArgumentError, 'Already attached'
        end

        interface = nil

        transaction {
          interface, mac_lease = get_if_and_ml(interface_id, mac_lease_id)

          model.interface_id = interface.id
          model.mac_lease_id = mac_lease.id

          model.save_changes
          current_time = Time.now # Use updated_at instead?

          model.ip_retentions.each do |ip_retention|
            ip_retention.released_at = nil
            ip_retention.save_changes
          end
        }

        dispatch_event(INTERFACE_LEASED_IPV4_ADDRESS, prepare_lease_event(model))
        model
      end

      def release_model(model)
        # Verify model is not nil.

        interface = nil

        transaction do
          # Refresh?

          interface = model.interface

          if model.interface_id.nil? && model.mac_lease_id.nil?
            raise ArgumentError, 'Not attached' # raise error or release
          end

          model.interface_id = nil
          model.mac_lease_id = nil

          model.save_changes
          current_time = Time.now # Use updated_at instead?

          model.ip_retentions.each do |ip_retention|
            ip_retention.released_at = current_time
            ip_retention.save_changes
          end
        end

        dispatch_event(INTERFACE_RELEASED_IPV4_ADDRESS, id: interface.id, ip_lease_id: model.id)

        # TODO: Move this to ip_retentions as a dispatch_foo_where
        # method.
        #
        # re-add released ip_retentions
        model.ip_retentions.each do |ip_retention|
          dispatch_event(
            IP_RETENTION_CONTAINER_ADDED_IP_RETENTION,
            id: ip_retention.ip_retention_container_id,
            ip_retention_id: ip_retention.id,
            ip_lease_id: ip_retention.ip_lease_id,
            leased_at: ip_retention.leased_at,
            released_at: ip_retention.released_at
          )
        end

        model
      end

      def get_if_and_ml(interface_id, mac_lease_id)
        if interface_id.nil? && mac_lease_id.nil?
          raise ArgumentError, 'Either interface and/or mac lease must be supplied'
        end

        interface = interface_id && M::Interface[id: interface_id]
        mac_lease = mac_lease_id && M::MacLease[id: mac_lease_id]

        if interface && mac_lease.nil? && mac_lease_id.nil?
          # Error if the interface has more than one mac_lease?
          mac_lease = interface.mac_leases.first
        end

        if mac_lease && interface.nil? && interface_id.nil?
          interface = mac_lease.interface
        end

        if interface.nil? || mac_lease.nil?
          raise ArgumentError, 'Could not find fitting interface or mac lease'
        end

        [interface, mac_lease]
      end

    end
  end
end
