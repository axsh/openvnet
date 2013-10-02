# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Interface < Base
    class << self
      def create(options)
        ipv4_address = options.delete(:ipv4_address)

        ipv4_created = false
        interface = transaction do
          model_class.create(options).tap do |interface|
            if interface.network && ipv4_address
              ipv4_created = true
              interface.add_ip_lease(
                { :network_id => interface.network.id,
                  :interface_id => interface.id,
                  :ip_address_id => IpAddress.create({:ipv4_address => ipv4_address})[:id]})
            end
          end
        end
        to_hash(interface)
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
