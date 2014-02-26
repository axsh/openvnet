# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/lease_policies' do
  put_post_shared_params = ["interface_uuid", "mac_address"]  # TODO

  fill_options = [:interface, :mac_address]  # TODO

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["interface_uuid", "mac_address"] # TODO

    post_new(:LeasePolicy, accepted_params, required_params, fill_options) { |params|
      check_syntax_and_get_id(M::Interface, params, "interface_uuid", "interface_id") # TODO
      params['mac_address'] = parse_mac(params['mac_address']) # TODO
    }
  end

  get do
    get_all(:LeasePolicy, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:LeasePolicy, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:LeasePolicy)
  end

  put '/:uuid' do
    update_by_uuid(:LeasePolicy, put_post_shared_params, fill_options) { |params|
      check_syntax_and_get_id(M::Interface, params, "interface_uuid", "interface_id") if params["interface_uuid"]
      params['mac_address'] = parse_mac(params['mac_address']) if params['mac_address'] # TODO
    }
  end
end
