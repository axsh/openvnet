# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/ip_addresses' do

  post do
    params = parse_params(@params, ["uuid","ipv4_address","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::IpAddress[params["uuid"]].nil?
      params["uuid"] = M::IpAddress.trim_uuid(params["uuid"])
    end

    params['ipv4_address'] = parse_ipv4(params['ipv4_address'])

    ip_address = M::IpAddress.create(params)
    respond_with(R::IpAddress.generate(ip_address))
  end

  get do
    ip_addresses = M::IpAddress.all
    respond_with(R::IpAddressCollection.generate(ip_addresses))
  end

  get '/:uuid' do
    ip_address = M::IpAddress[@params["uuid"]]
    respond_with(R::IpAddress.generate(ip_address))
  end

  delete '/:uuid' do
    ip_address = M::IpAddress.destroy(@params["uuid"])
    respond_with(R::IpAddress.generate(ip_address))
  end

  put '/:uuid' do
    params = parse_params(@params, ["ipv4_address","created_at","updated_at"])

    params['ipv4_address'] = parse_ipv4(params['ipv4_address'])

    ip_address = M::IpAddress.update(@params["uuid"], params)
    respond_with(R::IpAddress.generate(ip_address))
  end
end
