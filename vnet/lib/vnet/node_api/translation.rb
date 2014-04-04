# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Translation < Base
  end

  class TranslateStaticAddress < Base
    class << self
      def create(options)
        super.tap do |obj|
          dispatch_event(TRANSLATION_ADDED_STATIC_ADDRESS,
                         id: obj.translation_id,
                         static_address_id: obj.id,
                         ingress_ipv4_address: obj.ingress_ipv4_address,
                         egress_ipv4_address: obj.egress_ipv4_address)                         
        end
      end

      def destroy(uuid)
        super.tap do |obj|
          dispatch_event(TRANSLATION_REMOVED_STATIC_ADDRESS,
                         id: obj.translation_id,
                         static_address_id: obj.id,
                         ingress_ipv4_address: obj.ingress_ipv4_address,
                         egress_ipv4_address: obj.egress_ipv4_address)                         
        end
      end
    end
  end

  class VlanTranslation < Base
  end

end
