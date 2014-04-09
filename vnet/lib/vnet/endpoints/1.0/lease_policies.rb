# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/lease_policies' do
  put_post_shared_params = ["mode"]

  fill_options = [ ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = [ ]

    post_new(:LeasePolicy, accepted_params, required_params, fill_options) { |params|
      params["mode"] = "simple" if ! params.has_key? "mode"
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
    params = parse_params(@params, ['uuid', 'network_uuid', 'method', 'ip_range_uuid'])
    check_required_params(params, ['network_uuid', 'ip_range_uuid'])
    params['method'] = 'incremental' if params['method'].nil?  # TODO: remove
    
    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy, params)
    # TODO: verify this next line is not just a hack (that does work, so far)
    network = check_syntax_and_pop_uuid(M::Network, { "uuid" => params[:network_uuid] } )
    ip_range = check_syntax_and_pop_uuid(M::IpRange, { "uuid" => params[:ip_range_uuid] } )

    M::LeasePolicyBaseNetwork.create({ :network_id => network.id,
                                       :lease_policy_id => lease_policy.id,
                                       :ip_range_id => ip_range.id,
                                       :mmethod => params['method']
                                     })
    respond_with(R::LeasePolicy.lease_policy_network(lease_policy))
  end

  put '/:uuid/disassociate_network' do
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

  put '/:uuid/associate_interface' do
    # TODO: it is now possible to associate twice....probably should not allow that.
    params = parse_params(@params, ['uuid', 'interface_uuid', 'immediate'])
    check_required_params(params, ['interface_uuid'])

    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy, params)
    # TODO: verify this next line is not just a hack (that does work, so far)
    interface = check_syntax_and_pop_uuid(M::Interface, { "uuid" => params[:interface_uuid] } )

    M::LeasePolicyBaseInterface.create({ :interface_id => interface.id,
                                       :lease_policy_id => lease_policy.id
                                       })

    if params.has_key? :immediate
      # TODO: go over code in here carefully
      #   Should it use model instead of model class?
      #   Check for empty ml_array?
      #   What are the rules for what is required inside
      #      of IpLease.create()? Why do those three
      #      parameters work?
      net_array = lease_policy.batch.networks.commit
      if net_array && ! net_array.empty?
        first_net = net_array.first
        response = first_net.batch.incremental_ip_allocation.commit
        ml_array = interface.batch.mac_leases.commit
        
        ip_lease = M::IpLease.create({
                                       mac_lease_id: ml_array.first.id,
                                       network_id: first_net.id,
                                       ipv4_address: response
                                     })
      end
    else
        response = nil
    end

    # tmp response for debugging:
    respond_with({ :allocated_address => response })
    # TODO, what is a good response in the vnet style of doing things?
    # respond_with(R::LeasePolicy.lease_policy_interface(lease_policy))
  end

  put '/:uuid/disassociate_interface' do
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
