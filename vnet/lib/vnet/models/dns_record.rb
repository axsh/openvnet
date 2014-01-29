module Vnet::Models
  class DnsRecord < Base
    taggable "dnsr"

    plugin :paranoia

    many_to_one :dns_service
  end
end
