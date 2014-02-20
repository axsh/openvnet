# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Interface < Vnet::Endpoints::ResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::Interface)
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
      object.owner_datapath_uuid = object.owner_datapath.uuid if object.owner_datapath
      object.to_hash
    end

    def self.security_groups(interface)
      argument_type_check(interface, Vnet::ModelWrappers::Interface)
      SecurityGroupCollection.generate(interface.batch.security_groups.commit)
    end
  end

  class InterfaceCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        Interface.generate(i)
      }
    end
  end


end
