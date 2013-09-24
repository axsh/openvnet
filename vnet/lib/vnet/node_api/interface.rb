# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Interface < Base
    class << self
      def create(options)
        interface = transaction { model_class.create(options) }

        if interface.network_id
          dispatch_event("network/interface_added", network_id: interface.network_id, interface_id: interface.id)
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
