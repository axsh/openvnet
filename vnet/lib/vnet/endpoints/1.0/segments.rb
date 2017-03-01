# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/segments' do

  param_uuid M::Segment
  param_uuid M::Topology, :topology_uuid
  param :mode, :String, in: C::Segment::MODES, required: true
  post do
    uuid_to_id(M::Topology, 'topology_uuid', 'topology_id') if params['topology_uuid']

    post_new(:Segment)
  end

  get do
    get_all(:Segment)
  end

  get '/:uuid' do
    get_by_uuid(:Segment)
  end

  delete '/:uuid' do
    delete_by_uuid(:Segment)
  end

end
