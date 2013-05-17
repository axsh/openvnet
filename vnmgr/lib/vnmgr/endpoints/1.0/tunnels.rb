# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/tunnels' do

  post do
    possible_params = ["uuid","src_network_id","dst_network_id","tunnel_id","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    tunnel = SB.tunnel.create(params)
    respond_with(R::Tunnel.generate(tunnel))
  end

  get do
    tunnels = SB.tunnel.get_all
    respond_with(R::TunnelCollection.generate(tunnels))
  end

  get '/:uuid' do
    tunnel = SB.tunnel.get(@params["uuid"])
    respond_with(R::Tunnel.generate(tunnel))
  end

  delete '/:uuid' do
    SB.tunnel.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    tunnel = SB.tunnel.update(new_params)
    respond_with(R::Tunnel.generate(tunnel))
  end
end
