# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/routes' do
  param_uuid M::Route
  param_uuid M::Interface, :interface_uuid, required: true
  param_uuid M::Network, :network_uuid, required: true
  param_uuid M::RouteLink, :route_link_uuid, required: true
  param :ipv4_network, :String, transform: PARSE_IPV4, required: true
  param :ipv4_prefix, :Integer, in: 0..32
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

end
