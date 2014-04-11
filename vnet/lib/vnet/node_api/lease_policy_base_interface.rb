# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class LeasePolicyBaseInterface < Base
    class << self
      def create(options)
        p ",,,in create(#{options.inspect})"
        super
      end

      def destroy(uuid)
        p ",,,in destroy(#{uuid.inspect})"
        super
      end

      def get_lease_address(network, from_ipaddr, to_ipaddr, order)
        from_ipaddr = 0 if from_ipaddr.nil?
        to_ipaddr = 0xFFFFFFFF if to_ipaddr.nil?
        raise ArgumentError unless from_ipaddr.is_a?(Integer)
        raise ArgumentError unless to_ipaddr.is_a?(Integer)

        leaseaddr = nil

        range_order = {
          :asc => :range_begin.asc,
          :desc => :range_end.desc,
        }[order]

        network.dhcp_range_dataset.containing_range(from_ipaddr, to_ipaddr).order(range_order).all.each {|i|
          start_range = i.range_begin.to_i
          end_range = i.range_end.to_i

          raise "Got from_ipaddr > end_range: #{from_ipaddr} > #{end_range}" if from_ipaddr > end_range
          f = (from_ipaddr > start_range) ? from_ipaddr : start_range
          raise "Got to_ipaddr < start_range: #{to_ipaddr} < #{start_range}" if to_ipaddr < start_range
          t = (to_ipaddr < end_range) ? to_ipaddr : end_range

          begin
            is_loop = false

            leaseaddr = i.available_ip(f, t, order)
            break if leaseaddr.nil?
            check_ip = IPAddress::IPv4.parse_u32(leaseaddr, network[:prefix])
            # To check the IP address that can not be used.
            # TODO No longer needed in the future.
            if network.reserved_ip?(check_ip)
              network.network_vif_ip_lease_dataset.add_reserved(check_ip.to_s)
              is_loop = true
            end
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
