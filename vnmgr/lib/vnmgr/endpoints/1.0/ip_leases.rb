# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/ip_leases' do

  post do
    params = parse_params(@params, ["uuid","network_uuid","vif_uuid","ip_address_uuid","alloc_type","is_deleted","created_at","updated_at","deleted_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::IpLease[params["uuid"]].nil?
      params["uuid"] = M::IpLease.trim_uuid(params["uuid"])
    end
    ip_lease = sb.ip_lease.create(params)
    respond_with(R::IpLease.generate(ip_lease))
  end

  get do
    ip_leases = sb.ip_lease.all
    respond_with(R::IpLeaseCollection.generate(ip_leases))
  end

  get '/:uuid' do
    ip_lease = sb.ip_lease[{:uuid => @params["uuid"]}]
    respond_with(R::IpLease.generate(ip_lease))
  end

  delete '/:uuid' do
    ip_lease = sb.ip_lease.delete({:uuid => @params["uuid"]})
    respond_with(R::IpLease.generate(ip_lease))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","network_uuid","vif_uuid","ip_address_uuid","alloc_type","is_deleted","created_at","updated_at","deleted_at"])
    ip_lease = sb.ip_lease.update(params)
    respond_with(R::IpLease.generate(ip_lease))
  end
end
