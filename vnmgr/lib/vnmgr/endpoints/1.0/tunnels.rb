# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/tunnels' do

  post do
    params = parse_params(@params, ["uuid","src_network_uuid","dst_network_uuid","tunnel_id","ttl","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::Tunnel[params["uuid"]].nil?
      params["uuid"] = M::Tunnel.trim_uuid(params["uuid"])
    end
    tunnel = sb.tunnel.create(params)
    respond_with(R::Tunnel.generate(tunnel))
  end

  get do
    tunnels = sb.tunnel.all
    respond_with(R::TunnelCollection.generate(tunnels))
  end

  get '/:uuid' do
    tunnel = sb.tunnel[{:uuid => @params["uuid"]}]
    respond_with(R::Tunnel.generate(tunnel))
  end

  delete '/:uuid' do
    tunnel = sb.tunnel.delete({:uuid => @params["uuid"]})
    respond_with(R::Tunnel.generate(tunnel))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","src_network_uuid","dst_network_uuid","tunnel_id","ttl","created_at","updated_at"])
    tunnel = sb.tunnel.update(params)
    respond_with(R::Tunnel.generate(tunnel))
  end
end
