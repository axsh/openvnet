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

  put '/:uuid/associate_network' do
    # TODO: it is now possible to associate twice....probably should not allow that.
    params = parse_params(@params, ['uuid', 'network_uuid'])
    check_required_params(params, ['network_uuid'])

    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy, params)
    # TODO: verify this next line is not just a hack (that does work, so far)
    network = check_syntax_and_pop_uuid(M::Network, { "uuid" => params[:network_uuid] } )

    M::LeasePolicyBaseNetwork.create({ :network_id => network.id,
                                       :lease_policy_id => lease_policy.id
                                     })
    respond_with(R::LeasePolicy.lease_policy_network(lease_policy))
  end

end
