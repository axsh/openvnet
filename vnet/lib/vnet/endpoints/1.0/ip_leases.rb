# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_leases' do
  put_post_shared_params = [
    "network_uuid",
    "mac_lease_uuid",
    "ipv4_address",
  ]

  fill_options = [:mac_lease, :interface, { :ip_address => :network }]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["network_uuid", "mac_lease_uuid", "ipv4_address"]

    post_new(:IpLease, accepted_params, required_params, fill_options) { |params|
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id")
      check_syntax_and_get_id(M::MacLease, params, "mac_lease_uuid", "mac_lease_id")
      params['ipv4_address'] = parse_ipv4(params['ipv4_address'])
    }
  end

  get do
    get_all(:IpLease, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:IpLease, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid_with_node_api(:IpLease)
  end

  put '/:uuid' do
    update_by_uuid_with_node_api(:IpLease, put_post_shared_params, fill_options) { |params|
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id") if params["network_uuid"]
      check_syntax_and_get_id(M::MacLease, params, "mac_lease_uuid", "mac_lease_id") if params["mac_lease_uuid"]
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params['ipv4_address']
    }
  end
end
