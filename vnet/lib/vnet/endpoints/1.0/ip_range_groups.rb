# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_range_groups' do
  put_post_shared_params = ["allocation_type"]

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

  post '/:uuid/ip_ranges' do
    params = parse_params(@params, ['uuid', "begin_ipv4_address", "end_ipv4_address"])

    ip_range_group = check_syntax_and_pop_uuid(M::IpRangeGroup, params)
    begin_ipv4_address = parse_ipv4(params['begin_ipv4_address'])
    end_ipv4_address = parse_ipv4(params['end_ipv4_address'])

    M::IpRange.create({ :ip_range_group_id => ip_range_group.id,
                        :begin_ipv4_address => begin_ipv4_address,
                        :end_ipv4_address => end_ipv4_address,
                      })
    respond_with(R::IpRangeGroup.ip_ranges(ip_range_group))
  end

  get '/:uuid/ip_ranges' do
    show_relations(:IpRangeGroup, :ip_ranges)
  end

  delete '/:uuid/ip_ranges' do
    params = parse_params(@params, ['uuid', "begin_ipv4_address", "end_ipv4_address"])

    ip_range_group = check_syntax_and_pop_uuid(M::IpRangeGroup, params)
    begin_ipv4_address = parse_ipv4(params['begin_ipv4_address'])
    end_ipv4_address = parse_ipv4(params['end_ipv4_address'])

    M::IpRange.destroy({ :ip_range_group_id => ip_range_group.id,
                              :begin_ipv4_address => begin_ipv4_address,
                              :end_ipv4_address => end_ipv4_address,
                            })
    respond_with(R::IpRangeGroup.ip_ranges(ip_range_group))
  end
end
