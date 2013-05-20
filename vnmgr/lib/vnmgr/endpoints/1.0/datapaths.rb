# -*- coding: utf-8 -*-

Vnmgr::Endpoints::V10::VNetAPI.namespace '/datapaths' do
  post do
    possible_params = ["uuid","network_id","mac_addr","state","created_at","updated_at"]
    params = @params.delete_if {|k,v| !possible_params.member?(k)}
    params.default = nil

    datapath = SB.datapath.create(params)
    respond_with(R::Datapath.generate(datapath))
  end

  get do
    datapaths = SB.datapath.get_all
    respond_with(R::DatapathCollection.generate(datapaths))
  end

  get '/:uuid' do
    datapath = SB.datapath.get(@params["uuid"])
    respond_with(R::Datapath.generate(datapath))
  end

  delete '/:uuid' do
    SB.datapath.delete(@params["uuid"])
    respond_with({:uuid => @params["uuid"]})
  end

  put '/:uuid' do
    new_params = filter_params(params)
    datapath = SB.datapath.update(new_params)
    respond_with(R::Datapath.generate(datapath))
  end
end
