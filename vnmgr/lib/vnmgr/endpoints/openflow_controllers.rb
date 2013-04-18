# -*- coding: utf-8 -*-

Vnmgr::Endpoints::VNetAPI.namespace '/openflow_controllers' do
  post do
    ofc_params = define_params(params,{
      :uuid => [String,nil],
      :ipv4 => [Integer],
      :port => [Integer]
    })

    # Respond with this openflow_controller
  end

  get do
    # Respond with all openflow_controllers
  end

  get '/:uuid' do
    ofc_params = define_params(params,{:uuid => [String]})
    # Respond with a single openflow_controller
  end

  delete '/:uuid' do
    ofc_params = define_params(params,{:uuid => [String]})
    # Delete a single openflow_controller

    # Respond with openflow_controller id
  end

  put '/:uuid' do
    # Get openflow_controller from dba
    ofc_params = define_params(params,{
      :uuid => [String],
      :ipv4 => [Integer],
      :port => [Integer]
    })

    # use these params to update the openflow_controller and send it back to dba for storage

    # Respond with the modified openflow_controller
  end

  put '/:uuid/assign_datapath' do
      ofc_params = define_params(params,{
        :uuid => [String],
        :datapath_uuid => [String]
      })

      # Respond with the openflow_controller
  end

  put '/:uuid/unassign_datapath' do
      ofc_params = define_params(params,{
        :uuid => [String],
        :datapath_uuid => [String]
      })

      # Respond with the openflow_controller
  end
end
