
module Vnmgr::Models
  class Vif < Base
    taggable 'vif'
    many_to_one :Network
  end
end
