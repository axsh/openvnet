# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/networks' do
  post do
    possible_params = ["uuid","display_name","ipv4_network","ipv4_prefix","domain_name","dc_network_uuid","network_mode","editable"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}

    if params.has_key?("uuid")
      #TODO: Check UUID format without connecting to DB

      #TODO: Only allow admin accounts to set UUID. We can't have people keep trying to get these errors to learn what's in the database
      raise E::DuplicateUUID, params["uuid"] unless M::Network[params["uuid"]].nil?

      params["uuid"] = M::Network.trim_uuid(params["uuid"])
    end
    #TODO: Validate all parameters

    nw = SB.create(:Network,params.to_json)

    respond_with(R::Network.generate(nw))
  end

  get do
    networks = SB.get_all(:Network)
    respond_with(R::NetworkCollection.generate(networks))
  end

  get '/:uuid' do
    #TODO: Make sure that this uuid is a network and not something else
    nw = SB.get(@params["uuid"])
    respond_with(R::Network.generate(nw))
  end

  delete '/:uuid' do
    #TODO: Make sure that this uuid is a network and not something else
    #TODO: Make sure that this uuid exists
    SB.delete(@params["uuid"])
    respond_with(@params["uuid"])
  end

  put '/:uuid' do
    # Get network from dba
    new_nw_params = define_params(params,{:desciption => [String,nil]})

    #use these params to update the network and send it back to dba for storage

    # Respond with the modified network
  end

  put '/:uuid/attach_vif' do
    av_params = define_params(params,{
      :uuid => [String],
      :vif_uuid => [String],
      :ipv4 => [Int,nil]
    })

    # Respond with network
  end

  put '/:uuid/detach_vif' do
    av_params = define_params(params,{
      :vif_uuid => [String],
    })

    # Respond with network
  end
end
