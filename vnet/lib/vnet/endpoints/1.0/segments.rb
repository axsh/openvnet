# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/segments' do
  def self.put_post_shared_params
  end

  put_post_shared_params
  param_uuid M::Segment
  param :mode, :String, in: C::Segment::MODES
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

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:Segment)
  end

end
