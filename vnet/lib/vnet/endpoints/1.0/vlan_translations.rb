# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/vlan_translations' do
  put_post_shared_params = [
    "vif_uuid",
    "mac_address",
    "vlan_id",
    "network_id"
  ]

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["network_id"]

    post_new(:VlanTranslation, accepted_params, required_params) do |params|
      params['mac_address'] = parse_mac(params['mac_address'])
      check_syntax_and_get_id(M::Interface, params, "vif_uuid", "interface_id")
    end
  end

  get do
    get_all(:VlanTranslation)
  end

  get '/:uuid' do
    get_by_uuid(:VlanTranslation)
  end

  delete '/:uuid' do
    delete_by_uuid(:VlanTranslation)
  end

  put '/:uuid' do
    update_by_uuid(:VlanTranslation, put_post_shared_params) do |params|
      params['mac_address'] = parse_mac(params['mac_address']) if params["mac_address"]
      check_syntax_and_get_id(M::Interface, params, "vif_uuid", "interface_id")
    end
  end
end
