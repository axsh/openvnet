# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Interface < Base
    class << self
      def create(options)
        ipv4_address = options.delete(:ipv4_address)

        iface = transaction do
          model_class.create(options).tap do |iface|
            if iface.network && ipv4_address
              iface.add_ip_lease(
                { :network_id => iface.network.id,
                  :iface_id => iface.id,
                  :ip_address_id => IpAddress.create({:ipv4_address => ipv4_address})[:id]})
            end
          end
        end

        if iface.network_id
          dispatch_event("network/iface_added", network_id: iface.network_id, iface_id: iface.id)
        end

        to_hash(iface)
      end

      def destroy(uuid)
        # TODO implement me
      end

      def update(uuid, options)
        # TODO implement me
      end
    end
  end
end
