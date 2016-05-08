# -*- coding: utf-8 -*-

module Vnet::Models
  class MacLease < Base
    taggable 'ml'

    plugin :paranoia_is_deleted
    plugin :mac_address

    many_to_one :interface
    one_to_many :ip_leases

    plugin :association_dependencies,
    # 0001_origin
    ip_leases: :destroy,
    _mac_address: :destroy

    def cookie_id
      self.class.with_deleted.where(interface_id: self.interface_id).where("id <= ?", self.id).count
    end

  end
end
