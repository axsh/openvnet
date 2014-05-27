# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class MacLease < Base
    class << self
      def create(options)
        options = options.dup
        mac_lease = transaction do
          model_class.create(options)
        end

        dispatch_event(INTERFACE_LEASED_MAC_ADDRESS, id: mac_lease.interface_id,
                                           mac_lease_id: mac_lease.id,
                                           mac_address: mac_lease.mac_address)

        mac_lease
      end

      def update(uuid, options)
        options = options.dup
        deleted_mac_address = false

        mac_lease = transaction do
          model_class[uuid].tap do |model|
            deleted_mac_address = true if options[:mac_address]
            model.set(options)
            model.save_changes
            model
          end
        end

        if deleted_mac_address
          dispatch_event(INTERFACE_RELEASED_MAC_ADDRESS, id: mac_lease.interface_id,
                                               mac_lease_id: mac_lease.id)

          dispatch_event(INTERFACE_LEASED_MAC_ADDRESS, id: mac_lease.interface_id,
                                             mac_lease_id: mac_lease.id,
                                             mac_address: mac_lease.mac_address)
        end

        mac_lease
      end

      def destroy(uuid)
        mac_lease = model_class[uuid].tap do |model|
          transaction do
            model.destroy
          end
        end

        dispatch_event(INTERFACE_RELEASED_MAC_ADDRESS, id: mac_lease.interface_id, mac_lease_id: mac_lease.id)

        mac_lease
      end
    end
  end
end
