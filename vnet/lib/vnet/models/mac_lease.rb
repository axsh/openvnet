# -*- coding: utf-8 -*-

module Vnet::Models
  class MacLease < Base
    taggable 'ml'

    plugin :paranoia_is_deleted
    plugin :mac_address

    # one_to_one :mac_address

    many_to_one :interface
    one_to_many :ip_leases

    plugin :association_dependencies,
    # 0001_origin
    ip_leases: :destroy
    # mac_address: :destroy

    def cookie_id
      self.class.with_deleted.where(interface_id: self.interface_id).where("id <= #{self.id}").count
    end

    def to_hash
      super.merge(mac_address: self.mac_address)
    end

  end
end
