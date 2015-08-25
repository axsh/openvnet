# -*- coding: utf-8 -*-

#TODO: Write some FREAKING tests for this
Vnet::Endpoints::V10::VnetAPI.namespace '/filters' do
  CF = C::Filter
  
  def self.put_post_shared_params
    param_uuid M::Interface, :interface_uuid
    param :mode, :String, in: CF::MODES
    param :passthrough, :Boolean
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
    param :ipv4_address, :String, transform: PARSE_IPV4, required: true
    param :port_number, :Integer, in: 1..65536
  end

  static_shared_params
  post '/:uuid/static' do

    filter = check_syntax_and_pop_uuid(M::Filter)

    if filter.mode != CF::MODE_STATIC
      raise(E::ArgumentError, "Filter mode must be '#{CF::MODE_STATIC}'.")
    end

    s = M::FilterStatic.create(
      filter_id: filter.id,
      ipv4_address: params["ipv4_address"],
      port_number: params["port_number"]
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
