module Vnet::Models
  class DcNetworkDcSegment < Base
    many_to_one :dc_network
    many_to_one :dc_segment
  end
end
