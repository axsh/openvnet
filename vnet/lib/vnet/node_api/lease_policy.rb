# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::NodeApi
  class LeasePolicy < Base
    class << self
      include Vnet::Constants::LeasePolicy

      def allocate_ip(options)
        lease_policy = model_class(:lease_policy)[options[:lease_policy_id]]
        if lease_policy.timing == "immediate"
          base_networks = lease_policy.lease_policy_base_networks
          raise "No network associated with lease policy" if base_networks.empty?
          
          ip_r = base_networks.first.ip_range
          net = base_networks.first.network

          new_ip = schedule(net,ip_r)
          # TODO: race condition between here and the allocation?
          interface = model_class(:interface)[options[:interface_id]]
          if (ml_array = interface.mac_leases).empty?
            raise "Cannot create IP lease because interface #{interface.uuid} does not have a MAC lease"
          end
          ip_lease = model_class(:ip_lease).create({
                                                     mac_lease_id: ml_array.first.id,
                                                     network_id: net.id,
                                                     ipv4_address: new_ip
                                                   })
        end
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
        if leaseaddr.nil?
          netstr = IPAddress::IPv4.parse_u32(network.ipv4_network, network.ipv4_prefix).to_string
          raise "Run out of dynamic IP addresses from the network segment: #{network.uuid}, #{netstr}"
        end
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
