# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/routers' do

  post do
    possible_params = ["uuid","network_id","ipv4_address","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    router = sb.router.create(params)
    respond_with(R::Router.generate(router))
  end

  get do
    routers = sb.router.get_all
    respond_with(R::RouterCollection.generate(routers))
  end

  get '/:uuid' do
    router = sb.router.get(@params["uuid"])
    respond_with(R::Router.generate(router))
  end

  delete '/:uuid' do
    sb.router.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    router = sb.router.update(new_params)
    respond_with(R::Router.generate(router))
  end
end
