# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class Translation < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
        dispatch_event(TRANSLATION_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(TRANSLATION_DELETED_ITEM, id: model.id)
      end

    end
  end

  class VlanTranslation < Base
  end

end
