# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/segments' do
  param_uuid M::Segment
  param :mode, :String, in: C::Segment::MODES
  param :replace_uuid, :Boolean
 
  post do
    post_new(:Segment)
  end

  get do
    get_all(:Segment)
  end

  get '/:uuid' do
    get_by_uuid(:Segment)
  end

  param :preserve_uuid, :Boolean, required: false
  delete '/:uuid' do
    delete_by_uuid(:Segment)
  end
  
  param :new_uuid, :String, required: false
  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:Segment)
  end

end
