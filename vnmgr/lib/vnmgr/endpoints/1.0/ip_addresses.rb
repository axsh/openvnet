# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/ip_addresses' do

  post do
    params = parse_params(@params, ["uuid","ipv4_address","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::IpAddress[params["uuid"]].nil?
      params["uuid"] = M::IpAddress.trim_uuid(params["uuid"])
    end
    ip_address = sb.ip_address.create(params)
    respond_with(R::IpAddress.generate(ip_address))
  end

  get do
    ip_addresses = sb.ip_address.all
    respond_with(R::IpAddressCollection.generate(ip_addresses))
  end

  get '/:uuid' do
    ip_address = sb.ip_address[{:uuid => @params["uuid"]}]
    respond_with(R::IpAddress.generate(ip_address))
  end

  delete '/:uuid' do
    ip_address = sb.ip_address.delete({:uuid => @params["uuid"]})
    respond_with(R::IpAddress.generate(ip_address))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","ipv4_address","created_at","updated_at"])
    ip_address = sb.ip_address.update(params)
    respond_with(R::IpAddress.generate(ip_address))
  end
end
