# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/route_links' do
  def self.put_post_shared_params
    param :mac_address, :String, transform: PARSE_MAC
  end

  put_post_shared_params
  param_uuid M::RouteLink
  param_options :mac_address, required: false
  post do
    post_new(:RouteLink)
  end

  get do
    get_all(:RouteLink)
  end

  get '/:uuid' do
    get_by_uuid(:RouteLink)
  end

  delete '/:uuid' do
    delete_by_uuid(:RouteLink)
  end

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:RouteLink)
  end
end
