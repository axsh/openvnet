# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_leases' do
  def self.put_post_shared_params
    param_uuid M::Network, :network_uuid
    param_uuid M::MacLease, :mac_lease_uuid
    param :ipv4_address, :String, transform: PARSE_IPV4
    param :enable_routing, :Boolean
  end

  fill_options = [:mac_lease, :interface, { :ip_address => :network }]

  put_post_shared_params
  param_uuid M::IpLease
  param_options :network_uuid, required: true
  param_options :mac_lease_uuid, required: true
  param_options :ipv4_address, required: true
  post do
    network = uuid_to_id(M::Network, "network_uuid", "network_id")
    uuid_to_id(M::MacLease, "mac_lease_uuid", "mac_lease_id")

    check_ipv4_address_subnet(network)

    post_new(:IpLease, fill_options)
  end

  get do
    get_all(:IpLease, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:IpLease, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:IpLease)
  end

  put_post_shared_params
  put '/:uuid' do
    uuid_to_id(M::Network, "network_uuid", "network_id") if params["network_uuid"]
    uuid_to_id(M::MacLease, "mac_lease_uuid", "mac_lease_id") if params["mac_lease_uuid"]

    update_by_uuid(:IpLease, fill_options)
  end
end
