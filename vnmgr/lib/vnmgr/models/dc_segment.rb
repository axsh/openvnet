module Vnmgr::Models
  class DcSegment < Base
    taggable "ds"

    one_to_many :datapaths
    one_to_many :dc_network_dc_segments
    many_to_many :dc_networks, :join_table => :dc_network_dc_segments
  end
end
