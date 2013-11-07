# -*- coding: utf-8 -*-

require 'trema/mac'

Vnet::Endpoints::V10::VnetAPI.namespace '/interfaces' do
  put_post_shared_params = [
    "network_uuid",
    "ipv4_address",
    "mac_address",
    "port_name",
    "owner_datapath_uuid",
    "mode",
    "display_name",
  ]

  fill = [:owner_datapath, :network, {:ip_leases => {:ip_address => :network}}, {:mac_leases => :mac_address}]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = []

    post_new(:Interface, accepted_params, required_params, fill) { |params|
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id") if params["network_uuid"]
      check_syntax_and_get_id(M::Datapath, params, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]
      params['ipv4_address'] = parse_ipv4(params['ipv4_address'])
      params['mac_address'] = parse_mac(params['mac_address'])
    }
  end

  get do
    get_all(:Interface, fill)
  end

  get '/:uuid' do
    get_by_uuid(:Interface, fill)
  end

  delete '/:uuid' do
    delete_by_uuid(:Interface)
  end

  put '/:uuid' do
    update_by_uuid(:Interface, put_post_shared_params, fill) { |params|
      check_syntax_and_get_id(M::Datapath, params, "owner_datapath_uuid", "owner_datapath_id") if params["owner_datapath_uuid"]
      check_syntax_and_get_id(M::Network, params, "network_uuid", "network_id") if params["network_uuid"]
      params['ipv4_address'] = parse_ipv4(params['ipv4_address']) if params["ipv4_address"]
      params['mac_address'] = parse_mac(params['mac_address']) if params[:mac_address]
    }
  end

  post '/:interface_uuid/security_groups' do
    params = parse_params(@params, ['interface_uuid', 'security_group_uuid'])
    check_required_params(params, ['interface_uuid', 'security_group_uuid'])

    check_syntax_and_get_id(M::SecurityGroup, params, 'security_group_uuid', 'security_group_id')
    interface = check_syntax_and_get_id(M::Interface, params, 'interface_uuid', 'interface_id')

    M::InterfaceSecurityGroup.create(params)
    respond_with(R::Interface.security_groups(interface))
  end
end
