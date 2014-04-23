# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/translations' do
  put_post_shared_params = ["interface_uuid",
                            "mode",
                            "passthrough"
                           ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["interface_uuid", "mode"]

    post_new(:Translation, accepted_params, required_params) do |params|
      check_syntax_and_get_id(M::Interface, params, "interface_uuid", "interface_id")
    end
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

  put '/:uuid' do
    update_by_uuid(:Translation, put_post_shared_params) do |params|
      check_syntax_and_get_id(M::Interface, params, "interface_uuid", "interface_id")
    end
  end

  post '/:uuid/static_address' do
    params = parse_params(@params, ['uuid',
                                    'ingress_ipv4_address',
                                    'egress_ipv4_address',
                                    'ingress_port_number',
                                    'egress_port_number',
                                    'route_link_uuid'])
    check_required_params(params, ['ingress_ipv4_address', 'egress_ipv4_address'])

    ingress_ipv4_address = parse_ipv4(params['ingress_ipv4_address'])
    egress_ipv4_address = parse_ipv4(params['egress_ipv4_address'])
    ingress_port_number = parse_port(params['ingress_port_number'])
    egress_port_number = parse_port(params['egress_port_number'])

    translation = check_syntax_and_pop_uuid(M::Translation, params)
    route_link_id = params['route_link_uuid'] && check_syntax_and_pop_uuid(M::RouteLink, params, 'route_link_uuid').id

    if translation.mode != 'static_address'
      raise(E::ArgumentError, 'Translation mode must be "static_address".')
    end

    M::TranslationStaticAddress.create(translation_id: translation.id,
                                       route_link_id: route_link_id,
                                       ingress_ipv4_address: ingress_ipv4_address,
                                       egress_ipv4_address: egress_ipv4_address,
                                       ingress_port_number: ingress_port_number,
                                       egress_port_number: egress_port_number)
    respond_with(R::Translation.translation_static_addresses(translation))
  end

  delete '/:uuid/static_address' do
    params = parse_params(@params, ['uuid',
                                    'ingress_ipv4_address',
                                    'egress_ipv4_address',
                                    'ingress_port_number',
                                    'egress_port_number'])
    check_required_params(params, ['ingress_ipv4_address', 'egress_ipv4_address'])

    ingress_ipv4_address = parse_ipv4(params['ingress_ipv4_address'])
    egress_ipv4_address = parse_ipv4(params['egress_ipv4_address'])
    ingress_port_number = parse_port(params['ingress_port_number'])
    egress_port_number = parse_port(params['egress_port_number'])

    translation = check_syntax_and_pop_uuid(M::Translation, params)

    if translation.mode != 'static_address'
      raise(E::ArgumentError, 'Translation mode must be "static_address".')
    end

    M::TranslationStaticAddress.destroy(translation_id: translation.id,
                                        ingress_ipv4_address: ingress_ipv4_address,
                                        egress_ipv4_address: egress_ipv4_address,
                                        ingress_port_number: ingress_port_number,
                                        egress_port_number: egress_port_number)
    respond_with(R::Translation.translation_static_addresses(translation))
  end

end
