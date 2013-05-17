# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/mac_leases' do

  post do
    possible_params = ["uuid","mac_addr","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    mac_lease = SB.mac_lease.create(params)
    respond_with(R::MacLease.generate(mac_lease))
  end

  get do
    mac_leases = SB.mac_lease.get_all
    respond_with(R::MacLeaseCollection.generate(mac_leases))
  end

  get '/:uuid' do
    mac_lease = SB.mac_lease.get(@params["uuid"])
    respond_with(R::MacLease.generate(mac_lease))
  end

  delete '/:uuid' do
    SB.mac_lease.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    mac_lease = SB.mac_lease.update(new_params)
    respond_with(R::MacLease.generate(mac_lease))
  end
end
