# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class MacLease < Base
    class << self
      def create(options)
        options = options.dup
        mac_lease = transaction do
          model_class.create(options)
        end

        eif = mac_lease.interface.enable_ingress_filtering
        dispatch_event(LEASED_MAC_ADDRESS, id: mac_lease.interface_id,
                                           enable_ingress_filtering: eif,
                                           mac_lease_id: mac_lease.id,
                                           mac_address: mac_lease.mac_address)

        mac_lease
      end

      def update(uuid, options)
        options = options.dup
        mac_address = options.delete(:mac_address)
        deleted_mac_address = nil

        mac_lease = transaction do
          model_class[uuid].tap do |model|
            if model.mac_address.mac_address != mac_address
              model.mac_address.destroy
              deleted_mac_address = model.mac_address
              model.mac_address = model_class(:mac_address).create(mac_address: mac_address)
            end
            model.set(options)
            model.save_changes
            model
          end
        end

        if deleted_mac_address
          dispatch_event(RELEASED_MAC_ADDRESS, id: mac_lease.interface_id,
                                               mac_lease_id: mac_lease.id)

          eif = mac_lease.interface.enable_ingress_filtering
          dispatch_event(LEASED_MAC_ADDRESS, id: mac_lease.interface_id,
                                             enable_ingress_filtering: eif,
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

        dispatch_event(RELEASED_MAC_ADDRESS, id: mac_lease.interface_id, mac_lease_id: mac_lease.id)

        mac_lease
      end
    end
  end
end
