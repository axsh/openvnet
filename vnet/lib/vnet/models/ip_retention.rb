module Vnet::Models
  class IpRetention < Base
    many_to_one :ip_lease
  end
end
