# -*- coding: utf-8 -*-

module VNetAPIClient

  class Datapath < ApiResource
    define_standard_crud_methods
    define_relation_methods(:networks)
    define_relation_methods(:route_links)
  end

  class DnsService < ApiResource
    define_standard_crud_methods
  end

  class Interface < ApiResource
    define_standard_crud_methods
    define_relation_methods(:security_groups)
  end

  class IpLease < ApiResource
    define_standard_crud_methods
  end

  class IpRangeGroup < ApiResource
    define_standard_crud_methods

    def self.show_ip_ranges(uuid)
      send_request(Net::HTTP::Get, "#{@api_suffix}/#{uuid}/ip_ranges")
    end

    def self.remove_ip_range(uuid, ip_range_uuid)
      suffix = "#{@api_suffix}/#{uuid}/ip_ranges/#{ip_range_uuid}"
      send_request(Net::HTTP::Delete, suffix)
    end
  end

  class IpLeaseContainer < ApiResource
    define_standard_crud_methods

    def self.show_ip_leases(uuid)
      send_request(Net::HTTP::Get, "#{@api_suffix}/#{uuid}/ip_leases")
    end
  end

  class IpRetentionContainer < ApiResource
    define_standard_crud_methods

    def self.show_ip_retentions(uuid)
      send_request(Net::HTTP::Get, "#{@api_suffix}/#{uuid}/ip_retentions")
    end
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

