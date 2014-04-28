# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/lease_policies' do
  put_post_shared_params = ["mode", "timing"]

  fill_options = [ ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = [ ]

    post_new(:LeasePolicy, accepted_params, required_params, fill_options) { |params|
      params["mode"] = "simple" if ! params.has_key? "mode"
      params["timing"] = "immediate" if ! params.has_key? "timing"
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

  post '/:uuid/networks/:network_uuid' do
    # TODO: it is now possible to associate twice....probably should not allow that.
    params = parse_params(@params, ['uuid', 'network_uuid', 'ip_range_uuid'])
    check_required_params(params, ['network_uuid', 'ip_range_uuid'])
    
    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy, params)
    # TODO: verify this next line is not just a hack (that does work, so far)
    network = check_syntax_and_pop_uuid(M::Network, { "uuid" => params[:network_uuid] } )
    ip_range = check_syntax_and_pop_uuid(M::IpRange, { "uuid" => params[:ip_range_uuid] } )

    M::LeasePolicyBaseNetwork.create({ :network_id => network.id,
                                       :lease_policy_id => lease_policy.id,
                                       :ip_range_id => ip_range.id
                                     })
    respond_with(R::LeasePolicy.lease_policy_network(lease_policy))
  end

  get '/:uuid/networks' do
    show_relations(:LeasePolicy, :networks)
  end

  delete '/:uuid/networks/:network_uuid' do
    params = parse_params(@params, ['uuid', 'network_uuid'])
    check_required_params(params, ['network_uuid'])

    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy, params)
    network = check_syntax_and_pop_uuid(M::Network, { "uuid" => params[:network_uuid] } )

    # TODO: why does the following work without overloading node_api??
    M::LeasePolicyBaseNetwork.destroy({ :network_id => network.id,
                                       :lease_policy_id => lease_policy.id
                                     })
    respond_with(R::LeasePolicy.lease_policy_network(lease_policy))
  end

  post '/:uuid/interfaces/:interface_uuid' do
    # TODO: it is now possible to associate twice....probably should not allow that.
    params = parse_params(@params, ['uuid', 'interface_uuid'])
    check_required_params(params, ['interface_uuid'])

    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy, params)
    # TODO: verify this next line is not just a hack (that does work, so far)
    interface = check_syntax_and_pop_uuid(M::Interface, { "uuid" => params[:interface_uuid] } )

    M::LeasePolicy.allocate_ip({ :interface_id => interface.id,
                                       :lease_policy_id => lease_policy.id
                                       })

    respond_with(R::LeasePolicy.lease_policy_interface(lease_policy))
  end

  get '/:uuid/interfaces' do
    show_relations(:LeasePolicy, :interfaces)
  end

  delete '/:uuid/interfaces/:interface_uuid' do
    params = parse_params(@params, ['uuid', 'interface_uuid'])
    check_required_params(params, ['interface_uuid'])

    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy, params)
    interface = check_syntax_and_pop_uuid(M::Interface, { "uuid" => params[:interface_uuid] } )

    # TODO: why does the following work without overloading node_api??
    M::LeasePolicyBaseInterface.destroy({ :interface_id => interface.id,
                                       :lease_policy_id => lease_policy.id
                                     })
    respond_with(R::LeasePolicy.lease_policy_interface(lease_policy))
  end
end
