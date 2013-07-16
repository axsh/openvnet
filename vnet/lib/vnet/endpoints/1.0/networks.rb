# -*- coding: utf-8 -*-

require 'ipaddr'

Vnet::Endpoints::V10::VnetAPI.namespace '/networks' do
  post do
    params = parse_params(@params, ["uuid","display_name","ipv4_network","ipv4_prefix","domain_name","dc_network_uuid","network_mode","editable"])

    if params.has_key?("uuid")
      #TODO: Check UUID format without connecting to DB

      #TODO: Only allow admin accounts to set UUID. We can't have people keep trying to get these errors to learn what's in the database
      raise E::DuplicateUUID, params["uuid"] unless M::Network[params["uuid"]].nil?

      params["uuid"] = M::Network.trim_uuid(params["uuid"])
    end
    #TODO: Validate all parameters

    params["ipv4_network"] = parse_ipv4(params["ipv4_network"]) if params.has_key?("ipv4_network")

    nw = M::Network.create(params)

    respond_with(R::Network.generate(nw))
  end

  get do
    networks = M::Network.all
    respond_with(R::NetworkCollection.generate(networks))
  end

  get '/:uuid' do
    #TODO: Make sure that this uuid is a network and not something else
    nw = M::Network[@params["uuid"]]
    raise E::UnknownUUIDResource if nw.blank?
    respond_with(R::Network.generate(nw))
  end

  delete '/:uuid' do
    #TODO: Make sure that this uuid is a network and not something else
    #TODO: Make sure that this uuid exists

    nw = M::Network.batch[@params["uuid"]].destroy.commit
    respond_with(R::Network.generate(nw))
  end

  put '/:uuid' do
    params = parse_params(@params, ["display_name","ipv4_network","ipv4_prefix","domain_name","dc_network_uuid","network_mode","editable"])
    nw = M::Network.batch do |n|
      n[@params[:uuid]].update(params)
    end
    respond_with(R::Network.generate(nw))
  end

  put '/:uuid/attach_vif' do
    nw = M::Network.attach_vif(@params[:uuid], @params[:vif_uuid])
    respond_with(R::Network.generate(nw))
  end

  put '/:uuid/detach_vif' do
        nw = M::Network.detach_vif(@params[:uuid], @params[:vif_uuid])
    respond_with(R::Network.generate(nw))
  end
end
