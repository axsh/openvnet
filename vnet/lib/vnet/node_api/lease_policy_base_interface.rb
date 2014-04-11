# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::NodeApi
  class LeasePolicyBaseInterface < Base
    class << self
      include Vnet::Constants::LeasePolicy

      def create(options)
        p ",,,in create(#{options.inspect})"

        base_networks = model_class(:lease_policy)[options[:lease_policy_id]].lease_policy_base_networks
        raise "No network associated with lease policy" if base_networks.empty?

        network_id = base_networks.first.network_id
        ip_range_id = base_networks.first.ip_range_id
        p "network_id = #{network_id}, ip_range_id = #{ip_range_id}"

        ip_r = base_networks.first.ip_range

        p net = base_networks.first.network

        p schedule(net,ip_r)
        super
      end

      def destroy(uuid)
        p ",,,in destroy(#{uuid.inspect})"
        super
      end

      def schedule(network, ip_range)
        # TODO: consider how to filter for addresses dynamically assigned
        latest_ip = model_class(:ip_address).order(:updated_at.desc).first
        ipaddr = latest_ip.nil? ? nil : latest_ip.ipv4_address
        leaseaddr = case ip_range.allocation_type
                    when ALLOCATION_TYPE_INCREMENTAL
                      ip = get_lease_address(network, ip_range, ipaddr, nil, :asc)
                      ip = get_lease_address(network, ip_range, nil, ipaddr, :asc) if ip.nil?
                      ip
                    when ALLOCATION_TYPE_DECREMENTAL
                      ip = get_lease_address(network, ip_range, nil, ipaddr, :desc)
                      ip = get_lease_address(network, ip_range, ipaddr, nil, :desc) if ip.nil?
                      ip
                    else
                      raise "Unsupported IP address assignment: #{ip_range.allocation_type}"
                    end
        raise "Run out of dynamic IP addresses from the network segment: #{network.uuid}" if leaseaddr.nil?
        # TODO: also show ip subnet info in error message
        
        leaseaddr
      end

      def get_lease_address(network, ip_r, from_ipaddr, to_ipaddr, order)
        from_ipaddr = 0 if from_ipaddr.nil?
        to_ipaddr = 0xFFFFFFFF if to_ipaddr.nil?
        raise ArgumentError unless from_ipaddr.is_a?(Integer)
        raise ArgumentError unless to_ipaddr.is_a?(Integer)

        leaseaddr = nil

        range_order = {
          :asc => :begin_ipv4_address.asc,
          :desc => :end_ipv4_address.desc,
        }[order]

        net_start = network.ipv4_network
        net_prefix = network.ipv4_prefix
        suffix_mask = 0xFFFFFFFF >> net_prefix
        ip_r.ip_ranges_ranges_dataset.containing_range(from_ipaddr, to_ipaddr).order(range_order).all.each {|i|
          start_range = net_start + ( suffix_mask & i.begin_ipv4_address.to_i )
          end_range   = net_start + ( suffix_mask & i.end_ipv4_address.to_i )

          raise "Got from_ipaddr > end_range: #{from_ipaddr} > #{end_range}" if from_ipaddr > end_range
          f = (from_ipaddr > start_range) ? from_ipaddr : start_range
          raise "Got to_ipaddr < start_range: #{to_ipaddr} < #{start_range}" if to_ipaddr < start_range
          t = (to_ipaddr < end_range) ? to_ipaddr : end_range

          begin
            is_loop = false

            leaseaddr = i.available_ip(network.id, f, t, order)
            break if leaseaddr.nil?
            check_ip = IPAddress::IPv4.parse_u32(leaseaddr, net_prefix)
            # To check the IP address that can not be used.
            # TODO No longer needed in the future.
##            if network.reserved_ip?(check_ip)
##              network.network_vif_ip_lease_dataset.add_reserved(check_ip.to_s)
##              is_loop = true
##            end
            case order
            when :asc
              f = check_ip.to_i
            when :desc
              t = check_ip.to_i
            else
              raise "Unsupported IP address assignment: #{order.to_s}"
            end
          end while is_loop
          break unless leaseaddr.nil?
        }
        leaseaddr
      end
    end
  end
end
