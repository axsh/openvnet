# -*- coding: utf-8 -*-

require 'ipaddr'

Vnet::Endpoints::V10::VnetAPI.namespace '/networks' do
  post do
    accepted_params = [
      "uuid",
      "display_name",
      "ipv4_network",
      "ipv4_prefix",
      "domain_name",
      "dc_network_uuid",
      "network_mode",
      "editable"
    ]
    required_params = ["display_name", "ipv4_network"]

    post_new(:Network, accepted_params, required_params) { |params|
      params["ipv4_network"] = parse_ipv4(params["ipv4_network"]) if params.has_key?("ipv4_network")
      check_syntax_and_get_id(M::DcNetwork, params, "dc_network", "dc_network_id") if params["dc_network_uuid"]
    }
  end

  get do
    get_all(:Network)
  end

  get '/:uuid' do
    get_by_uuid(:Network)
  end

  delete '/:uuid' do
    delete_by_uuid(:Network)
  end

  put '/:uuid' do
    update_by_uuid(:Network, [
      "display_name",
      "ipv4_network",
      "ipv4_prefix",
      "domain_name",
      "dc_network_uuid",
      "network_mode",
      "editable"
    ]) { |params|
      params["ipv4_network"] = parse_ipv4(params["ipv4_network"]) if params.has_key?("ipv4_network")
      check_syntax_and_get_id(M::DcNetwork, params, "dc_network", "dc_network_id") if params["dc_network_uuid"]
    }
  end
end
