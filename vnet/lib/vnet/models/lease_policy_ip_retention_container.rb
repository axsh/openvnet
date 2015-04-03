module Vnet::Models

  # TODO: Refactor.
  class LeasePolicyIpRetentionContainer < Base
    many_to_one :lease_policy
    many_to_one :ip_retention_container
  end
end
