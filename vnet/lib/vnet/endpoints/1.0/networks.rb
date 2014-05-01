# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/networks' do
  def self.put_post_shared_params
    param :display_name, :String
    param :ipv4_network, :String, transform: PARSE_IPV4
    param :ipv4_prefix, :Integer, in: 1..32
    param :domain_name, :String
    param :network_mode, :String, in: C::Network::MODES
    param :editable, :Boolean
  end

  put_post_shared_params
  param_options :display_name, required: true
  param_options :ipv4_network, required: true
  param_uuid M::Network
  post do
    post_new(:Network)
  end

  get do
    get_all(:Network)
  end

  get '/:uuid' do
    get_by_uuid(:Network)
  end

  delete '/:uuid' do
    begin
      delete_by_uuid(:Network)
    rescue Vnet::Models::DeleteRestrictionError => e
      raise E::DeleteRestrictionError, e.message
    end
  end

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:Network)
  end
end
