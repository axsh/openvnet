# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/ip_addresses' do

  post do
    possible_params = ["uuid","network_id","ipv4_address","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    ip_address = sb.ip_address.create(params)
    respond_with(R::IpAddress.generate(ip_address))
  end

  get do
    ip_addresss = sb.ip_address.get_all
    respond_with(R::IpAddressCollection.generate(ip_addresss))
  end

  get '/:uuid' do
    ip_address = sb.ip_address.get(@params["uuid"])
    respond_with(R::IpAddress.generate(ip_address))
  end

  delete '/:uuid' do
    sb.ip_address.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    ip_address = sb.ip_address.update(new_params)
    respond_with(R::IpAddress.generate(ip_address))
  end
end
