# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::NodeApi
  class LeasePolicyBaseInterface < Base
    class << self
      def create(options)
        p ",,,in create(#{options.inspect})"

        base_networks = model_class(:lease_policy)[options[:lease_policy_id]].lease_policy_base_networks
        raise "No network associated with lease policy" if base_networks.empty?

        network_id = base_networks.first.network_id
        ip_range_id = base_networks.first.ip_range_id
        p "network_id = #{network_id}, ip_range_id = #{ip_range_id}"

        ip_r = base_networks.first.ip_range

        p net = base_networks.first.network

        begip = net.ipv4_network
        pref = net.ipv4_prefix
        max = 2 << ( 31 - pref )
        
        p get_lease_address(net, ip_r, begip, begip+max, :asc)
        super
      end

      def destroy(uuid)
        p ",,,in destroy(#{uuid.inspect})"
        super
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

        ip_r.ip_ranges_ranges_dataset.containing_range(from_ipaddr, to_ipaddr).order(range_order).all.each {|i|
          p "doing #{i.inspect}"
          start_range = i.begin_ipv4_address.to_i
          end_range = i.end_ipv4_address.to_i

          raise "Got from_ipaddr > end_range: #{from_ipaddr} > #{end_range}" if from_ipaddr > end_range
          f = (from_ipaddr > start_range) ? from_ipaddr : start_range
          raise "Got to_ipaddr < start_range: #{to_ipaddr} < #{start_range}" if to_ipaddr < start_range
          t = (to_ipaddr < end_range) ? to_ipaddr : end_range

          begin
            is_loop = false

            leaseaddr = i.available_ip(network.id, f, t, order)
            break if leaseaddr.nil?
            check_ip = IPAddress::IPv4.parse_u32(leaseaddr, network[:ipv4_prefix])
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
