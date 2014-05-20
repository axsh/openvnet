# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/lease_policies' do
  CLP = Vnet::Constants::LeasePolicy
  def self.put_post_shared_params
    param :mode, :String, in: CLP::MODES, default: CLP::MODE_SIMPLE
    param :timing, :String, in: CLP::TIMINGS, default: CLP::TIMING_IMMEDIATE
    param :lease_time, :Integer
    param :grace_time, :Integer
  end

  fill_options = [ ]

  put_post_shared_params
  param_uuid M::LeasePolicy
  post do
    post_new(:LeasePolicy, fill_options)
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

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:LeasePolicy, fill_options)
  end

  param_uuid M::IpRangeGroup, :ip_range_group_uuid, required: true
  post '/:uuid/networks/:network_uuid' do
    # TODO: it is now possible to associate twice....probably should not allow that.
    
    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy)
    network = check_syntax_and_pop_uuid(M::Network, "network_uuid")

    uuid_to_id(M::IpRangeGroup, "ip_range_group_uuid", "ip_range_group_id")

    M::LeasePolicyBaseNetwork.create({ :network_id => network.id,
                                       :lease_policy_id => lease_policy.id,
                                       :ip_range_group_id => params["ip_range_group_id"]
                                     })

    respond_with(R::LeasePolicy.lease_policy_network(lease_policy))
  end

  get '/:uuid/networks' do
    show_relations(:LeasePolicy, :networks)
  end

  delete '/:uuid/networks/:network_uuid' do
    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy)
    network = check_syntax_and_pop_uuid(M::Network, "network_uuid")

    M::LeasePolicyBaseNetwork.destroy({ :network_id => network.id,
                                        :lease_policy_id => lease_policy.id
                                      })

    respond_with(R::LeasePolicy.lease_policy_network(lease_policy))
  end

  post '/:uuid/interfaces/:interface_uuid' do
    # TODO: it is now possible to associate twice....probably should not allow that.

    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy)
    interface = check_syntax_and_pop_uuid(M::Interface, "interface_uuid")

    M::LeasePolicy.allocate_ip({ :interface_id => interface.id,
                                 :lease_policy_id => lease_policy.id
                               })

    respond_with(R::LeasePolicy.lease_policy_interface(lease_policy))
  end

  get '/:uuid/interfaces' do
    show_relations(:LeasePolicy, :interfaces)
  end

  delete '/:uuid/interfaces/:interface_uuid' do
    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy)
    interface = check_syntax_and_pop_uuid(M::Interface, "interface_uuid")

    M::LeasePolicyBaseInterface.destroy({ :interface_id => interface.id,
                                          :lease_policy_id => lease_policy.id
                                       })

    respond_with(R::LeasePolicy.lease_policy_interface(lease_policy))
  end

  post '/:uuid/ip_lease_containers/:ip_lease_container_uuid' do
    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy)
    ip_lease_container = check_syntax_and_pop_uuid(M::IpLeaseContainer, "ip_lease_container_uuid")

    if lease_policy.batch.ip_lease_containers(ip_lease_container: ip_lease_container).first.commit
      raise(E::RelationAlreadyExists, "#{lease_policy.uuid} <=> #{ip_lease_container.uuid}")
    end

    M::LeasePolicy.add_ip_lease_container(lease_policy.uuid, ip_lease_container.uuid)

    respond_with(R::IpLeaseContainer.generate(ip_lease_container))
  end

  get '/:uuid/ip_lease_containers' do
    show_relations(:LeasePolicy, :ip_lease_containers)
  end

  delete '/:uuid/ip_lease_containers/:ip_lease_container_uuid' do
    lease_policy = check_syntax_and_pop_uuid(M::LeasePolicy)
    ip_lease_container = check_syntax_and_pop_uuid(M::IpLeaseContainer, "ip_lease_container_uuid")

    unless lease_policy.batch.ip_lease_containers(ip_lease_container: ip_lease_container).first.commit
      raise(E::UnknownUUIDResource, "LeasePolicyIpLeaseContainer #{lease_policy.uuid} <=> #{ip_lease_container.uuid}")
    end

    M::LeasePolicy.remove_ip_lease_container(lease_policy.uuid, ip_lease_container.uuid)

    respond_with(R::IpLeaseContainer.generate(ip_lease_container))
  end
end
