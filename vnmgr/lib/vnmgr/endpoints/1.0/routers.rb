# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/routers' do

  post do
    params = parse_params(@params, ["uuid","network_id","ipv4_address","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::Router[params["uuid"]].nil?
      params["uuid"] = M::Router.trim_uuid(params["uuid"])
    end
    router = M::Router.create(params)
    respond_with(R::Router.generate(router))
  end

  get do
    routers = M::Router.all
    respond_with(R::RouterCollection.generate(routers))
  end

  get '/:uuid' do
    router = M::Router[@params["uuid"]]
    respond_with(R::Router.generate(router))
  end

  delete '/:uuid' do
    router = M::Router.destroy(@params["uuid"])
    respond_with(R::Router.generate(router))
  end

  put '/:uuid' do
    params = parse_params(@params, ["network_id","ipv4_address","created_at","updated_at"])
    router = M::Router.update(@params["uuid"], params)
    respond_with(R::Router.generate(router))
  end
end
