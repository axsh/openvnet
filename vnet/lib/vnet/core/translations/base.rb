# -*- coding: utf-8 -*-

module Vnet::Core::Translations

  class Base < Vnet::ItemDpUuid
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :interface_id

    def initialize(params)
      super

      map = params[:map]

      @interface_id = map.interface_id
      @passthrough = map.passthrough == 1
    end

    def log_type
      'translation/base'
    end

    def pretty_properties
      "interface_id:#{@interface_id}" +
        (@passthrough == 1 ? ' passthrough' : '')
    end

    def cookie
      @id | COOKIE_TYPE_TRANSLATION
    end
    
    def cookie_mask
      COOKIE_PREFIX_MASK | COOKIE_ID_MASK
    end

    def to_hash
      Vnet::Core::Translation.new(id: @id,
                                  uuid: @uuid)
    end

    def uninstall
      @dp_info.del_cookie(self.cookie, self.cookie_mask)
    end

    def added_static_address(static_address_id,
                             route_link_id,
                             ingress_ipv4_address,
                             egress_ipv4_address,
                             ingress_port_number,
                             egress_port_number)
    end

    def removed_static_address(static_address_id)
    end

    #
    # Internal methods:
    #

    private

  end

end
