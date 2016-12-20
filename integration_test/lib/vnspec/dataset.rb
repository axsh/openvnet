# -*- coding: utf-8 -*-
module Vnspec
  class Dataset
    include Logger
    include Config

    class << self
      def setup(name)
        self.new(name).setup
      end

    end

    attr_reader :name
    attr_reader :dataset
    attr_reader :options

    def initialize(name)
      @name = name
      @options = config[:dataset_options]
      init_dataset
    end

    def setup
      @dataset.each do |key, value|
        value.each do |v|
          v = v.dup
          request_type = :post

          url = case key
          when :datapath_networks
            "datapaths/#{v.delete(:datapath_uuid)}/networks/#{v.delete(:network_uuid)}"
          when :datapath_route_links
            "datapaths/#{v.delete(:datapath_uuid)}/route_links/#{v.delete(:route_link_uuid)}"
          when :datapath_segments
            "datapaths/#{v.delete(:datapath_uuid)}/segments/#{v.delete(:segment_uuid)}"
          when :interface_security_groups
            "interfaces/#{v.delete(:interface_uuid)}/security_groups/#{v.delete(:security_group_uuid)}"
          when :interface_network_puts
            request_type = :put
            "interfaces/#{v.delete(:interface_uuid)}/networks/#{v.delete(:network_uuid)}"
          when :interface_segment_puts
            request_type = :put
            "interfaces/#{v.delete(:interface_uuid)}/segments/#{v.delete(:segment_uuid)}"
          when :filter_static
            "filters/#{v.delete(:filter_uuid)}/static"
          when :dns_records
            "dns_services/#{v.delete(:dns_service_uuid)}/dns_records"
          when :ip_ranges
            "ip_range_groups/#{v.delete(:ip_range_group_uuid)}/ip_ranges"
          when :lease_policy_base_networks
            "lease_policies/#{v.delete(:lease_policy_uuid)}/networks/#{v.delete(:network_uuid)}"
          when :lease_policy_base_interfaces
            "lease_policies/#{v.delete(:lease_policy_uuid)}/interfaces/#{v.delete(:interface_uuid)}"
          when :lease_policy_ip_lease_containers
            "lease_policies/#{v.delete(:lease_policy_uuid)}/ip_lease_containers/#{v.delete(:ip_lease_container_uuid)}"
          when :lease_policy_ip_retention_containers
            "lease_policies/#{v.delete(:lease_policy_uuid)}/ip_retention_containers/#{v.delete(:ip_retention_container_uuid)}"
          when :mac_range_group_mac_ranges
            "mac_range_groups/#{v.delete(:mac_range_group_uuid)}/mac_ranges"
          when :topology_networks
            "topologies/#{v.delete(:topology_uuid)}/networks/#{v.delete(:network_uuid)}"
          when :topology_segments
            "topologies/#{v.delete(:topology_uuid)}/segments/#{v.delete(:segment_uuid)}"
          when :topology_route_links
            "topologies/#{v.delete(:topology_uuid)}/route_links/#{v.delete(:route_link_uuid)}"
          when :translation_static_addresses
            "translations/#{v.delete(:translation_uuid)}/static_address"
          else
            key.to_s
          end

          request(request_type, url, v)
        end
      end
    end

    def request(method, url, params = {}, headers = {}, &block)
      API.request(method, url, params, headers, &block)
    end

    def is_topology?
      @name =~ /_tp$/
    end

    private

    def init_dataset
      files = ['base']

      files << if is_topology?
                 'base_topology'
               else
                 'base_dp'
               end

      files << name

      @dataset = files.each_with_object({}) do |n, h|
        load_file(n).each do |k, v|
          h[k] ||= []
          h[k] += v if v
        end
      end
    end

    def load_file(name)
      file = File.expand_path(File.join("../../dataset", "#{name}.yml"), File.dirname(__FILE__))
      body = ERB.new(File.open(file).read).result_hash(options)
      YAML.load(body).symbolize_keys
    end
  end
end
