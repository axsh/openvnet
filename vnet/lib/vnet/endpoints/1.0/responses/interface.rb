# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Interface < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Interface)
      object.mac_leases = [] unless object.mac_leases
      if object.mac_leases.first
        object.mac_address = object.mac_leases.first.mac_address_s
      end
      object.mac_leases = object.mac_leases.map do |mac_lease|
        if mac_lease.ip_leases.first
          object.network_uuid = mac_lease.ip_leases.first.ip_address.network.uuid
          object.ipv4_address = mac_lease.ip_leases.first.ip_address.ipv4_address_s
        end
        mac_lease.ip_leases = mac_lease.ip_leases.map do |ip_lease|
          ip_lease.interface_uuid = object.uuid
          ip_lease.mac_lease_uuid = mac_lease.uuid
          IpLease.generate(ip_lease)
        end

        # just for compatibility
        # TODO remove it when unnecessary
        object.ip_leases = mac_lease.ip_leases

        mac_lease.interface_uuid = object.uuid
        MacLease.generate(mac_lease)
      end

      object.to_hash
    end
  end

  class InterfaceCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Interface.generate(i)
      }
    end
  end

  class InterfaceSegment < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(route)
      argument_type_check(route, Vnet::ModelWrappers::InterfaceSegment)
      route.to_hash
    end
  end

  class InterfaceSegmentCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| InterfaceSegment.generate(i) }
    end
  end

end
