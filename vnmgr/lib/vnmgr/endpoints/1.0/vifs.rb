# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/vifs' do

  post do
    possible_params = ["uuid","network_id","mac_addr","state","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    vif = SB.vif.create(params)
    respond_with(R::Vif.generate(vif))
  end

  get do
    vifs = SB.vif.get_all
    respond_with(R::VifCollection.generate(vifs))
  end

  get '/:uuid' do
    vif = SB.vif.get(@params["uuid"])
    respond_with(R::Vif.generate(vif))
  end

  delete '/:uuid' do
    SB.vif.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    vif = SB.vif.update(new_params)
    respond_with(R::Vif.generate(vif))
  end
end
