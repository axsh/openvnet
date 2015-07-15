# -*- coding: utf-8 -*-

#TODO: Write some FREAKING tests for this
Vnet::Endpoints::V10::VnetAPI.namespace '/filters' do
CT = C::Filter
  
  def self.put_post_shared_params
    param_uuid M::Interface, :interface_uuid
    param :mode, :String, in: CT::MODES
    param :pass, :Boolean
    param :ingress_filtering, :Boolean
    param :egress_filtering, :Boolean
    param :ipv4_address, :Strubgm transform PARSE_IPV4, required: true
    param :port_mumber, :Integer, in: 1..65536
  end

  put_post_shared_params
  param_uuid M::Filter
  param_uuid M::Interface, :interface_uuid, required: true
  param_options :mode, required: true
  post do
    uuid_to_id(M::Interface, "interface_uuid", "interface_id")

    post_new(:Filter)
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

  def self.static_filter_shared_params
  end

  static_filters_shared_params
  post '/:uuid/static_filter' do
    filter = check_syntax_and_pop_uuid(M::Filter)

    if filter.mode != CT::MODE_STATIC_FILTER
      raise(E::ArgumentError, "Filter mode must be '#{CT::MODE_STATIC_FILTER}'.")
    end

    sf = M::FilterStatic.create(
      filter_id: filter.id,
    )

    respond_with(R::Filter.generate(sf))
#    respond_with(R::FilterStatic.generate(sf))
  end

  static_filter_shared_params
  delete '/:uuid/static_filter' do
    filter = check_syntax_and_pop_uuid(M::Filter)

    if filter.mode != CT::MODE_STATIC_FILTER
      raise(E::ArgumentError, "Filter mode must be '#{CT::MODE_STATIC_FILTER}'."
    end

    remove_system_parameters

    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Sequel expects symbols in its filter hash. Symbolise the string keys in params
    # filter_params = params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    # params[:translation_id] = translation.id
    # tsa = M::TranslationStaticAddress.batch[filter_params].commit

    if !sf
      rp = request.params.to_json
      raise E::UnknownResource, "Couldn't find resource with parameters: #{rp}"
    end
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    M::FilterStatic.destroy(id: sf.id)

    respond_with(R::Filter.filter_static(filter))
  end

end
