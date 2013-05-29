# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/mac_ranges' do
  post do
    params = parse_params(@params, ["uuid","vendor_id","range_begin","range_end","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::MacRange[params["uuid"]].nil?
      params["uuid"] = M::MacRange.trim_uuid(params["uuid"])
    end
    mac_range = data_access.mac_range.create(params)
    respond_with(R::MacRange.generate(mac_range))
  end

  get do
    mac_ranges = data_access.mac_range.all
    respond_with(R::MacRangeCollection.generate(mac_ranges))
  end

  get '/:uuid' do
    mac_range = data_access.mac_range[{:uuid => @params["uuid"]}]
    respond_with(R::MacRange.generate(mac_range))
  end

  delete '/:uuid' do
    mac_range = data_access.mac_range.delete({:uuid => @params["uuid"]})
    respond_with(R::MacRange.generate(mac_range))
  end

  put '/:uuid' do
    params = parse_params(@params, ["uuid","vendor_id","range_begin","range_end","created_at","updated_at"])
    mac_range = data_access.mac_range.update(params)
    respond_with(R::MacRange.generate(mac_range))
  end
end
