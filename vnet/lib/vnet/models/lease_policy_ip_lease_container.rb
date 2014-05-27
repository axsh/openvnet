module Vnet::Models
  class LeasePolicyIpLeaseContainer < Base
    many_to_one :lease_policy
    many_to_one :ip_lease_container
  end
end
