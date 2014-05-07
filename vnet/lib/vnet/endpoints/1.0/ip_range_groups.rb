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

  param :begin_ipv4_address, :String, transform: PARSE_IPV4
  param :end_ipv4_address, :String, transform: PARSE_IPV4
  post '/:uuid/ip_ranges' do
    ip_range_group = check_syntax_and_pop_uuid(M::IpRangeGroup, params)

    M::IpRange.create({ :ip_range_group_id => ip_range_group.id,
                        :begin_ipv4_address => params["begin_ipv4_address"],
                        :end_ipv4_address => params["end_ipv4_address"],
                      })
    respond_with(R::IpRangeGroup.ip_ranges(ip_range_group))
  end

  get '/:uuid/ip_ranges' do
    show_relations(:IpRangeGroup, :ip_ranges)
  end

  param :begin_ipv4_address, :String, transform: PARSE_IPV4
  param :end_ipv4_address, :String, transform: PARSE_IPV4
  delete '/:uuid/ip_ranges' do
    ip_range_group = check_syntax_and_pop_uuid(M::IpRangeGroup, params)

    #TODO: Raise error when this range wasn't found

    M::IpRange.destroy({ :ip_range_group_id => ip_range_group.id,
                         :begin_ipv4_address => params["begin_ipv4_address"],
                         :end_ipv4_address => params["end_ipv4_address"],
                       })

    respond_with(R::IpRangeGroup.ip_ranges(ip_range_group))
  end
end
