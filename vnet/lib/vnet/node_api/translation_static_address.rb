# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class TranslationStaticAddress < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        model_hash = model.to_hash.merge(id: model.translation_id,
                                         static_address_id: model.id)

        dispatch_event(TRANSLATION_ADDED_STATIC_ADDRESS, model_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(TRANSLATION_REMOVED_STATIC_ADDRESS,
                       id: model.translation_id,
                       static_address_id: model.id)
      end

    end
  end
end
