# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/tunnels' do

  post do
    params = parse_params(@params, ["uuid","src_network_uuid","dst_network_uuid","tunnel_id","ttl","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::Tunnel[params["uuid"]].nil?
      params["uuid"] = M::Tunnel.trim_uuid(params["uuid"])
    end
    tunnel = M::Tunnel.create(params)
    respond_with(R::Tunnel.generate(tunnel))
  end

  get do
    tunnels = M::Tunnel.all
    respond_with(R::TunnelCollection.generate(tunnels))
  end

  get '/:uuid' do
    tunnel = M::Tunnel[@params["uuid"]]
    respond_with(R::Tunnel.generate(tunnel))
  end

  delete '/:uuid' do
    tunnel = M::Tunnel.destroy(@params["uuid"])
    respond_with(R::Tunnel.generate(tunnel))
  end

  put '/:uuid' do
    params = parse_params(@params, ["src_network_uuid","dst_network_uuid","tunnel_id","ttl","created_at","updated_at"])
    tunnel = M::Tunnel.update(@params["uuid"], params)
    respond_with(R::Tunnel.generate(tunnel))
  end
end
