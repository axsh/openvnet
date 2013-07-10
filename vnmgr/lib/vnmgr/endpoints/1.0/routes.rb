# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/routes' do

  post do
    params = parse_params(@params, ["uuid", "vif_uuid", "route_link_uuid", "ipv4_address", "ipv4_prefix"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::Route[params["uuid"]].nil?
      params["uuid"] = M::Route.trim_uuid(params["uuid"])
    end

    vif_uuid = params.delete('vif_uuid') || raise(E::MissingArgument, 'vif_uuid')
    route_link_uuid = params.delete('route_link_uuid') || raise(E::MissingArgument, 'route_link_uuid')

    params['vif_id'] = (M::Vif[vif_uuid] || raise(E::InvalidUUID, vif_uuid)).id
    params['route_link_id'] = (M::RouteLink[route_link_uuid] || raise(E::InvalidUUID, route_link_uuid)).id

    params['ipv4_address'] = parse_ipv4(params['ipv4_address'] || raise(E::MissingArgument, 'ipv4_address'))

    route = M::Route.create(params)
    respond_with(R::Route.generate(route))
  end

  get do
    routes = M::Route.all
    respond_with(R::RouteCollection.generate(routes))
  end

  get '/:uuid' do
    route = M::Route[@params["uuid"]]
    respond_with(R::Route.generate(route))
  end

  delete '/:uuid' do
    route = M::Route.destroy(@params["uuid"])
    respond_with(R::Route.generate(route))
  end

  put '/:uuid' do
    params = parse_params(@params, ["ipv4_address","created_at","updated_at"])
    route = M::Route.update(@params["uuid"], params)
    respond_with(R::Route.generate(route))
  end
end
