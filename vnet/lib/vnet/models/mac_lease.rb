# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class MacLease < Base
    taggable 'ml'

    plugin :paranoia
    plugin :mac_address

    many_to_one :interface
    one_to_many :ip_leases

    plugin :association_dependencies,
      :ip_leases => :destroy

    def cookie_id
      self.class.with_deleted.where(interface_id: self.interface_id).where("id <= #{self.id}").count
    end

    def to_hash
      super.merge({
        mac_address: self.mac_address
      })
    end
  end
end
