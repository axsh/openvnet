# -*- coding: utf-8 -*-

module Vnet::Core::InterfaceNetworks

  class Base < Vnet::ItemDpId
    attr_reader :interface_id
    attr_reader :network_id

    attr_accessor :static

    def initialize(params)
      super

      map = params[:map]

      @interface_id = get_param_id(map, :interface_id)
      @network_id = get_param_id(map, :network_id)
      @static = get_param_bool(map, :static)
    end

    def mode
      :base
    end

    def log_type
      'interface_network/base'
    end

    def pretty_id
      "#{mode}/#{id}"
    end

    def pretty_properties
      "interface_id:#{@interface_id} network_id:#{@network_id}" + (@static ? ' static' : '')
    end

    def install
      @dp_info.network_manager.insert_interface_network(@interface_id, @network_id)
    end

    def uninstall
      @dp_info.network_manager.remove_interface_network(@interface_id, @network_id)
    end

    def to_hash
      Vnet::Core::InterfaceNetwork.new(
        id: @id,
        interface_id: @interface_id,
        network_id: @network_id,
        static: @static
      )
    end

  end

end
