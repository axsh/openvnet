# -*- coding: utf-8 -*-

#TODO: Write some FREAKING tests for this
Vnet::Endpoints::V10::VnetAPI.namespace '/filters' do
  CF = C::Filter
  
  def self.put_post_shared_params
    param_uuid M::Interface, :interface_uuid
    param :mode, :String, in: CF::MODES
    param :egress_passthrough, :Boolean
    param :ingress_passthrough, :Boolean
  end

  put_post_shared_params
  param_uuid M::Filter
  param_uuid M::Interface, :interface_uuid, required: true
  param_options :mode, required: true
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

    update_by_uuid(:Filter)
  end

  def self.static_shared_params
    param :ipv4_address, :String, transform: PARSE_IPV4_ADDRESS, required: true
    param :port_number, :Integer, in: 0..65536
    param :protocol, :String
    param :passthrough, :Boolean

    # not in use yet
    param :ipv4_src_address, :String, transform: PARSE_IPV4_ADDRESS
    param :ipv4_dst_address, :String, transform: PARSE_IPV4_ADDRESS
    param :port_src_first, :Integer, in: 0..65536
    param :port_src_last, :Integer, in: 0..65536
    param :port_dst_first, :Integer, in: 0..65536
    param :port_dst_last, :Integer, in: 0..65536
  end

  static_shared_params
  post '/:uuid/static' do

    filter = check_syntax_and_pop_uuid(M::Filter)

    if filter.mode != CF::MODE_STATIC
      raise(E::ArgumentError, "Filter mode must be '#{CF::MODE_STATIC}'.")
    end

    s = M::FilterStatic.create(
      filter_id: filter.id,
      ipv4_src_address: params["ipv4_address"].to_i,
      ipv4_src_prefix: params["ipv4_address"].prefix,
      ipv4_dst_address: "0",
      ipv4_dst_prefix: 0,
      port_src_first: params["port_number"],
      port_src_lastr: params["port_number"],
      port_dst_first: params["port_number"],
      port_dst_lastr: params["port_number"],
      protocol: params["protocol"],
      passthrough: params["passthrough"]
    )

    respond_with(R::FilterStatic.generate(s))
  end

  static_shared_params
  delete '/:uuid/static' do
    filter = check_syntax_and_pop_uuid(M::Filter)

    if filter.mode != CF::MODE_STATIC
      raise(E::ArgumentError, "Filter mode must be '#{CF::MODE_STATIC}'.")
    end

    remove_system_parameters

    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Sequel expects symbols in its filter hash. Symbolise the string keys in params
    # filter_params = params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    # params[:translation_id] = translation.id
    # tsa = M::TranslationStaticAddress.batch[filter_params].commit

    if !s
      rp = request.params.to_json
      raise E::UnknownResource, "Couldn't find resource with parameters: #{rp}"
    end
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    M::FilterStatic.destroy(id: s.id)

    respond_with(R::Filter.filter_statics(filter))
  end

end
