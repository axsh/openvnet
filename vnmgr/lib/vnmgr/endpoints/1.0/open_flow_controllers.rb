# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/open_flow_controllers' do

  post do
    possible_params = ["uuid","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    open_flow_controller = sb.open_flow_controller.create(params)
    respond_with(R::OpenFlowController.generate(open_flow_controller))
  end

  get do
    open_flow_controllers = sb.open_flow_controller.get_all
    respond_with(R::OpenFlowControllerCollection.generate(open_flow_controllers))
  end

  get '/:uuid' do
    open_flow_controller = sb.open_flow_controller.get(@params["uuid"])
    respond_with(R::OpenFlowController.generate(open_flow_controller))
  end

  delete '/:uuid' do
    sb.open_flow_controller.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    open_flow_controller = sb.open_flow_controller.update(new_params)
    respond_with(R::OpenFlowController.generate(open_flow_controller))
  end
end
