module Vnet::Models
  class DcSegment < Base
    taggable "ds"

    one_to_many :datapaths
  end
end
