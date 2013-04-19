
module Vnmgr::Models
  class DhcpRange < Base
    many_to_one :Network
  end
end
