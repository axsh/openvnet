# -*- coding: utf-8 -*-

module Vnet::Models
  class DnsRecord < Base
    taggable "dnsr"

    plugin :paranoia_is_deleted

    many_to_one :dns_service

  end
end
