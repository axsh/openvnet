# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/mac_leases' do
  def self.put_post_shared_params
    param_uuid M::Interface, :interface_uuid
  end

  fill_options = [:interface, :mac_address]

  put_post_shared_params
  param_uuid M::MacLease
  param_uuid M::Segment, :segment_uuid, required: false
  param_uuid M::Interface, :interface_uuid, required: false
  param :mac_address, :String, transform: PARSE_MAC
  param :mrg_uuid, :String
  param :mac_range_group_uuid, :String
  post do
    uuid_to_id(M::Segment, 'segment_uuid', 'segment_id') if params['segment_uuid']
    uuid_to_id(M::Interface, 'interface_uuid', 'interface_id') if params['interface_uuid']
    uuid_to_id(M::MacRangeGroup, 'mrg_uuid', 'mac_range_group_id') if params['mrg_uuid']
    uuid_to_id(M::MacRangeGroup, 'mac_range_group_uuid', 'mac_range_group_id') if params['mac_range_group_uuid']

    if params['mac_address'].nil? && params['mac_range_group_id'].nil?
      raise(E::MissingArgument, 'mac_address')
    end

    post_new(:MacLease, fill_options)
  end

  get do
    get_all(:MacLease, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:MacLease, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:MacLease)
  end

  put_post_shared_params
  put '/:uuid' do
    uuid_to_id(M::Interface, 'interface_uuid', 'interface_id') if params['interface_uuid']

    update_by_uuid(:MacLease, fill_options)
  end
end
