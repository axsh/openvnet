# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/routes' do
  def self.put_post_shared_params
    param :ipv4_network, :String, transform: PARSE_IPV4
    param :ipv4_prefix, :Integer, in: 0..32
    param_uuid M::Interface, :interface_uuid
    param_uuid M::Network, :network_uuid
    param_uuid M::RouteLink, :route_link_uuid
  end

  put_post_shared_params
  param_uuid M::Route
  param_options :interface_uuid, required: true
  param_options :network_uuid, required: true
  param_options :route_link_uuid, required: true
  param_options :ipv4_network, required: true
  param :ingress, :Boolean
  param :egress, :Boolean
  post do
    uuid_to_id(M::Interface, "interface_uuid", "interface_id")
    uuid_to_id(M::Network, "network_uuid", "network_id")
    uuid_to_id(M::RouteLink, "route_link_uuid", "route_link_id")

    post_new(:Route)
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

  put_post_shared_params
  put '/:uuid' do
    check_syntax_and_get_id(M::Interface, "interface_uuid", "interface_id") if params["interface_uuid"]
    check_syntax_and_get_id(M::Network,   "network_uuid", "network_id") if params["network_uuid"]
    check_syntax_and_get_id(M::RouteLink, "route_link_uuid", "route_link_id") if params["route_link_uuid"]
    update_by_uuid(:Route)
  end
end
