# -*- coding: utf-8 -*-

module VNetAPIClient

  class Datapath < ApiResource
    api_suffix :datapaths

    define_standard_crud_methods
    define_relation_methods(:networks)
    define_relation_methods(:route_links)

    define_show_relation(:dns_records)
    define_remove_relation(:dns_records)
  end

  class DnsService < ApiResource
    api_suffix :dns_services

    define_standard_crud_methods

    def self.add_dns_record(dns_service_uuid, params = nil)
      send_request(Net::HTTP::Post, "#{@api_suffix}/#{dns_service_uuid}/dns_records")
    end
  end

  class Interface < ApiResource
    api_suffix :interfaces

    define_standard_crud_methods
    define_relation_methods(:security_groups)

    define_show_relation(:ports)
  end

  class IpLease < ApiResource
    api_suffix :ip_leases

    define_standard_crud_methods
  end

  class IpRangeGroup < ApiResource
    api_suffix :ip_range_groups

    define_standard_crud_methods

    define_show_relation(:ip_ranges)
    define_remove_relation(:ip_ranges)
  end

  class IpLeaseContainer < ApiResource
    api_suffix :ip_lease_containers

    define_standard_crud_methods

    define_show_relation(:ip_leases)
  end

  class IpRetentionContainer < ApiResource
    api_suffix :ip_retention_containers

    define_standard_crud_methods

    define_show_relation(:ip_retentions)
  end

  class LeasePolicy < ApiResource
    api_suffix :lease_policies

    define_standard_crud_methods
    define_relation_methods(:ip_lease_containers)
    define_relation_methods(:ip_retention_containers)
    define_relation_methods(:networks)
    define_relation_methods(:interfaces)
  end

  class MacLease < ApiResource
    api_suffix :mac_leases

    define_standard_crud_methods
  end

  class Network < ApiResource
    api_suffix :networks

    define_standard_crud_methods
  end

  class NetworkService < ApiResource
    api_suffix :network_services

    define_standard_crud_methods
  end

  class Route < ApiResource
    api_suffix :routes

    define_standard_crud_methods
  end

  class RouteLink < ApiResource
    api_suffix :route_links

    define_standard_crud_methods
  end

  class SecurityGroup < ApiResource
    api_suffix :security_groups

    define_standard_crud_methods
    define_relation_methods(:interfaces)
  end

  class Translation < ApiResource
    api_suffix :translations

    define_standard_crud_methods
  end

  class VlanTranslation < ApiResource
    api_suffix :vlan_translations

    define_standard_crud_methods
  end

end

