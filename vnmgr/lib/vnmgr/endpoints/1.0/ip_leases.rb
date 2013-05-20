# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/ip_leases' do

  post do
    possible_params = ["uuid","network_id","vif_id","ip_handle_id","alloc_type","is_deleted","created_at","updated_at","deleted_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    ip_lease = sb.ip_lease.create(params)
    respond_with(R::IpLease.generate(ip_lease))
  end

  get do
    ip_leases = sb.ip_lease.get_all
    respond_with(R::IpLeaseCollection.generate(ip_leases))
  end

  get '/:uuid' do
    ip_lease = sb.ip_lease.get(@params["uuid"])
    respond_with(R::IpLease.generate(ip_lease))
  end

  delete '/:uuid' do
    sb.ip_lease.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    ip_lease = sb.ip_lease.update(new_params)
    respond_with(R::IpLease.generate(ip_lease))
  end
end
