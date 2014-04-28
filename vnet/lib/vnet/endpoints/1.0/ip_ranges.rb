# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_ranges' do
  put_post_shared_params = ["allocation_type"]

  fill_options = [ ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = [ ]

    post_new(:IpRange, accepted_params, required_params, fill_options) { |params|
      params["allocation_type"] = "incremental" if ! params.has_key? "allocation_type"
    }
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

  put '/:uuid' do
    update_by_uuid(:IpRange, put_post_shared_params, fill_options)
  end

  post '/:uuid/ranges' do
    params = parse_params(@params, ['uuid', "begin_ipv4_address", "end_ipv4_address"])

    ip_range = check_syntax_and_pop_uuid(M::IpRange, params)
    begin_ipv4_address = parse_ipv4(params['begin_ipv4_address'])
    end_ipv4_address = parse_ipv4(params['end_ipv4_address'])

    M::IpRangeRange.create({ :ip_range_id => ip_range.id,
                              :begin_ipv4_address => begin_ipv4_address,
                              :end_ipv4_address => end_ipv4_address,
                            })
    respond_with(R::IpRange.ip_range_ranges(ip_range))
  end

  get '/:uuid/ranges' do
    show_relations(:IpRange, :ip_range_ranges)
  end

  delete '/:uuid/ranges' do
    params = parse_params(@params, ['uuid', "begin_ipv4_address", "end_ipv4_address"])

    ip_range = check_syntax_and_pop_uuid(M::IpRange, params)
    begin_ipv4_address = parse_ipv4(params['begin_ipv4_address'])
    end_ipv4_address = parse_ipv4(params['end_ipv4_address'])

    M::IpRangeRange.destroy({ :ip_range_id => ip_range.id,
                              :begin_ipv4_address => begin_ipv4_address,
                              :end_ipv4_address => end_ipv4_address,
                            })
    respond_with(R::IpRange.ip_range_ranges(ip_range))
  end
end
