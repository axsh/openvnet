# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/lease_policies' do
  put_post_shared_params = ["mode"]

  fill_options = [ ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["mode"]

    post_new(:LeasePolicy, accepted_params, required_params, fill_options) { |params|
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

    }
  end
end
