# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/mac_leases' do
  put_post_shared_params = ["mac_address"]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["mac_address"]

    post_new(:MacLease, accepted_params, required_params) { |params|
      params['mac_address'] = parse_mac(params['mac_address'])
    }
  end

  get do
    get_all(:MacLease)
  end

  get '/:uuid' do
    get_by_uuid(:MacLease)
  end

  delete '/:uuid' do
    delete_by_uuid(:MacLease)
  end

  put '/:uuid' do
    update_by_uuid(:MacLease, put_post_shared_params) { |params|
      params['mac_address'] = parse_mac(params['mac_address']) if params['mac_address']
    }
  end
end
