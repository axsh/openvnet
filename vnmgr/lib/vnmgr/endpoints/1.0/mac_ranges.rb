# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/mac_ranges' do
  post do
    possible_params = ["uuid","vendor_id","range_begin","range_end","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    mac_range = sb.mac_range.create(params)
    respond_with(R::MacRange.generate(mac_range))
  end

  get do
    mac_ranges = sb.mac_range.get_all
    respond_with(R::MacRangeCollection.generate(mac_ranges))
  end

  get '/:uuid' do
    mac_range = sb.mac_range.get(@params["uuid"])
    respond_with(R::MacRange.generate(mac_range))
  end

  delete '/:uuid' do
    sb.mac_range.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    mac_range = sb.mac_range.update(new_params)
    respond_with(R::MacRange.generate(mac_range))
  end
end
