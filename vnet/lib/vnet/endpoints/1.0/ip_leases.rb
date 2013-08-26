# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_leases' do

  post do
    params = parse_params(@params, ["uuid","network_uuid","interface_uuid","ip_address_uuid","is_deleted","created_at","updated_at","deleted_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::IpLease[params["uuid"]].nil?
      params["uuid"] = M::IpLease.trim_uuid(params["uuid"])
    end

    params['network_id'] = pop_uuid(M::Network, params, 'network_uuid').id if params.has_key?('network_uuid')
    params['interface_id'] = pop_uuid(M::Interface, params, 'interface_uuid').id if params.has_key?('interface_uuid')
    params['ip_address_id'] = pop_uuid(M::IpAddress, params, 'ip_address_uuid').id if params.has_key?('ip_address_uuid')
    params['is_deleted'] = @params['is_deleted'] == 'true' ? 1 : 0

    ip_lease = M::IpLease.create(params)
    respond_with(R::IpLease.generate(ip_lease))
  end

  get do
    ip_leases = M::IpLease.all
    respond_with(R::IpLeaseCollection.generate(ip_leases))
  end

  get '/:uuid' do
    ip_lease = M::IpLease[@params["uuid"]]
    respond_with(R::IpLease.generate(ip_lease))
  end

  delete '/:uuid' do
    ip_lease = M::IpLease.destroy(@params["uuid"])
    respond_with(R::IpLease.generate(ip_lease))
  end

  put '/:uuid' do
    params = parse_params(@params, ["network_uuid","interface_uuid","ip_address_uuid","is_deleted","created_at","updated_at","deleted_at"])

    params['network_id'] = pop_uuid(M::Network, params, 'network_uuid').id if params.has_key?('network_uuid')
    params['interface_id'] = pop_uuid(M::Interface, params, 'interface_uuid').id if params.has_key?('interface_uuid')
    params['ip_address_id'] = pop_uuid(M::IpAddress, params, 'ip_address_uuid').id if params.has_key?('ip_address_uuid')
    params['is_deleted'] = @params['is_deleted'] == 'true' ? 1 : 0

    ip_lease = M::IpLease.update(@params["uuid"], params)
    respond_with(R::IpLease.generate(ip_lease))
  end
end
