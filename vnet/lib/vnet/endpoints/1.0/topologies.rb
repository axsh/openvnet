# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/topologies' do
  def self.put_post_shared_params
  end

  put_post_shared_params
  param_uuid M::Topology
  param :mode, :String, in: C::Topology::MODES
  post do
    post_new(:Topology)
  end

  get do
    get_all(:Topology)
  end

  get '/:uuid' do
    get_by_uuid(:Topology)
  end

  delete '/:uuid' do
    delete_by_uuid(:Topology)
  end

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:Topology)
  end
end
