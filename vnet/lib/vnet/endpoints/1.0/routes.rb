# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/routes' do

  post do
    params = parse_params(@params, ["uuid", "vif_uuid", "route_link_uuid",
      "ipv4_address", "ipv4_prefix", "ingress", "egress"])
    required_params(params, ["ipv4_address", "route_link_uuid"])
    check_and_trim_uuid(M::Route, params) if params.has_key?("uuid")

    check_syntax_and_get_id(M::Route, params, "vif_uuid", "vif_id") if params["vif_uuid"]
    check_syntax_and_get_id(M::RouteLink, params, "route_link_uuid", "route_link_id")

    params['ipv4_address'] = parse_ipv4(params['ipv4_address'])
    params['ipv4_prefix'] = params['ipv4_prefix'].to_i if params['ipv4_prefix']

    params['ingress'] = params['ingress'].to_i if params['ingress']
    params['egress'] = params['egress'].to_i if params['egress']

    route = M::Route.create(params)
    respond_with(R::Route.generate(route))
  end

  get do
    get_all(:Route)
  end

  get '/:uuid' do
    route = check_syntax_and_pop_uuid(M::Route, @params)
    respond_with(R::Route.generate(route))
  end

  delete '/:uuid' do
    delete_by_uuid(M::Route)
  end

  put '/:uuid' do
    params = parse_params(@params, ["ipv4_address", "ipv4_prefix", "vif_uuid",
      "route_link_uuid", "uuid"])
    route = check_syntax_and_pop_uuid(M::Route, params)

    params['ipv4_address'] = parse_ipv4(params['ipv4_address'])
    params['ipv4_prefix'] = params['ipv4_prefix'].to_i if params['ipv4_prefix']

    route.batch.update(params).commit
    updated_route = M::Route[@params["uuid"]]
    respond_with(R::Route.generate(updated_route))
  end
end
