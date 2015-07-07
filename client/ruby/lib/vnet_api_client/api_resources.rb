# -*- coding: utf-8 -*-

module VNetAPIClient

  class Datapath < ApiResource
    define_standard_crud_methods
    define_relation_methods(:networks)
    define_relation_methods(:route_links)

    define_show_relation(:dns_records)
    define_remove_relation(:dns_records)
  end

  class DnsService < ApiResource
    define_standard_crud_methods
  end

  class Interface < ApiResource
    define_standard_crud_methods
    define_relation_methods(:security_groups)

    define_show_relation(:ports)
  end

  class IpLease < ApiResource
    define_standard_crud_methods
  end

  class IpRangeGroup < ApiResource
    define_standard_crud_methods

    define_show_relation(:ip_ranges)
    define_remove_relation(:ip_ranges)
  end

  class IpLeaseContainer < ApiResource
    define_standard_crud_methods

    define_show_relation(:ip_leases)
  end

  class IpRetentionContainer < ApiResource
    define_standard_crud_methods

    define_show_relation(:ip_retentions)
  end

  #TODO: Fix the plural here
  class LeasePolicie < ApiResource
    define_standard_crud_methods
    define_relation_methods(:ip_lease_containers)
    define_relation_methods(:ip_retention_containers)
    define_relation_methods(:networks)
    define_relation_methods(:interfaces)
  end

  class MacLease < ApiResource
    define_standard_crud_methods
  end

  class Network < ApiResource
    define_standard_crud_methods
  end

  class NetworkService < ApiResource
    define_standard_crud_methods
  end

  class Route < ApiResource
    define_standard_crud_methods
  end

  class RouteLink < ApiResource
    define_standard_crud_methods
  end

  class SecurityGroup < ApiResource
    define_standard_crud_methods
    define_relation_methods(:interfaces)
  end

  class Translation < ApiResource
    define_standard_crud_methods
  end

  class VlanTranslation < ApiResource
    define_standard_crud_methods
  end

end

