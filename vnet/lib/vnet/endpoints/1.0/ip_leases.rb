# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_leases' do

  post do
    params = parse_params(@params, ["uuid","network_uuid","iface_uuid","ip_address_uuid","alloc_type","is_deleted","created_at","updated_at","deleted_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::IpLease[params["uuid"]].nil?
      params["uuid"] = M::IpLease.trim_uuid(params["uuid"])
    end
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
    params = parse_params(@params, ["network_uuid","iface_uuid","ip_address_uuid","alloc_type","is_deleted","created_at","updated_at","deleted_at"])
    ip_lease = M::IpLease.update(@params["uuid"], params)
    respond_with(R::IpLease.generate(ip_lease))
  end
end
