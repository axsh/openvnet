# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_range_groups' do
  def self.put_post_shared_params
    param :allocation_type, :String,
      in: C::LeasePolicy::ALLOCATION_TYPES,
      default: C::LeasePolicy::ALLOCATION_TYPE_INCREMENTAL
  end

  fill_options = [ ]

  put_post_shared_params
  param_uuid M::IpRangeGroup
  post do
    post_new(:IpRangeGroup, fill_options)
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

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:IpRangeGroup, fill_options)
  end

  param_uuid M::IpRange, :uuid, transform: proc { |u| M::IpRange.trim_uuid(u) }
  param :begin_ipv4_address, :String, transform: PARSE_IPV4
  param :end_ipv4_address, :String, transform: PARSE_IPV4
  post '/:ip_range_group_uuid/ranges' do
    check_syntax_and_get_id(M::IpRangeGroup, "ip_range_group_uuid", "ip_range_group_id")

    remove_system_parameters

    ip_range = M::IpRange.create(params)
    respond_with(R::IpRange.generate(ip_range))
  end

  get '/:uuid/ranges' do
    show_relations(:IpRangeGroup, :ip_ranges)
  end

  delete '/:uuid/ranges/:ip_range_uuid' do
    ip_range_group = check_syntax_and_pop_uuid(M::IpRangeGroup)
    ip_range = check_syntax_and_pop_uuid(M::IpRange, "ip_range_uuid")

    raise E::UnknownUUIDResource, ip_range.uuid unless ip_range.ip_range_group_id == ip_range_group.id

    M::IpRange.destroy(ip_range.uuid)

    respond_with([ip_range.uuid])
  end
end
