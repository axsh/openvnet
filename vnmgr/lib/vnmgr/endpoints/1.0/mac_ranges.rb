# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/mac_ranges' do
  post do
    params = parse_params(@params, ["uuid","vendor_id","range_begin","range_end","created_at","updated_at"])

    if params.has_key?("uuid")
      raise E::DuplicateUUID, params["uuid"] unless M::MacRange[params["uuid"]].nil?
      params["uuid"] = M::MacRange.trim_uuid(params["uuid"])
    end
    mac_range = M::MacRange.create(params)
    respond_with(R::MacRange.generate(mac_range))
  end

  get do
    mac_ranges = M::MacRange.all
    respond_with(R::MacRangeCollection.generate(mac_ranges))
  end

  get '/:uuid' do
    mac_range = M::MacRange[@params["uuid"]]
    respond_with(R::MacRange.generate(mac_range))
  end

  delete '/:uuid' do
    mac_range = M::MacRange.destroy(@params["uuid"])
    respond_with(R::MacRange.generate(mac_range))
  end

  put '/:uuid' do
    params = parse_params(@params, ["vendor_id","range_begin","range_end","created_at","updated_at"])
    mac_range = M::MacRange.update(@params["uuid"], params)
    respond_with(R::MacRange.generate(mac_range))
  end
end
