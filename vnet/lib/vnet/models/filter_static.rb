# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class FilterStatic < Base

    many_to_one :filter
    # TODO: Association needed:

    def ipv4_src_address_s
      self.ipv4_src_address && parse_ipv4(self.ipv4_src_address)
    end

    def ipv4_dst_address_s
      self.ipv4_dst_address && parse_ipv4(self.ipv4_dst_address)
    end

    def validate
      errors.add(:ipv4_src_prefix, "prefix out of range") if !(0..32).member?(self.ipv4_src_prefix)
      errors.add(:ipv4_dst_prefix, "prefix out of range") if !(0..32).member?(self.ipv4_dst_prefix)

      if protocol_included(["tcp", "udp"])
        errors.add(:port_src_first, "port not in valid range") if !(0..0xffff).member?(self.port_src_first)
        errors.add(:port_dst_first, "port not in valid range") if !(0..0xffff).member?(self.port_dst_first)
        errors.add(:port_src_last, "port not in valid range") if !(self.port_src_first..0xffff).member?(self.port_src_last)
        errors.add(:port_dst_last, "port not in valid range") if !(self.port_dst_first..0xffff).member?(self.port_dst_last)
      elsif protocol_included(["arp", "icmp", "all"])
        errors.add(:port_src_first, "port needs to be nil") if !self.port_src_first.nil?
        errors.add(:port_dst_first, "port needs to be nil") if !self.port_dst_first.nil?
        errors.add(:port_src_last, "port needs to be nil") if !self.port_dst_last.nil?
        errors.add(:port_dst_last, "port needs to be nil") if !self.port_src_last.nil?
      elsif protocol_included(["arp", "all"])
        errors.add(:ipv4_src_address, "ip address needs to be 0") if (self.ipv4_src_address > 0) # needs inspection
        errors.add(:ipv4_dst_address, "ip address needs to be 0") if (self.ipv4_dst_address > 0) # needs inspection
      end

      errors.add(:ipv4_dst_prefix, "prefix needs to be 0") if ipv4_dst_prefix != 0 && self.ipv4_dst_address == 0
      errors.add(:ipv4_src_prefix, "prefix needs to be 0") if ipv4_src_prefix != 0 && self.ipv4_src_address == 0
    end

    private

    def parse_ipv4(ipv4)
      IPAddress::IPv4::parse_u32(ipv4).to_s
    end

    def protocol_included(protocols = [])
      return protocols.include? self.protocol
    end

  end

end
