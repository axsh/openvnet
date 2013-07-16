# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/dhcp_ranges' do

  post do
    params = parse_params(@params, ["uuid","network_id","range_begin","range_end","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::DhcpRange[params["uuid"]].nil?
      params["uuid"] = M::DhcpRange.trim_uuid(params["uuid"])
    end
    dhcp_range = M::DhcpRange.create(params)
    respond_with(R::DhcpRange.generate(dhcp_range))
  end

  get do
    dhcp_ranges = M::DhcpRange.all
    respond_with(R::DhcpRangeCollection.generate(dhcp_ranges))
  end

  get '/:uuid' do
    dhcp_range = M::DhcpRange[@params["uuid"]]
    respond_with(R::DhcpRange.generate(dhcp_range))
  end

  delete '/:uuid' do
    M::DhcpRange.destroy(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    params = parse_params(@params, ["network_id","range_begin","range_end","created_at","updated_at"])
    dhcp_range = M::DhcpRange.update(@params["uuid"], params)
    respond_with(R::DhcpRange.generate(dhcp_range))
  end
end
