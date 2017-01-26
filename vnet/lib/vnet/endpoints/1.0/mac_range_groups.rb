# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/mac_range_groups' do
  def self.put_post_shared_params
    param :allocation_type, :String
  end

  fill_options = [ ]

  put_post_shared_params
  param_uuid M::MacRangeGroup
  post do
    post_new(:MacRangeGroup, fill_options)
  end

  get do
    get_all(:MacRangeGroup, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:MacRangeGroup, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:MacRangeGroup)
  end

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:MacRangeGroup, fill_options)
  end

  param_uuid M::MacRange, :uuid, transform: proc { |u| M::MacRange.trim_uuid(u) }
  param :begin_mac_address, :String, transform: PARSE_MAC
  param :end_mac_address, :String, transform: PARSE_MAC
  post '/:mac_range_group_uuid/mac_ranges' do
    check_syntax_and_get_id(M::MacRangeGroup, "mac_range_group_uuid", "mac_range_group_id")

    remove_system_parameters

    mac_range = M::MacRange.create(params)
    respond_with(R::MacRange.generate(mac_range))
  end

  get '/:uuid/mac_ranges' do
    show_relations(:MacRangeGroup, :mac_ranges)
  end

  delete '/:uuid/mac_ranges/:mac_range_uuid' do
    mac_range_group = check_syntax_and_pop_uuid(M::MacRangeGroup)
    mac_range = check_syntax_and_pop_uuid(M::MacRange, "mac_range_uuid")

    raise E::UnknownUUIDResource, mac_range.uuid unless mac_range.mac_range_group_id == mac_range_group.id

    M::MacRange.destroy(mac_range.uuid)

    respond_with([mac_range.uuid])
  end

end
