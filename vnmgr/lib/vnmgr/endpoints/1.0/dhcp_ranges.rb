# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/dhcp_ranges' do

  post do
    possible_params = ["uuid","network_id","range_begin","range_end","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    dhcp_range = sb.dhcp_range.create(params)
    respond_with(R::DhcpRange.generate(dhcp_range))
  end

  get do
    dhcp_ranges = sb.dhcp_range.get_all
    respond_with(R::DhcpRangeCollection.generate(dhcp_ranges))
  end

  get '/:uuid' do
    dhcp_range = sb.dhcp_range.get(@params["uuid"])
    respond_with(R::DhcpRange.generate(dhcp_range))
  end

  delete '/:uuid' do
    sb.dhcp_range.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    dhcp_range = sb.dhcp_range.update(new_params)
    respond_with(R::DhcpRange.generate(dhcp_range))
  end
end
