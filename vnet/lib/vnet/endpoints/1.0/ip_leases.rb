# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_leases' do
  put_post_shared_params = [
    #"network_uuid",
    "vif_uuid",
    "ipv4_address",
    "alloc_type"
  ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    #required_params = ["network_uuid", "vif_uuid", "ip_address_uuid"]
    required_params = ["vif_uuid", "ipv4_address"]

    post_new(:IpLease, accepted_params, required_params) { |params|
      #check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id")
      check_syntax_and_get_id(M::Interface, params, "vif_uuid", "interface_id")
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params['ipv4_address']
    }
  end

  get do
    get_all(:IpLease)
  end

  get '/:uuid' do
    get_by_uuid(:IpLease)
  end

  delete '/:uuid' do
    delete_by_uuid_with_node_api(:IpLease)
  end

  put '/:uuid' do
    update_by_uuid_with_node_api(:IpLease, put_post_shared_params) { |params|
      #check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id") if params["network_uuid"]
      check_syntax_and_get_id(M::Interface, params, "vif_uuid", "interface_id") if params["vif_uuid"]
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params['ipv4_address']
    }
  end
end
