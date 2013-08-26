# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/mac_addresses' do

  post do
    params = parse_params(@params, ["uuid","mac_address"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::MacAddress[params["uuid"]].nil?
      params["uuid"] = M::MacAddress.trim_uuid(params["uuid"])
    end

    params['mac_address'] = parse_mac(params['mac_address']) || raise(E::MissingArgument, 'mac_address')

    mac_addr = M::MacAddress.create(params)
    respond_with(R::MacAddress.generate(mac_addr))
  end

  get do
    mac_addrs = M::MacAddress.all
    respond_with(R::MacAddressCollection.generate(mac_addrs))
  end

  get '/:uuid' do
    mac_addr = M::MacAddress[@params["uuid"]]
    respond_with(R::MacAddress.generate(mac_addr))
  end

  delete '/:uuid' do
    mac_addr = M::MacAddress.destroy(@params["uuid"])
    respond_with(R::MacAddress.generate(mac_addr))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","mac_addr"])

    params['mac_address'] = parse_mac(params['mac_address']) || raise(E::MissingArgument, 'mac_address')

    mac_addr = M::MacAddress.update(@params["uuid"], params)
    respond_with(R::MacAddress.generate(mac_addr))
  end
end
