# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/dhcp_ranges' do
  put_post_shared_params = ["network_uuid","range_begin","range_end"]

  post do
    accepted_params = put_post_shared_params + ["uuid"]

    post_new(:DhcpRange, accepted_params, put_post_shared_params) { |params|
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id")
      params['range_begin'] = parse_ipv4(params['range_begin'])
      params['range_end'] = parse_ipv4(params['range_end'])
    }
  end

  get do
    get_all(:DhcpRange)
  end

  get '/:uuid' do
    get_by_uuid(:DhcpRange)
  end

  delete '/:uuid' do
    delete_by_uuid(:DhcpRange)
  end

  put '/:uuid' do
    update_by_uuid(:DhcpRange, put_post_shared_params) { |params|
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id") if params["network_uuid"]
      params['range_begin'] = parse_ipv4(params['range_begin']) if params["range_begin"]
      params['range_end'] = parse_ipv4(params['range_end']) if params["range_end"]
    }
  end
end
