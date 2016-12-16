# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/filters' do
  CF = C::Filter

  def self.put_post_shared_params
    param :egress_passthrough, :Boolean
    param :ingress_passthrough, :Boolean
  end

  put_post_shared_params
  param_uuid M::Filter
  param_uuid M::Interface, :interface_uuid, required: true
  param :mode, :String, in: CF::MODES, required: true
  post do
    uuid_to_id(M::Interface, "interface_uuid", "interface_id")

    post_new :Filter
  end

  get do
    get_all(:Filter)
  end

  get '/:uuid' do
    get_by_uuid(:Filter)
  end

  delete '/:uuid' do
    delete_by_uuid(:Filter)
  end

  put_post_shared_params
  put '/:uuid' do
    uuid_to_id(M::Interface, "interface_uuid", "interface_id") if params["interface_uuid"]

    update_by_uuid2(:Filter)
  end

  def self.static_shared_params
    param :ipv4_address, :String, transform: PARSE_IPV4_ADDRESS
    param :port_number, :Integer, in: 0..65536
    param :protocol, :String, in: ['tcp', 'udp', 'icmp', 'arp', 'all'], required: true
    param :passthrough, :Boolean, required: true
  end

  def params_to_db_fields(filter, params)
    case params["protocol"]
    when "tcp", "udp"
      raise E::MissingArgument, 'port_number' if params["port_number"].nil?
      raise E::MissingArgument, 'ipv4_address' if params["ipv4_address"].nil?

      ipv4_src_address = params["ipv4_address"].to_i
      ipv4_src_prefix = params["ipv4_address"].prefix.to_i
      port_number = params["port_number"]
    when "icmp"
      raise E::MissingArgument, 'ipv4_address' if params["ipv4_address"].nil?

      ipv4_src_address = params["ipv4_address"].to_i
      ipv4_src_prefix = params["ipv4_address"].prefix.to_i
      port_number = nil
    when "arp", "all"
      ipv4_src_address = 0
      ipv4_src_prefix = 0
      port_number = nil
    end

    if filter.mode != CF::MODE_STATIC
      raise(E::ArgumentError, "Filter mode must be '#{CF::MODE_STATIC}'.")
    end

    {
      filter_id: filter.id,
      ipv4_src_address: ipv4_src_address,
      ipv4_src_prefix: ipv4_src_prefix,
      ipv4_dst_address: 0,
      ipv4_dst_prefix: 0,
      port_src: port_number && 0,
      port_dst: port_number,
      protocol: params["protocol"],
      passthrough: params["passthrough"]
    }
  end

  static_shared_params
  post '/:uuid/static' do
    filter = check_syntax_and_pop_uuid(M::Filter)
    db_fields = params_to_db_fields(filter, params)

    s = M::FilterStatic.create(db_fields)

    respond_with(R::FilterStatic.generate(s))
  end

  static_shared_params
  delete '/:uuid/static' do
    filter = check_syntax_and_pop_uuid(M::Filter)
    db_fields = params_to_db_fields(filter, params)

    s = M::FilterStatic.batch[db_fields].commit

    if !s
      rp = request.params.to_json
      raise E::UnknownResource, "Couldn't find resource with parameters: #{rp}"
    end

    M::FilterStatic.destroy(id: s.id)

    respond_with(R::Filter.filter_statics(filter))

  end

  get '/static/' do
    get_all(:FilterStatic)
  end

  get '/:uuid/static' do
    show_relations(:Filter, :filter_statics)
  end
end
