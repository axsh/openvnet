# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_addresses' do
  put_post_shared_params = [
    "ipv4_address"
  ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["ipv4_address"]

    post_new(:IpAddress, accepted_params, required_params) { |params|
      params['ipv4_address'] = parse_ipv4(params['ipv4_address'])
    }
  end

  get do
    get_all(:IpAddress)
  end

  get '/:uuid' do
    get_by_uuid(:IpAddress)
  end

  delete '/:uuid' do
    delete_by_uuid(:IpAddress)
  end

  put '/:uuid' do
    update_by_uuid(:IpAddress, put_post_shared_params) { |params|
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params['ipv4_address']
    }
  end
end
