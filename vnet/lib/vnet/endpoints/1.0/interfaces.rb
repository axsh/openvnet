# -*- coding: utf-8 -*-

require 'trema/mac'

Vnet::Endpoints::V10::VnetAPI.namespace '/interfaces' do
  def self.put_post_shared_params
    param_uuid M::Datapath, :owner_datapath_uuid
    param :ingress_filtering_enabled, :Boolean, default: false
    param :enable_filtering, :Boolean
    param :display_name, :String
    param :enable_routing, :Boolean
    param :enable_route_translation, :Boolean
  end

  fill = [ { :mac_leases => [ :mac_address, { :ip_leases => { :ip_address => :network } } ] } ]

  #
  # Base:
  #

  put_post_shared_params
  param_uuid M::Interface
  param_uuid M::Network, :network_uuid
  param_uuid M::Segment, :segment_uuid
  param :ipv4_address, :String, transform: PARSE_IPV4
  param :mac_address, :String, transform: PARSE_MAC
  param :mac_range_group_uuid, :String
  param :port_name, :String
  param :mode, :String, in: C::Interface::MODES
  post do
    uuid_to_id(M::Datapath, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]
    uuid_to_id(M::MacRangeGroup, "mac_range_group_uuid", "mac_range_group_id") if params["mac_range_group_uuid"]

    segment_uuid = params["segment_uuid"]

    uuid_to_id(M::Segment, "segment_uuid", "segment_id") if segment_uuid

    if params["network_uuid"]
      network = uuid_to_id(M::Network, "network_uuid", "network_id")

      check_ipv4_address_subnet(network)

      if params["segment_id"] && params["segment_id"] != network.segment_id
        raise(E::InvalidID, "segment_uuid:#{segment_uuid} does not match the segment used by network_uuid:#{network_uuid}")
      end

      # TODO: Temporary workaround until segment's are set properly.
      params["segment_id"] = network.segment_id if network.segment_id
    end

    params["enable_legacy_filtering"] = params["ingress_filtering_enabled"]
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

  param_uuid M::Interface
  param :new_uuid, :String, required: true
  put '/:uuid/rename' do
    updated_object = M::Interface.batch.rename(params['uuid'], params['new_uuid']).commit
    respond_with([updated_object])
  end

  #
  # Ports:
  #

  def self.port_delete_post_shared_params
    param_uuid M::Datapath, :datapath_uuid
    param :port_name, :String
    param :singular, :Boolean
  end

  port_delete_post_shared_params
  param_uuid M::Interface
  post '/:uuid/ports' do
    interface = check_syntax_and_get_id(M::Interface, 'uuid', 'interface_id')
    datapath = check_syntax_and_get_id(M::Datapath, 'datapath_uuid', 'datapath_id') if params['datapath_uuid']

    # TODO: Move to node_api.
    params['interface_mode'] = interface.mode

    remove_system_parameters

    interface_port = M::InterfacePort.create_with_uuid(params)
    respond_with(R::InterfacePort.generate(interface_port))
  end

  get '/:uuid/ports' do
    show_relations(:Interface, :interface_ports)
  end

  port_delete_post_shared_params
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

    respond_with(R::InterfacePortCollection.generate(ports))
  end

  #
  # Segments:
  #

  param_uuid M::Interface
  param_uuid M::Segment, :segment_uuid
  param :static, :Boolean
  put '/:uuid/segments/:segment_uuid' do
    # TODO: Move the 'uuid_to_id' calls to nodeapi and add a
    # base_foobar module that let's us easily extract the foo_id from
    # uuid, id or nil according to the requirements.
    interface = uuid_to_id(M::Interface, 'uuid', 'interface_id')
    segment = uuid_to_id(M::Segment, 'segment_uuid', 'segment_id')

    # TODO: Use the default update handling code instead.

    if params.has_key?('static')
      if params['static']
        result = M::InterfaceSegment.set_static(interface.id, segment.id)
      else
        result = M::InterfaceSegment.clear_static(interface.id, segment.id)
      end
    else
      respond_with({})
    end

    respond_with(R::InterfaceSegment.generate(result))
  end

  get '/:uuid/segments' do
    show_relations(:Interface, :interface_segments)
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
