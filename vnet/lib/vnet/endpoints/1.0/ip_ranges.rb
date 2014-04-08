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
    update_by_uuid(:IpRange, put_post_shared_params, fill_options) { |params|

    }
  end

  put '/:uuid/add_range' do
    params = parse_params(@params, ['uuid', "start_ipv4_address", "end_ipv4_address"])

    ip_range = check_syntax_and_pop_uuid(M::IpRange, params)
    start_ipv4_address = parse_ipv4(params['start_ipv4_address'])
    end_ipv4_address = parse_ipv4(params['end_ipv4_address'])

    M::IpRangesRange.create({ :ip_range_id => ip_range.id,
                              :start_ipv4_address => start_ipv4_address,
                              :end_ipv4_address => end_ipv4_address,
                            })
    respond_with(R::IpRange.ip_ranges_ranges(ip_range))
  end

  put '/:uuid/delete_range' do
    params = parse_params(@params, ['uuid', "start_ipv4_address", "end_ipv4_address"])

    ip_range = check_syntax_and_pop_uuid(M::IpRange, params)
    start_ipv4_address = parse_ipv4(params['start_ipv4_address'])
    end_ipv4_address = parse_ipv4(params['end_ipv4_address'])

    M::IpRangesRange.destroy({ :ip_range_id => ip_range.id,
                              :start_ipv4_address => start_ipv4_address,
                              :end_ipv4_address => end_ipv4_address,
                            })
    respond_with(R::IpRange.ip_ranges_ranges(ip_range))
  end
end
