# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/segments' do
  param_uuid M::Segment
  param :mode, :String, in: C::Segment::MODES, required: true
  post do
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
