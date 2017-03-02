# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/filters' do
  CF = C::Filter
  CFS = C::FilterStatic

  def self.put_post_shared_params
    param :egress_passthrough, :Boolean
    param :ingress_passthrough, :Boolean
  end

  put_post_shared_params
  param_uuid M::Filter
  param_uuid M::Interface, :interface_uuid, required: true
  param :mode, :String, in: CF::MODES, required: true
  post do
    uuid_to_id(M::Interface, 'interface_uuid', 'interface_id')

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
    uuid_to_id(M::Interface, 'interface_uuid', 'interface_id') if params['interface_uuid']

    update_by_uuid2(:Filter)
  end

  def self.static_shared_params
    param :protocol, :String, in: CFS::PROTOCOLS, required: true
    param :src_address, :String, transform: PARSE_IPV4_ADDRESS
    param :dst_address, :String, transform: PARSE_IPV4_ADDRESS
    param :src_port, :Integer, in: 0..65536
    param :dst_port, :Integer, in: 0..65536
  end

  def params_to_db_fields(filter, params)
    result = {
      filter_id: filter.id,
      protocol: params['protocol'],

      ipv4_src_address: params['src_address'] ? params['src_address'].to_i : 0,
      ipv4_dst_address: params['dst_address'] ? params['dst_address'].to_i : 0,
      ipv4_src_prefix: params['src_address'] ? params['src_address'].prefix.to_i : 0,
      ipv4_dst_prefix: params['dst_address'] ? params['dst_address'].prefix.to_i : 0
    }

    case params['protocol']
    when 'tcp', 'udp'
      result.merge!(port_src: params['src_port'] ? params['src_port'] : 0,
                    port_dst: params['dst_port'] ? params['dst_port'] : 0)
    end

    result[:action] = params['action'] if params['action']
    result
  end

  static_shared_params
  param :action, :String, required: true
  post '/:uuid/static' do
    filter = check_syntax_and_pop_uuid(M::Filter)

    if filter.mode != CF::MODE_STATIC
      raise(E::ArgumentError, "Filter mode must be '#{CF::MODE_STATIC}'.")
    end

    result = M::FilterStatic.create(params_to_db_fields(filter, params))
    respond_with(R::FilterStatic.generate(result))
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

    result = M::FilterStatic.destroy(id: s.id)
    respond_with(R::FilterStatic.generate(result))
  end

  get '/:uuid/static' do
    show_relations(:Filter, :filter_statics)
  end
end
