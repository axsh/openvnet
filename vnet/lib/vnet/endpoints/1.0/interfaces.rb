# -*- coding: utf-8 -*-

require 'trema/mac'
require "vnet/constants/datapath"
require "vnet/constants/interface"
require "vnet/constants/network"

Vnet::Endpoints::V10::VnetAPI.namespace '/interfaces' do
  def self.put_post_shared_params
    param_uuid2 :owner_datapath_uuid, C::Datapath
    param :ingress_filtering_enabled, :Boolean
    param :display_name, :String
    param :enable_routing, :Boolean
    param :enable_route_translation, :Boolean
  end

  fill = [ { :mac_leases => [ :mac_address, { :ip_leases => { :ip_address => :network } } ] } ]

  #
  # Base:
  #

  put_post_shared_params
  param_uuid2 :uuid, C::Interface
  param_uuid2 :network_uuid, C::Network
  param :ipv4_address, :String, transform: PARSE_IPV4
  param :mac_address, :String, transform: PARSE_MAC
  param :port_name, :String
  param :mode, :String, in: C::Interface::MODES
  post do
    uuid_to_id(M::Network, "network_uuid", "network_id") if params["network_uuid"]
    uuid_to_id(M::Datapath, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]

    post_new(:Interface, fill)
  end

  get do
    get_all(:Interface, fill)
  end

  param_uuid2 :uuid, C::Interface
  get '/:uuid' do
    get_by_uuid(:Interface, fill)
  end

  param_uuid2 :uuid, C::Interface
  delete '/:uuid' do
    delete_by_uuid(:Interface)
  end

  param_uuid2 :uuid, C::Interface
  put_post_shared_params
  put '/:uuid' do
    check_syntax_and_get_id(M::Datapath, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]
    update_by_uuid(:Interface, fill)
  end

  param_uuid2 :uuid, C::Interface
  param_uuid2 :new_uuid, C::Interface
  put '/:uuid/rename' do
    updated_object = M::Interface.batch.rename(params['uuid'], params['new_uuid']).commit
    respond_with([updated_object])
  end

  #
  # Ports:
  #

  def self.port_put_post_shared_params
    param_uuid2 :datapath_uuid, C::Datapath
    param :port_name, :String
    param :singular, :Boolean
  end

  port_put_post_shared_params
  param_uuid2 :uuid, C::Interface
  post '/:uuid/ports' do
    interface = check_syntax_and_get_id(M::Interface, 'uuid', 'interface_id')
    datapath = check_syntax_and_get_id(M::Datapath, 'datapath_uuid', 'datapath_id') if params['datapath_uuid']

    # TODO: Move to node_api.
    params['interface_mode'] = interface.mode

    remove_system_parameters

    interface_port = M::InterfacePort.create_with_uuid(params)
    respond_with(interface_port)
  end

  param_uuid2 :uuid, C::Interface
  get '/:uuid/ports' do
    show_relations(:Interface, :interface_ports)
  end

  param_uuid2 :uuid, C::Interface
  port_put_post_shared_params
  delete '/:uuid/ports' do
    interface = check_syntax_and_get_id(M::Interface, 'uuid', 'interface_id')
    datapath = check_syntax_and_get_id(M::Datapath, 'datapath_uuid', 'datapath_id') if params['datapath_uuid']

    filter = {
      interface_id: interface.id,
    }
    filter[:datapath_id] = datapath.id if datapath
    filter[:port_name] = params['port_name'] if params.has_key?('port_name')
    filter[:singular] = params['singular'] if params.has_key?('singular')

    ports = M::InterfacePort.batch.where(filter).all.commit
    ports.each { |r| M::InterfacePort.destroy(r.id) }

    respond_with(ports)
  end

  #
  # Security Groups:
  #

  post '/:uuid/security_groups/:security_group_uuid' do
    security_group = check_syntax_and_get_id(M::SecurityGroup, 'security_group_uuid', 'security_group_id')
    interface = check_syntax_and_get_id(M::Interface, 'uuid', 'interface_id')

    M::SecurityGroupInterface.filter(:interface_id => interface.id,
      :security_group_id => security_group.id).empty? ||
    raise(E::RelationAlreadyExists, "#{interface.uuid} <=> #{security_group.uuid}")

    remove_system_parameters

    M::SecurityGroupInterface.create(params)

    respond_with(R::SecurityGroup.generate(security_group))
  end

  get '/:uuid/security_groups' do
    show_relations(:Interface, :security_groups)
  end

  delete '/:uuid/security_groups/:security_group_uuid' do
    interface = check_syntax_and_pop_uuid(M::Interface)
    security_group = check_syntax_and_pop_uuid(M::SecurityGroup, 'security_group_uuid')

    deleted = M::SecurityGroupInterface.destroy_where(interface_id: interface.id,
                                                      security_group_id: security_group.id)

    respond_with(deleted > 0 ? [security_group.uuid] : [])
  end

end
