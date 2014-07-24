module Vnet::Models

  # TODO: Refactor.
  class DnsRecord < Base
    taggable "dnsr"

    plugin :paranoia

    many_to_one :dns_service
  end
end
