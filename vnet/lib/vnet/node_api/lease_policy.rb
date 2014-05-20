# -*- coding: utf-8 -*-

require "ipaddress"

module Vnet::NodeApi
  class LeasePolicy < Base
    class << self
      include Vnet::Constants::LeasePolicy

      def allocate_ip(options)
        lease_policy = model_class(:lease_policy)[options[:lease_policy_uuid]]
        if lease_policy.timing == "immediate"
          base_networks = lease_policy.lease_policy_base_networks
          raise "No network associated with lease policy" if base_networks.empty?
          
          ip_r = base_networks.first.ip_range_group
          net = base_networks.first.network

          new_ip = schedule(net,ip_r)

          options_for_ip_lease = {
            network_id: net.id,
            ipv4_address: new_ip,
            lease_time: lease_policy.lease_time,
            grace_time: lease_policy.grace_time
          }
          options_for_ip_lease[:uuid] = options[:ip_lease_uuid] if options[:ip_lease_uuid]

          ip_lease = nil

          transaction do
            if interface = model_class(:interface)[options[:interface_uuid]]
              if (ml_array = interface.mac_leases).empty?
                raise "Cannot create IP lease because interface #{interface.uuid} does not have a MAC lease"
              end

              model_class(:lease_policy_base_interface).create(
                :lease_policy_id => lease_policy.id,
                :interface_id => interface.id
              )

              options_for_ip_lease[:mac_lease_id] = ml_array.first.id
            end

            ip_lease = IpLease.create(options_for_ip_lease)
          end

          ip_lease
        end
      end

      def schedule(network, ip_range_group)
        # TODO: consider how to filter for addresses dynamically assigned
        latest_ip = model_class(:ip_address).order(:updated_at.desc).first
        ipaddr = latest_ip.nil? ? nil : latest_ip.ipv4_address
        leaseaddr = case ip_range_group.allocation_type
                    when ALLOCATION_TYPE_INCREMENTAL
                      get_lease_address(network, ip_range_group, from_ipaddr: ipaddr) ||
                        get_lease_address(network, ip_range_group, to_ipaddr: ipaddr)
                    when ALLOCATION_TYPE_DECREMENTAL
                      get_lease_address(network, ip_range_group, to_ipaddr: ipaddr, order: :desc) ||
                        get_lease_address(network, ip_range_group, from_ipaddr: ipaddr, order: :desc)
                    when ALLOCATION_TYPE_RANDOM
                      raise NotImplementedError
                    else
                      raise "Unsupported IP address assignment: #{ip_range_group.allocation_type}"
                    end
        if leaseaddr.nil?
          netstr = IPAddress::IPv4.parse_u32(network.ipv4_network, network.ipv4_prefix).to_string
          raise "Run out of dynamic IP addresses from the network segment: #{network.uuid}, #{netstr}"
        end
        leaseaddr
      end

      def get_lease_address(network, ip_range_group, options = {})
        from_ipaddr = options[:from_ipaddr] || 0
        to_ipaddr = options[:to_ipaddr] || 0xFFFFFFFF
        order = options[:order] || :asc
        raise ArgumentError unless from_ipaddr.is_a?(Integer)
        raise ArgumentError unless to_ipaddr.is_a?(Integer)

        range_order = {
          :asc => :begin_ipv4_address.asc,
          :desc => :end_ipv4_address.desc,
        }[order]

        network_ip_address = IPAddress::IPv4::parse_u32(network.ipv4_network, network.ipv4_prefix)
        ip_range_group.ip_ranges_dataset.containing_range(from_ipaddr, to_ipaddr).order(range_order).all.each do |i|
          from = [from_ipaddr, network_ip_address.first.to_i, i.begin_ipv4_address].max
          to = [to_ipaddr, network_ip_address.last.to_i, i.end_ipv4_address].min

          # no ip address is assigined
          return if from > to

          i.available_ip(network.id, from, to, order).tap do |leaseaddr|
            return leaseaddr if leaseaddr
          end
        end

        return
      end

      def add_ip_lease_container(uuid, ip_lease_container_uuid)
        lease_policy = model_class[uuid]
        ip_lease_container = model_class(:ip_lease_container)[ip_lease_container_uuid]
        model = nil
        transaction do
          model = model_class(:lease_policy_ip_lease_container).create(
            lease_policy_id: lease_policy.id,
            ip_lease_container_id: ip_lease_container.id
          )
        end
        model
      end

      def remove_ip_lease_container(uuid, ip_lease_container_uuid)
        lease_policy = model_class[uuid]
        ip_lease_container = model_class(:ip_lease_container)[ip_lease_container_uuid]
        model = nil
        transaction do
          model = model_class(:lease_policy_ip_lease_container).find(
            lease_policy_id: lease_policy.id,
            ip_lease_container_id: ip_lease_container.id
          )
          model.destroy
        end
        model
      end
    end
  end
end
