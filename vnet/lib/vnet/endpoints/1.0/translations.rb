# -*- coding: utf-8 -*-

#TODO: Write some FREAKING tests for this
Vnet::Endpoints::V10::VnetAPI.namespace '/translations' do
  CT = C::Translation

  def self.put_post_shared_params
    param_uuid M::Interface, :interface_uuid
    param :mode, :String, in: CT::MODES
    param :passthrough, :Boolean
  end

  put_post_shared_params
  param_uuid M::Translation
  param_uuid M::Interface, :interface_uuid, required: true
  param_options :mode, required: true
  post do
    uuid_to_id(M::Interface, "interface_uuid", "interface_id")

    post_new(:Translation)
  end

  get do
    get_all(:Translation)
  end

  get '/:uuid' do
    get_by_uuid(:Translation)
  end

  delete '/:uuid' do
    delete_by_uuid(:Translation)
  end

  put_post_shared_params
  put '/:uuid' do
    uuid_to_id(M::Interface, "interface_uuid", "interface_id") if params["interface_uuid"]

    update_by_uuid(:Translation)
  end

  def self.static_address_shared_params
    param :ingress_ipv4_address, :String, transform: PARSE_IPV4, required: true
    param :egress_ipv4_address, :String, transform: PARSE_IPV4, required: true
    param :ingress_port_number, :Integer, in: 1..65536
    param :egress_port_number, :Integer, in: 1..65536
    param_uuid M::Network, :ingress_network_uuid
    param_uuid M::Network, :egress_network_uuid
  end

  static_address_shared_params
  param_uuid M::RouteLink, :route_link_uuid
  post '/:uuid/static_address' do
    translation = check_syntax_and_pop_uuid(M::Translation)

    route_link_id = if params['route_link_uuid']
      check_syntax_and_pop_uuid(M::RouteLink, 'route_link_uuid').id
    end

    # TODO: Add a helper method that checks the mode, or list of valid
    # modes in this case. Might be best done in model validation. 

    if translation.mode != CT::MODE_STATIC_ADDRESS
      raise(E::ArgumentError, "Translation mode must be '#{CT::MODE_STATIC_ADDRESS}'.")
    end

    tsa = M::TranslationStaticAddress.create(
      translation_id: translation.id,
      route_link_id: route_link_id,
      ingress_ipv4_address: params["ingress_ipv4_address"],
      egress_ipv4_address: params["egress_ipv4_address"],
      ingress_port_number: params["ingress_port_number"],
      egress_port_number: params["egress_port_number"]
    )

    r = R::TranslationStaticAddress.generate(tsa)

    if params['ingress_network_uuid'] && params['egress_network_uuid']
      r[:ingress_network_uuid] = params['ingress_network_uuid']
      r[:egress_network_uuid] = params['egress_network_uuid']
    end

    respond_with(r)
  end

  static_address_shared_params
  delete '/:uuid/static_address' do
    translation = check_syntax_and_pop_uuid(M::Translation)

    if translation.mode != CT::MODE_STATIC_ADDRESS
      raise(E::ArgumentError, "Translation mode must be '#{CT::MODE_STATIC_ADDRESS}'.")
    end

    remove_system_parameters

    # Sequel expects symbols in its filter hash. Symbolise the string keys in params
    filter_params = params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    params[:translation_id] = translation.id
    tsa = M::TranslationStaticAddress.batch[filter_params].commit

    if !tsa
      rp = request.params.to_json
      raise E::UnknownResource, "Couldn't find resource with parameters: #{rp}"
    end

    M::TranslationStaticAddress.destroy(id: tsa.id)

    respond_with(R::Translation.translation_static_addresses(translation))
  end

end
