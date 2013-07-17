# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/mac_leases' do

  post do
    params = parse_params(@params, ["uuid","mac_addr","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::MacLease[params["uuid"]].nil?
      params["uuid"] = M::MacLease.trim_uuid(params["uuid"])
    end
    mac_lease = M::MacLease.create(params)
    respond_with(R::MacLease.generate(mac_lease))
  end

  get do
    mac_leases = M::MacLease.all
    respond_with(R::MacLeaseCollection.generate(mac_leases))
  end

  get '/:uuid' do
    mac_lease = M::MacLease[@params["uuid"]]
    respond_with(R::MacLease.generate(mac_lease))
  end

  delete '/:uuid' do
    mac_lease = M::MacLease.destroy(@params["uuid"])
    respond_with(R::MacLease.generate(mac_lease))
  end

  put '/:uuid' do
    params = parse_params(@params, ["mac_addr","created_at","updated_at"])
    mac_lease = M::MacLease.update(@params["uuid"], params)
    respond_with(R::MacLease.generate(mac_lease))
  end
end
