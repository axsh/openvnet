# -*- coding: utf-8 -*-

module VNetAPIClient

  class Datapath < ApiResource
    api_suffix :datapaths

    define_standard_crud_methods
    define_relation_methods(:networks)
    define_relation_methods(:segments)
    define_relation_methods(:route_links)
  end

  class DnsService < ApiResource
    api_suffix :dns_services

    define_standard_crud_methods

    define_show_relation(:dns_records)
    define_remove_relation(:dns_records)

    def self.add_dns_record(dns_service_uuid, params = nil)
      send_request(Net::HTTP::Post,
                   "#{@api_suffix}/#{dns_service_uuid}/dns_records",
                   params)
    end
  end

  class Interface < ApiResource
    api_suffix :interfaces

    define_standard_crud_methods
    define_relation_methods(:security_groups)

    define_show_relation(:ports)

    define_update_relation(:segments)
    define_show_relation(:segments)

    def self.rename(interface_uuid, params = nil)
      send_request(Net::HTTP::Put, "#{@api_suffix}/#{interface_uuid}/rename", params)
    end

    def self.add_port(interface_uuid, params = nil)
      send_request(Net::HTTP::Post, "#{@api_suffix}/#{interface_uuid}/ports", params)
    end

    def self.remove_port(interface_uuid, params = nil)
      send_request(Net::HTTP::Delete, "#{@api_suffix}/#{interface_uuid}/ports", params)
    end
  end

  class IpLease < ApiResource
    api_suffix :ip_leases

    define_standard_crud_methods

    def self.attach(target_uuid, params = nil)
      send_request(Net::HTTP::Put,
                   "#{@api_suffix}/#{target_uuid}/attach",
                   params)
    end

    def self.release(target_uuid, params = nil)
      send_request(Net::HTTP::Put,
                   "#{@api_suffix}/#{target_uuid}/release",
                   params)
    end

  end

  class IpRangeGroup < ApiResource
    api_suffix :ip_range_groups

    define_standard_crud_methods

    define_show_relation(:ip_ranges)
    define_remove_relation(:ip_ranges)

    def self.add_range(ip_range_group_uuid, params = nil)
      send_request(Net::HTTP::Post,
                   "#{@api_suffix}/#{ip_range_group_uuid}/ip_ranges",
                   params)
    end
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

    def self.add_lease(lease_policy_uuid, params = nil)
      send_request(Net::HTTP::Post,
                   "#{@api_suffix}/#{lease_policy_uuid}/ip_leases",
                   params)
    end
  end

  class MacLease < ApiResource
    api_suffix :mac_leases

    define_standard_crud_methods
  end

  class MacRangeGroup < ApiResource
    api_suffix :mac_range_groups

    define_standard_crud_methods

    define_show_relation(:mac_ranges)
    define_remove_relation(:mac_ranges)

    def self.add_range(mac_range_group_uuid, params = nil)
      send_request(Net::HTTP::Post,
                   "#{@api_suffix}/#{mac_range_group_uuid}/mac_ranges",
                   params)
    end
  end

  class Network < ApiResource
    api_suffix :networks

    define_standard_crud_methods

    define_relation_methods(:segments)
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

  class Segment < ApiResource
    api_suffix :segments

    define_standard_crud_methods
  end

  class Translation < ApiResource
    api_suffix :translations

    define_standard_crud_methods

    def self.add_static_address(translation_uuid, params = nil)
      send_request(Net::HTTP::Post,
                   "#{@api_suffix}/#{translation_uuid}/static_address",
                   params)
    end

    def self.remove_static_address(translation_uuid, params = nil)
      send_request(Net::HTTP::Delete,
                   "#{@api_suffix}/#{translation_uuid}/static_address",
                   params)
    end
  end

  class Filter < ApiResource
    api_suffix :filters

    define_standard_crud_methods

    def self.add_filter_static(filter_uuid, params = nil)
      send_request(Net::HTTP::Post,
                   "#{@api_suffix}/#{filter_uuid}/static",
                   params)
    end

    def self.remove_filter_static(filter_uuid, params = nil)
      send_request(Net::HTTP::Delete,
                   "#{@api_suffix}/#{filter_uuid}/static",
                   params)
    end
    def self.show_filter_static(params = nil)
      send_request(Net::HTTP::Get,
                   "#{@api_suffix}/static/",
                   params)
    end
    def self.show_filter_static_by_uuid(filter_uuid, params = nil)
      send_request(Net::HTTP::Get,
                   "#{@api_suffix}/static/#{filter_uuid}",
                   params)
    end
  end

  class Topology < ApiResource
    api_suffix :topologies

    define_standard_crud_methods
    define_relation_methods(:networks)
    define_relation_methods(:segments)
    define_relation_methods(:route_links)
  end

  class VlanTranslation < ApiResource
    api_suffix :vlan_translations

    define_standard_crud_methods
  end

end

