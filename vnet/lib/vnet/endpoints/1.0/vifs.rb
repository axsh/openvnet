# -*- coding: utf-8 -*-

require 'trema/mac'

Vnet::Endpoints::V10::VnetAPI.namespace '/vifs' do
  put_post_shared_params = [
    "network_uuid",
    "mac_addr",
    "owner_datapath_uuid",
    "ipv4_address",
    "mode",
  ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["mac_addr"]

    post_new(:Vif, accepted_params, required_params) { |params|
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params["ipv4_address"]
      params['mac_addr'] = parse_mac(params['mac_addr'])
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id") if params["network_uuid"]
      check_syntax_and_get_id(M::Datapath, params, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]
    }
  end

  get do
    get_all(:Vif)
  end

  get '/:uuid' do
    get_by_uuid(:Vif)
  end

  delete '/:uuid' do
    delete_by_uuid(:Vif)
  end

  put '/:uuid' do
    update_by_uuid(:Vif, put_post_shared_params) { |params|
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params["ipv4_address"]
      params['mac_addr'] = parse_mac(params['mac_addr']) if params["ipv4_address"]
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id") if params["network_uuid"]
      check_syntax_and_get_id(M::Datapath, params, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]
    }
  end
end
