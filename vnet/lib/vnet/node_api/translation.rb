# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Translation < Base
    class << self
      def create(options)
        super.tap do |obj|
          dispatch_event(TRANSLATION_CREATED_ITEM, obj.values)
        end
      end

      def destroy(uuid)
        super.tap do |obj|
          dispatch_event(TRANSLATION_DELETED_ITEM, id: obj.id)
        end
      end
    end
  end

  class TranslationStaticAddress < Base
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
