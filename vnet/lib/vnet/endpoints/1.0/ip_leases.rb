# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_leases' do
  def self.put_post_shared_params
    param :enable_routing, :Boolean
  end

  fill_options = [:mac_lease, :interface, { :ip_address => :network }]

  put_post_shared_params
  param_uuid M::IpLease
  param_uuid M::Network, :network_uuid, required: true
  param :ipv4_address, :String, transform: PARSE_IPV4, required: true
  param_uuid M::MacLease, :mac_lease_uuid
  param_uuid M::Interface, :interface_uuid
  post do
    network = uuid_to_id(M::Network, 'network_uuid', 'network_id')

    uuid_to_id_or_nil(M::MacLease, 'mac_lease_uuid', 'mac_lease_id')
    uuid_to_id_or_nil(M::Interface, 'interface_uuid', 'interface_id')

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
    update_by_uuid(:IpLease, fill_options)
  end

  param_uuid M::IpLease
  param_uuid M::Interface, :interface_uuid, required: false
  param_uuid M::MacLease, :mac_lease_uuid, required: false
  put '/:uuid/attach' do
    uuid_to_id(M::IpLease, 'uuid', 'id')
    uuid_to_id_or_nil(M::Interface, 'interface_uuid', 'interface_id')
    uuid_to_id_or_nil(M::MacLease, 'mac_lease_uuid', 'mac_lease_id')

    remove_system_parameters

    result = M::IpLease.attach_id(params)
    respond_with(R::IpLease.generate(result))
  end

  param_uuid M::IpLease
  put '/:uuid/release' do
    remove_system_parameters

    result = M::IpLease.release_uuid(params[:uuid])
    respond_with(R::IpLease.generate(result))
  end

end
