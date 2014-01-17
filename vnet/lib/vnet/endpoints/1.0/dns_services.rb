# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/dns_services' do
  fill_options = [:network_service]

  put_post_shared_params = [
    :public_dns,
    :enabled
  ]

  post do
    accepted_params = put_post_shared_params + [
      :uuid,
      :network_service_uuid,
    ]
    required_params = [:network_service_uuid]

    post_new(:DnsService, accepted_params, required_params, fill_options) { |params|
      check_syntax_and_get_id(M::NetworkService, params, :network_service_uuid, :network_service_id)
    }
  end

  get do
    get_all(:DnsService, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:DnsService, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:DnsService)
  end

  put '/:uuid' do
    update_by_uuid(:DnsService, put_post_shared_params, fill_options)
  end

  post '/:dns_service_uuid/dns_records' do
    params = parse_params(@params, [:uuid, :dns_service_uuid, :name, :ipv4_address])
    check_required_params(params, [:dns_service_uuid, :name, :ipv4_address])

    dns_service = check_syntax_and_pop_uuid(M::DnsService, params, :dns_service_uuid)

    check_and_trim_uuid(M::DnsRecord, params) if params[:uuid]

    params[:ipv4_address] = parse_ipv4(params[:ipv4_address])
    params[:dns_service_id] = dns_service.id

    M::DnsRecord.create(params)

    respond_with(R::DnsService.dns_records(dns_service))
  end

  get '/:uuid/dns_records' do
    show_relations(:DnsService, :dns_records)
  end

  delete '/:uuid/dns_records/:dns_record_uuid' do
    dns_service = check_syntax_and_pop_uuid(M::DnsService, @params)
    dns_record = check_syntax_and_pop_uuid(M::DnsRecord, @params, :dns_record_uuid)

    raise E::UnknownUUIDResource, dns_record.uuid unless dns_record.dns_service_id == dns_service.id

    M::DnsRecord.destroy(dns_record.uuid)

    respond_with R::DnsService.dns_records(dns_service)
  end
end
