module Vnet::Models

  # TODO: Refactor.
  class IpLeaseContainerIpLease < Base
    many_to_one :ip_lease_container
    many_to_one :ip_lease
  end
end
