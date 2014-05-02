# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/vlan_translations' do
  def self.put_post_shared_params
    param_uuid M::Translation, :translation_uuid
    param :mac_address, :String, transform: PARSE_MAC
    param :vlan_id, :Integer
    param :network_id, :Integer
  end

  def parse_translation
    translation = uuid_to_id(M::Translation, "translation_uuid", "translation_id")

    if translation.mode != C::Translation::MODE_VNET_EDGE
      raise(E::ArgumentError, 'Translation mode must be "%s".') %
        C::Translation::MODE_VNET_EDGE
    end
  end

  put_post_shared_params
  param_options :network_id, required: true
  param_options :translation_uuid, required: true
  param_uuid M::VlanTranslation
  post do
    parse_translation

    post_new(:VlanTranslation)
  end

  get do
    get_all(:VlanTranslation)
  end

  get '/:uuid' do
    get_by_uuid(:VlanTranslation)
  end

  delete '/:uuid' do
    delete_by_uuid(:VlanTranslation)
  end

  put_post_shared_params
  put '/:uuid' do
    parse_translation if params["translation_uuid"]

    update_by_uuid(:VlanTranslation)
  end
end
