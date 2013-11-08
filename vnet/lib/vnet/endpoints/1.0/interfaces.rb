# -*- coding: utf-8 -*-

require 'trema/mac'

Vnet::Endpoints::V10::VnetAPI.namespace '/interfaces' do
  put_post_shared_params = [
    "network_uuid",
    "ipv4_address",
    "mac_address",
    "port_name",
    "owner_datapath_uuid",
    "mode",
    "display_name",
  ]

  fill = [:owner_datapath, :network, {:ip_leases => {:ip_address => :network}}, {:mac_leases => :mac_address}]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = []

    post_new(:Interface, accepted_params, required_params, fill) { |params|
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id") if params["network_uuid"]
      check_syntax_and_get_id(M::Datapath, params, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]
      params['ipv4_address'] = parse_ipv4(params['ipv4_address'])
      params['mac_address'] = parse_mac(params['mac_address'])
    }
  end

  get do
    get_all(:Interface, fill)
  end

  get '/:uuid' do
    get_by_uuid(:Interface, fill)
  end

  delete '/:uuid' do
    delete_by_uuid(:Interface)
  end

  put '/:uuid' do
    update_by_uuid(:Interface, put_post_shared_params, fill) { |params|
      check_syntax_and_get_id(M::Datapath, params, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id") if params["network_uuid"]
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params["ipv4_address"]
      params['mac_address'] = parse_mac(params['mac_address']) if params[:mac_address]
    }
  end

  post '/:uuid/security_groups' do
    params = parse_params(@params, ['uuid', 'security_group_uuid'])
    check_required_params(params, ['uuid', 'security_group_uuid'])

    security_group = check_syntax_and_get_id(M::SecurityGroup, params, 'security_group_uuid', 'security_group_id')
    interface = check_syntax_and_get_id(M::Interface, params, 'uuid', 'interface_id')

    M::InterfaceSecurityGroup.filter(:interface_id => interface.id,
      :security_group_id => security_group.id).empty? ||
    raise(E::RelationAlreadyExists, "#{interface.uuid} <=> #{security_group.uuid}")

    M::InterfaceSecurityGroup.create(params)
    respond_with(R::Interface.security_groups(interface))
  end

  get '/:uuid/security_groups' do
    show_relations(:Interface, :security_groups)
  end

  delete '/:uuid/security_groups/:security_group_uuid' do
    params = parse_params(@params, ['uuid', 'security_group_uuid'])
    check_required_params(params, ['uuid', 'security_group_uuid'])

    interface = check_syntax_and_pop_uuid(M::Interface, params)
    security_group = check_syntax_and_pop_uuid(M::SecurityGroup, params, 'security_group_uuid')

    relations = M::InterfaceSecurityGroup.batch.filter(:interface_id => interface.id,
      :security_group_id => security_group.id).all.commit

    relations.each { |r| r.batch.destroy.commit }
    respond_with(R::Interface.security_groups(interface))
  end
end
