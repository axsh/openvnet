module Vnet::NodeApi
  class IpRetention < Base
    class << self
      include Vnet::Helpers::Event

      def destroy(id)
        super
        dispatch_event(IP_RETENTION_DELETED_ITEM, id: id)
      end
    end
  end
end
