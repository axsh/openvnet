# -*- coding: utf-8 -*-

require 'ipaddr'

Vnet::Endpoints::V10::VnetAPI.namespace '/networks' do
  put_post_shared_params = [
    "display_name",
    "ipv4_network",
    "ipv4_prefix",
    "domain_name",
    "network_mode",
    "editable"
  ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["display_name", "ipv4_network"]

    post_new(:Network, accepted_params, required_params) { |params|
      params["ipv4_network"] = parse_ipv4(params["ipv4_network"]) if params.has_key?("ipv4_network")
    }
  end

  get do
    get_all(:Network)
  end

  get '/:uuid' do
    get_by_uuid(:Network)
  end

  delete '/:uuid' do
    begin
      delete_by_uuid(:Network)
    rescue Vnet::Models::DeleteRestrictionError => e
      raise E::DeleteRestrictionError, e.message
    end
  end

  put '/:uuid' do
    update_by_uuid(:Network, put_post_shared_params) { |params|
      params["ipv4_network"] = parse_ipv4(params["ipv4_network"]) if params.has_key?("ipv4_network")
    }
  end

  post '/:network_uuid/dhcp_ranges' do
    params = parse_params(@params, ['uuid', 'network_uuid', 'range_begin', 'range_end'])
    check_required_params(params, ['range_begin', 'range_end'])

    check_and_trim_uuid(M::DhcpRange, params) if params["uuid"]
    network = check_syntax_and_get_id(M::Network, params, 'network_uuid', 'network_id')

    params['range_begin'] = parse_ipv4(params['range_begin'])
    params['range_end'] = parse_ipv4(params['range_end'])

    M::DhcpRange.create(params)

    respond_with(R::Network.dhcp_ranges(network))
  end

  get '/:uuid/dhcp_ranges' do
    show_relations(:Network, :dhcp_ranges)
  end

  delete '/:uuid/dhcp_ranges/:range_uuid' do
    params = parse_params(@params, ['uuid', 'range_uuid'])

    network = check_syntax_and_pop_uuid(M::Network, params)
    range = check_syntax_and_pop_uuid(M::DhcpRange, params, 'range_uuid')

    # Using id because for some reason range.network is returning nil
    # I've got the ModelWrapper blues.... ;_;
    raise E::UnknownUUIDResource, range.uuid unless range.network_id == network.id

    range.batch.destroy.commit

    respond_with R::Network.dhcp_ranges(network)
  end
end
