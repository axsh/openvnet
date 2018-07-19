# -*- coding: utf-8 -*-

module Vnet::NodeApi

  class LegacyBase < EventBase
    class << self
      private

      def dispatch_created_item_events(model)
      end

      def dispatch_deleted_item_events(model)
      end
    end
  end

  class IpAddress < LegacyBase
    valid_update_fields []
  end

  class IpRange < LegacyBase
    valid_update_fields []
  end

  class IpRangeGroup < LegacyBase
    valid_update_fields [:allocation_type]
  end

  class MacAddress < LegacyBase
    valid_update_fields []
  end

end
