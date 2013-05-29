# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/mac_leases' do

  post do
    params = parse_params(@params, ["uuid","mac_addr","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::MacLease[params["uuid"]].nil?
      params["uuid"] = M::MacLease.trim_uuid(params["uuid"])
    end
    mac_lease = data_access.mac_lease.create(params)
    respond_with(R::MacLease.generate(mac_lease))
  end

  get do
    mac_leases = data_access.mac_lease.all
    respond_with(R::MacLeaseCollection.generate(mac_leases))
  end

  get '/:uuid' do
    mac_lease = data_access.mac_lease[{:uuid => @params["uuid"]}]
    respond_with(R::MacLease.generate(mac_lease))
  end

  delete '/:uuid' do
    mac_lease = data_access.mac_lease.delete({:uuid => @params["uuid"]})
    respond_with(R::MacLease.generate(mac_lease))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","mac_addr","created_at","updated_at"])
    mac_lease = data_access.mac_lease.update(params)
    respond_with(R::MacLease.generate(mac_lease))
  end
end
