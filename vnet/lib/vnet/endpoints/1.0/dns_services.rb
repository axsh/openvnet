# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/dns_services' do
  fill_options = [:network_service]

  def self.put_post_shared_params
    param :public_dns, :String
  end

  put_post_shared_params
  param_uuid M::DnsService
  param_uuid M::NetworkService, :network_service_uuid, required: true
  post do
    #TODO: No need to check syntax since we do that in param_uuid
    check_syntax_and_get_id(M::NetworkService, :network_service_uuid, :network_service_id)

    post_new(:DnsService, fill_options)
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

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:DnsService, fill_options)
  end

  param_uuid M::DnsRecord, :uuid, required: true, transform: proc { |u| M::DnsRecord.trim_uuid(u) }
  param :name, :String, required: true
  param :ipv4_address, :String, transform: PARSE_IPV4
  post '/:dns_service_uuid/dns_records' do
    dns_service = check_syntax_and_pop_uuid(M::DnsService, :dns_service_uuid)

    params[:dns_service_id] = dns_service.id

    remove_system_parameters
    dns_record = M::DnsRecord.create(params)

    respond_with(R::DnsRecord.generate(dns_record))
  end

  get '/:uuid/dns_records' do
    show_relations(:DnsService, :dns_records)
  end

  delete '/:uuid/dns_records/:dns_record_uuid' do
    dns_service = check_syntax_and_pop_uuid(M::DnsService)
    dns_record = check_syntax_and_pop_uuid(M::DnsRecord, :dns_record_uuid)

    raise E::UnknownUUIDResource, dns_record.uuid unless dns_record.dns_service_id == dns_service.id

    M::DnsRecord.destroy(dns_record.uuid)

    respond_with([dns_record.uuid])
  end
end
