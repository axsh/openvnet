# -*- coding: utf-8 -*-

require 'ipaddr'

Vnet::Endpoints::V10::VnetAPI.namespace '/networks' do
  put_post_shared_params = [
    "display_name",
    "ipv4_network",
    "ipv4_prefix",
    "domain_name",
    "network_mode",
    "editable"
  ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["display_name", "ipv4_network"]

    post_new(:Network, accepted_params, required_params) { |params|
      params["ipv4_network"] = parse_ipv4(params["ipv4_network"]) if params.has_key?("ipv4_network")
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
    update_by_uuid(:Network, put_post_shared_params) { |params|
      params["ipv4_network"] = parse_ipv4(params["ipv4_network"]) if params.has_key?("ipv4_network")
    }
  end
end
