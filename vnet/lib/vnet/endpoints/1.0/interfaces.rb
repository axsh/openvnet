# -*- coding: utf-8 -*-

require 'trema/mac'

Vnet::Endpoints::V10::VnetAPI.namespace '/interfaces' do
  def self.put_post_shared_params
    param_uuid M::Datapath, :owner_datapath_uuid
    param :ingress_filtering_enabled, :Boolean
    param :display_name, :String
    param :enable_routing, :Boolean
    param :enable_route_translation, :Boolean
  end

  fill = [ :owner_datapath, { :mac_leases => [ :mac_address, { :ip_leases => { :ip_address => :network } } ] } ]

  put_post_shared_params
  param_uuid M::Interface
  param_uuid M::Network, :network_uuid
  param :ipv4_address, :String, transform: PARSE_IPV4
  param :mac_address, :String, transform: PARSE_MAC
  param :port_name, :String
  #TODO: Write this in a constant
  param :mode, :String, in: ['vif', 'simulated', 'patch', 'remote', 'host', 'edge']
  post do
    # Consider deprecating this:
    params['port_name'] = params['uuid'] if !params['port_name'] && params['uuid']

    uuid_to_id(M::Network, "network_uuid", "network_id") if params["network_uuid"]
    uuid_to_id(M::Datapath, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]

    post_new(:Interface, fill)
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

  put_post_shared_params
  put '/:uuid' do
    check_syntax_and_get_id(M::Datapath, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]
    update_by_uuid(:Interface, fill)
  end

  post '/:uuid/security_groups/:security_group_uuid' do
    security_group = check_syntax_and_get_id(M::SecurityGroup, 'security_group_uuid', 'security_group_id')
    interface = check_syntax_and_get_id(M::Interface, 'uuid', 'interface_id')

    M::InterfaceSecurityGroup.filter(:interface_id => interface.id,
      :security_group_id => security_group.id).empty? ||
    raise(E::RelationAlreadyExists, "#{interface.uuid} <=> #{security_group.uuid}")

    remove_system_parameters

    M::InterfaceSecurityGroup.create(params)

    respond_with(R::SecurityGroup.generate(security_group))
  end

  get '/:uuid/security_groups' do
    show_relations(:Interface, :security_groups)
  end

  delete '/:uuid/security_groups/:security_group_uuid' do
    interface = check_syntax_and_pop_uuid(M::Interface)
    security_group = check_syntax_and_pop_uuid(M::SecurityGroup, 'security_group_uuid')

    relations = M::InterfaceSecurityGroup.batch.filter(:interface_id => interface.id,
      :security_group_id => security_group.id).all.commit

    # We call the destroy class method so we go trough NodeApi and send an
    # update isolation event
    relations.each { |r| M::InterfaceSecurityGroup.destroy(r.id) }
    respond_with([security_group.uuid])
  end
end
