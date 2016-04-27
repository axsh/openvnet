# -*- coding: utf-8 -*-

module Vnet::Services::Topologies

  class Base < Vnet::ItemVnetUuid
    include Celluloid::Logger

    def initialize(params)
      super

      map = params[:map]
    end    
    
    def log_type
      'topology/base'
    end

    def to_hash
      Vnet::Core::Topology.new(id: @id,
                               uuid: @uuid)
    end

    #
    # Events:
    #

    def install
    end

    def uninstall
    end

    #
    # Internal methods:
    #

    private

    def create_datapath_network(datapath_id, network_id, interface_id)
      create_params = {
        datapath_id: datapath_id,
        network_id: network_id,
        interface_id: interface_id
      }

      if MW::DatapathNetwork.batch.create(create_params).commit
        debug log_format_h("created datapath_network", create_params)
      else
        info log_format_h("failed to create datapath_network", create_params)
      end
    end

    def create_datapath_route_link(datapath_id, route_link_id, interface_id)
      create_params = {
        datapath_id: datapath_id,
        route_link_id: route_link_id,
        interface_id: interface_id
      }

      if MW::DatapathRouteLink.batch.create(create_params).commit
        debug log_format_h("created datapath_route_link", create_params)
      else
        info log_format_h("failed to create datapath_route_link", create_params)
      end
    end

    # Ugly but simple way of getting a host interface.
    def get_a_host_interface_id(datapath_id)
      filter = {
        datapath_id: datapath_id,
        interface_mode: Vnet::Constants::Interface::MODE_HOST
      }

      interface = MW::InterfacePort.batch.dataset.where(filter).first.commit

      debug log_format("get_a_host_interface", interface.inspect)

      interface && interface.interface_id
    end

  end

end
