# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/networks' do
  def self.put_post_shared_params
    param :display_name, :String
    param :domain_name, :String
  end

  put_post_shared_params
  param_uuid M::Network
  param_uuid M::Segment, :segment_uuid
  param :mode, :String, in: C::Network::MODES
  param :network_mode, :String, in: C::Network::MODES
  param :ipv4_network, :String, transform: PARSE_IPV4, required: true
  param :ipv4_prefix, :Integer, in: 1..32
  param_options :display_name, required: true
  post do
    uuid_to_id(M::Segment, 'segment_uuid', 'segment_id') if params['segment_uuid']

    params['mode'] = params.delete('network_mode') if params['network_mode']

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
