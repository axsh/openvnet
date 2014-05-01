# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_ranges' do
  def self.put_post_shared_params
    param :allocation_type, :String,
      in: C::LeasePolicy::ALLOCATION_TYPES,
      default: C::LeasePolicy::ALLOCATION_TYPE_INCREMENTAL
  end

  fill_options = [ ]

  put_post_shared_params
  param_uuid M::IpRange
  post do
    post_new(:IpRange, fill_options)
  end

  get do
    get_all(:IpRange, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:IpRange, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:IpRange)
  end

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:IpRange, fill_options)
  end

  param :begin_ipv4_address, :String, transform: PARSE_IPV4
  param :end_ipv4_address, :String, transform: PARSE_IPV4
  post '/:uuid/ranges' do
    ip_range = check_syntax_and_pop_uuid(M::IpRange, params)

    M::IpRangesRange.create({ :ip_range_id => ip_range.id,
                              :begin_ipv4_address => params["begin_ipv4_address"],
                              :end_ipv4_address => params["end_ipv4_address"]
                            })

    respond_with(R::IpRange.ip_ranges_ranges(ip_range))
  end

  get '/:uuid/ranges' do
    show_relations(:IpRange, :ip_ranges_ranges)
  end

  param :begin_ipv4_address, :String, transform: PARSE_IPV4
  param :end_ipv4_address, :String, transform: PARSE_IPV4
  delete '/:uuid/ranges' do
    ip_range = check_syntax_and_pop_uuid(M::IpRange, params)

    M::IpRangesRange.destroy({ :ip_range_id => ip_range.id,
                              :begin_ipv4_address => params["begin_ipv4_address"],
                              :end_ipv4_address => params["end_ipv4_address"],
                            })
    respond_with(R::IpRange.ip_ranges_ranges(ip_range))
  end
end
