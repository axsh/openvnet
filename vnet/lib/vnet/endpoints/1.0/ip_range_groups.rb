# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_range_groups' do
  put_post_shared_params = [:allocation_type]

  fill_options = [ ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = [ ]

    post_new(:IpRangeGroup, accepted_params, required_params, fill_options)
  end

  get do
    get_all(:IpRangeGroup, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:IpRangeGroup, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:IpRangeGroup)
  end

  put '/:uuid' do
    update_by_uuid(:IpRangeGroup, put_post_shared_params, fill_options)
  end

  post '/:ip_range_group_uuid/ip_ranges' do
    params = parse_params(@params, [:ip_range_group_uuid, :uuid, :begin_ipv4_address, :end_ipv4_address])

    ip_range_group = check_syntax_and_pop_uuid(M::IpRangeGroup, params, :ip_range_group_uuid)
    check_and_trim_uuid(M::IpRange, params) if params[:uuid]

    params[:ip_range_group_id] = ip_range_group.id
    params[:begin_ipv4_address] = parse_ipv4(params[:begin_ipv4_address])
    params[:end_ipv4_address] = parse_ipv4(params[:end_ipv4_address])

    ip_range = M::IpRange.create(params)

    respond_with(R::IpRange.generate(ip_range))
  end

  get '/:uuid/ip_ranges' do
    show_relations(:IpRangeGroup, :ip_ranges)
  end

  delete '/:uuid/ip_ranges/:ip_range_uuid' do
    params = parse_params(@params, [:uuid, :ip_range_uuid])

    ip_range_group = check_syntax_and_pop_uuid(M::IpRangeGroup, params)
    ip_range = check_syntax_and_pop_uuid(M::IpRange, params, :ip_range_uuid)

    raise E::UnknownUUIDResource, ip_range.uuid unless ip_range.ip_range_group_id == ip_range_group.id

    M::IpRange.destroy(ip_range.uuid)

    respond_with([ip_range.uuid])
  end
end
