# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/routers' do

  post do
    params = parse_params(@params, ["uuid","network_id","ipv4_address","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::Router[params["uuid"]].nil?
      params["uuid"] = M::Router.trim_uuid(params["uuid"])
    end
    router = sb.router.create(params)
    respond_with(R::Router.generate(router))
  end

  get do
    routers = sb.router.all
    respond_with(R::RouterCollection.generate(routers))
  end

  get '/:uuid' do
    router = sb.router[{:uuid => @params["uuid"]}]
    respond_with(R::Router.generate(router))
  end

  delete '/:uuid' do
    router = sb.router.delete({:uuid => @params["uuid"]})
    respond_with(R::Router.generate(router))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","network_id","ipv4_address","created_at","updated_at"])
    router = sb.router.update(params)
    respond_with(R::Router.generate(router))
  end
end
