# -*- coding: utf-8 -*-

require 'ipaddr'

Vnet::Endpoints::V10::VnetAPI.namespace '/networks' do
  post do
    params = parse_params(@params, ["uuid","display_name","ipv4_network","ipv4_prefix","domain_name","dc_network_uuid","network_mode","editable"])
    required_params(params, ["display_name", "ipv4_network"])

    if params.has_key?("uuid")
      check_uuid_syntax(M::Network, params["uuid"])
      raise E::DuplicateUUID, params["uuid"] unless M::Network[params["uuid"]].nil?

      params["uuid"] = M::Network.trim_uuid(params["uuid"])
    end
    #TODO: Validate all parameters

    params["ipv4_network"] = parse_ipv4(params["ipv4_network"]) if params.has_key?("ipv4_network")

    dc_network = if params["dc_network_uuid"]
      dc_network_uuid = params.delete("dc_network_uuid")
      M::DcNetwork[dc_network_uuid] || raise(E::UnknownUUIDResource, dc_network_uuid)
    end

    nw = M::Network.create(params)
    nw.dc_network = dc_network unless dc_network.nil?
    nw.save

    respond_with(R::Network.generate(nw))
  end

  get do
    networks = M::Network.all
    respond_with(R::NetworkCollection.generate(networks))
  end

  get '/:uuid' do
    nw = check_syntax_and_pop_uuid(M::Network, @params)
    respond_with(R::Network.generate(nw))
  end

  delete '/:uuid' do
    nw = check_syntax_and_pop_uuid(M::Network, @params)
    nw.batch.destroy.commit
    respond_with(R::Network.generate(nw))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","display_name","ipv4_network","ipv4_prefix","domain_name","dc_network_uuid","network_mode","editable"])
    nw = check_syntax_and_pop_uuid(M::Network, params)
    nw.batch.update(params).commit

    updated_nw = M::Network[@params["uuid"]]
    respond_with(R::Network.generate(updated_nw))
  end
end
