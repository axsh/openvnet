# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/open_flow_controllers' do

  post do
    params = parse_params(@params, ["uuid","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::OpenFlowController[params["uuid"]].nil?
      params["uuid"] = M::OpenFlowController.trim_uuid(params["uuid"])
    end
    open_flow_controller = M::OpenFlowController.create(params)
    respond_with(R::OpenFlowController.generate(open_flow_controller))
  end

  get do
    open_flow_controllers = M::OpenFlowController.all
    respond_with(R::OpenFlowControllerCollection.generate(open_flow_controllers))
  end

  get '/:uuid' do
    open_flow_controller = M::OpenFlowController[@params["uuid"]]
    respond_with(R::OpenFlowController.generate(open_flow_controller))
  end

  delete '/:uuid' do
    open_flow_controller = M::OpenFlowController.destroy(@params["uuid"])
    respond_with(R::OpenFlowController.generate(open_flow_controller))
  end

  put '/:uuid' do
    params = parse_params(@params, ["created_at","updated_at"])
    open_flow_controller = M::OpenFlowController.update(@param["uuid"], params)
    respond_with(R::OpenFlowController.generate(open_flow_controller))
  end
end
