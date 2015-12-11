# -*- coding: utf-8 -*-

module Vnet::Services::Topologies

  class SimpleOverlay < Base
    include Celluloid::Logger

    def log_type
      'topology/simple_overlay'
    end

    def create_dp_generic(params)
      object_id = get_param_id(params, :object_id)
      datapath_id = get_param_id(params, :datapath_id)

      interface_id = get_a_host_interface_id(datapath_id)

      if interface_id.nil?
        # TODO: This shows network.
        warn log_format_dn("create_datapath_generic could not find host interface", datapath_id, object_id)
        return
      end

      case get_param_symbol(params, :type)
      when :network
        create_datapath_network(datapath_id, object_id, interface_id)
      else
        throw_param_error("unknown type", params, :type)
      end
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
        debug log_format_dp_nw_if("created datapath_network", datapath_id, network_id, interface_id)
      else
        info log_format_dp_nw_if("failed to create datapath_network", datapath_id, network_id, interface_id)
      end
    end

    def get_a_host_interface_id(datapath_id)
      filter = {
        datapath_id: datapath_id,
        interface_mode: Vnet::Constants::Interface::MODE_HOST
      }

      interface = MW::InterfacePort.batch.dataset.where(filter).first.commit

      debug log_format("get_a_host_interface", interface.inspect)

      interface.interface_id
    end

  end

end
