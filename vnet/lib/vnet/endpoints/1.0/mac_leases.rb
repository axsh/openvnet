# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/mac_leases' do
  put_post_shared_params = ["interface_uuid", "mac_address"]

  fill_options = [:interface, :mac_address]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["interface_uuid", "mac_address"]

    post_new(:MacLease, accepted_params, required_params, fill_options) { |params|
      check_syntax_and_get_id(M::Interface, params, "interface_uuid", "interface_id")
      params['mac_address'] = parse_mac(params['mac_address'])
    }
  end

  get do
    get_all(:MacLease, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:MacLease, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:MacLease)
  end

  put '/:uuid' do
    update_by_uuid(:MacLease, put_post_shared_params, fill_options) { |params|
      check_syntax_and_get_id(M::Interface, params, "interface_uuid", "interface_id") if params["interface_uuid"]
      params['mac_address'] = parse_mac(params['mac_address']) if params['mac_address']
    }
  end
end
