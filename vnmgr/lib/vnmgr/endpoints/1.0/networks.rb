# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/networks' do
  post do
    possible_params = ["uuid","display_name","ipv4_network","ipv4_prefix","domain_name","dc_network_uuid","network_mode","editable"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    if params.has_key?("uuid")
      #TODO: Check UUID format without connecting to DB

      #TODO: Only allow admin accounts to set UUID. We can't have people keep trying to get these errors to learn what's in the database
      raise E::DuplicateUUID, params["uuid"] unless M::Network[params["uuid"]].nil?

      params["uuid"] = M::Network.trim_uuid(params["uuid"])
    end
    #TODO: Validate all parameters

    nw = sb.network.create(params)

    respond_with(R::Network.generate(nw))
  end

  get do
    networks = sb.network.get_all
    respond_with(R::NetworkCollection.generate(networks))
  end

  get '/:uuid' do
    #TODO: Make sure that this uuid is a network and not something else
    nw = sb.network.get(@params["uuid"])
    respond_with(R::Network.generate(nw))
  end

  delete '/:uuid' do
    #TODO: Make sure that this uuid is a network and not something else
    #TODO: Make sure that this uuid exists
    sb.network.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    nw = sb.network.update(new_params)
    respond_with(R::Network.generate(nw))
  end

  put '/:uuid/attach_vif' do
    tmp_params = filter_params(params)
    av_params = parse_params(tmp_params, {
      'uuid' => [String],
      'vif_uuid' => [String]
    })

    nw = sb.network.attach_vif(av_params)
    respond_with(R::Network.generate(nw))
  end

  put '/:uuid/detach_vif' do
    tmp_params = filter_params(params)
    dv_params = define_params(tmp_params,{
      'uuid' => [String],
      'vif_uuid' => [String]
    })

    nw = sb.network.attach_vif(dv_params)
    respond_with(R::Network.generate(nw))
  end
end
