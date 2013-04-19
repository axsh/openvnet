
module Vnmgr::Models
  class Vif < Base
    many_to_one :Network
  end
end
