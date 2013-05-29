# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/networks' do
  post do
    params = parse_params(@params, ["uuid","display_name","ipv4_network","ipv4_prefix","domain_name","dc_network_uuid","network_mode","editable"])

    if params.has_key?("uuid")
      #TODO: Check UUID format without connecting to DB

      #TODO: Only allow admin accounts to set UUID. We can't have people keep trying to get these errors to learn what's in the database
      raise E::DuplicateUUID, params["uuid"] unless M::Network[params["uuid"]].nil?

      params["uuid"] = M::Network.trim_uuid(params["uuid"])
    end
    #TODO: Validate all parameters

    nw = data_access.network.create(params)

    respond_with(R::Network.generate(nw))
  end

  get do
    networks = data_access.network.all
    respond_with(R::NetworkCollection.generate(networks))
  end

  get '/:uuid' do
    #TODO: Make sure that this uuid is a network and not something else
    nw = data_access.network[@params["uuid"]]
    raise E::UnknownUUIDResource if nw.blank?
    respond_with(R::Network.generate(nw))
  end

  delete '/:uuid' do
    #TODO: Make sure that this uuid is a network and not something else
    #TODO: Make sure that this uuid exists

    nw = data_access.network.destroy(@params["uuid"])
    respond_with(R::Network.generate(nw))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","display_name","ipv4_network","ipv4_prefix","domain_name","dc_network_uuid","network_mode","editable"])
    nw = data_access.network.update(params[:uuid], params)
    respond_with(R::Network.generate(nw))
  end

  put '/:uuid/attach_vif' do
    params = parse_params(@params, ["uuid","vif_uuid"])
    nw = data_access.network.attach_vif(params[:uuid], params[:vif_uuid])
    respond_with(R::Network.generate(nw))
  end

  put '/:uuid/detach_vif' do
    params = parse_params(@params, ["uuid","vif_uuid"])

    nw = data_access.network.detach_vif(params[:uuid], params[:vif_uuid])
    respond_with(R::Network.generate(nw))
  end
end
