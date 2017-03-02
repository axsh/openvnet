# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class FilterStatic < Base
    plugin :paranoia_is_deleted

    many_to_one :filter
    # TODO: Association needed:

    def src_address_s
      self.src_address && parse_ipv4(self.src_address)
    end

    def dst_address_s
      self.dst_address && parse_ipv4(self.dst_address)
    end

    def validate
      errors.add(:src_prefix, "out of range: '") if !(0..32).member?(self.src_prefix)
      errors.add(:dst_prefix, "out of range: '") if !(0..32).member?(self.dst_prefix)
      errors.add(:protocol, "unknown protocol: '") if !protocol_included(Vnet::Constants::FilterStatic::PROTOCOLS)

      if protocol_included(['tcp', 'udp'])
        errors.add(:port_src, "not in valid range: '") if !(0..0xffff).member?(self.port_src)
        errors.add(:port_dst, "not in valid range: '") if !(0..0xffff).member?(self.port_dst)
      elsif protocol_included(['arp', 'icmp', 'ip'])
        errors.add(:port_src, 'needs to be nil') if !self.port_src.nil?
        errors.add(:port_dst, 'needs to be nil') if !self.port_dst.nil?
      elsif protocol_included(['arp', 'ip'])
        errors.add(:src_address, 'address needs to be 0') if (self.src_address > 0) # needs inspection
        errors.add(:dst_address, 'address needs to be 0') if (self.dst_address > 0) # needs inspection
      end

      errors.add(:dst_prefix, 'needs to be 0') if dst_prefix != 0 && self.dst_address == 0
      errors.add(:src_prefix, 'needs to be 0') if src_prefix != 0 && self.src_address == 0
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
