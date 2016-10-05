# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/mac_leases' do
  def self.put_post_shared_params
    param_uuid M::Interface, :interface_uuid
    param :mac_address, :String, transform: PARSE_MAC
  end

  fill_options = [:interface, :mac_address]

  put_post_shared_params
  param_uuid M::MacLease
  param_uuid M::Segment, :segment_uuid
  param_options :interface_uuid, required: true
  param_options :mac_address, required: true
  param :replace_uuid, :Boolean
 
  post do
    uuid_to_id(M::Interface, "interface_uuid", "interface_id")
    uuid_to_id(M::Segment, "segment_uuid", "segment_id") if params["segment_uuid"]

    post_new(:MacLease, fill_options)
  end

  get do
    get_all(:MacLease, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:MacLease, fill_options)
  end

  param :preserve_uuid, :Boolean, required: false
  delete '/:uuid' do
    delete_by_uuid(:MacLease)
  end

  param :new_uuid, :String, required: false
  put_post_shared_params
  put '/:uuid' do
    uuid_to_id(M::Interface, "interface_uuid", "interface_id") if params["interface_uuid"]

    update_by_uuid(:MacLease, fill_options)
  end
end
