# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Vif < Base
    class << self
      def create(options)
        ipv4_address = options.delete(:ipv4_address)

        vif = transaction do
          model_class.create(options).tap do |vif|
            if vif.network && ipv4_address
              vif.add_ip_lease(
                { :network_id => vif.network.id,
                  :vif_id => vif.id,
                  :ip_address_id => IpAddress.create({:ipv4_address => ipv4_address})[:id]})
            end
          end
        end

        if vif.network_id
          dispatch_event("network/vif_added", network_id: vif.network_id, vif_id: vif.id)
        end

        to_hash(vif)
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
