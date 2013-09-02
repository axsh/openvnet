# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/routes' do

  post do
    accepted_params = [
      "uuid",
      "vif_uuid",
      "route_link_uuid",
      "ipv4_address",
      "ipv4_prefix",
      "ingress",
      "egress"
    ]
    required_params = ["ipv4_address", "route_link_uuid"]

    post_new(:Route, accepted_params, required_params) { |params|
      params['ipv4_address'] = parse_ipv4(params['ipv4_address'])
      params['ipv4_prefix'] = params['ipv4_prefix'].to_i if params['ipv4_prefix']
      check_syntax_and_get_id(M::Vif, params, "vif_uuid", "vif_id") if params["vif_uuid"]
      check_syntax_and_get_id(M::RouteLink, params, "route_link_uuid", "route_link_id")
    }
  end

  get do
    get_all(:Route)
  end

  get '/:uuid' do
    get_by_uuid(:Route)
  end

  delete '/:uuid' do
    delete_by_uuid(:Route)
  end

  put '/:uuid' do
    accepted_params = [
      "ipv4_address",
      "ipv4_prefix",
      "vif_uuid",
      "route_link_uuid"
    ]

    update_by_uuid(:Route, accepted_params) { |params|
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params["ipv4_address"]
      params['ipv4_prefix'] = params['ipv4_prefix'].to_i if params['ipv4_prefix']
      check_syntax_and_get_id(M::Vif, params, "vif_uuid", "vif_id") if params["vif_uuid"]
      check_syntax_and_get_id(M::RouteLink, params, "route_link_uuid",
        "route_link_id") if params["route_link_uuid"]
    }
  end
end
