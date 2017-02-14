# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/topologies' do
  def self.put_post_shared_params
  end

  put_post_shared_params
  param_uuid M::Topology
  param :mode, :String, required: true, in: C::Topology::MODES
  post do
    post_new(:Topology)
  end

  get do
    get_all(:Topology)
  end

  get '/:uuid' do
    get_by_uuid(:Topology)
  end

  delete '/:uuid' do
    delete_by_uuid(:Topology)
  end

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:Topology)
  end

  TOPOLOGY_ASSOCS = [
    ['datapath', true],
    ['network', nil],
    ['segment', nil],
    ['route_link', nil]
  ].freeze

  TOPOLOGY_ASSOCS.each { |other_name, with_interface|
    other_id = "#{other_name}_id".to_sym
    other_uuid = "#{other_name}_uuid".to_sym
    assoc_table = "topology_#{other_name}s".to_sym

    other_model = M.const_get(other_name.camelize)
    assoc_model = M.const_get("Topology#{other_name.camelize}")
    assoc_response = R.const_get("Topology#{other_name.camelize}")
    
    # TODO: Change to confirm with either POST or PUT idioms.
    param_uuid M::Interface, :interface_uuid, required: true if with_interface
    post "/:uuid/#{other_name}s/:#{other_uuid}" do
      uuid_to_id(M::Topology, :uuid, :topology_id)
      uuid_to_id(other_model, other_uuid, other_id)
      uuid_to_id(M::Interface, :interface_uuid, :interface_id) if with_interface
      
      remove_system_parameters
      respond_with(assoc_response.generate(assoc_model.create(params)))
    end

    get "/:uuid/#{other_name}s" do
      show_relations(:Topology, assoc_table)
    end

    # TODO: No need to have other_uuid.

    delete "/:uuid/#{other_name}s/:#{other_uuid}" do
      uuid_to_id(M::Topology, :uuid, :topology_id)
      other = uuid_to_id(other_model, other_uuid, other_id)

      remove_system_parameters
      assoc_model.destroy(params)

      respond_with([other.uuid])
    end
  }

  post '/:uuid/underlays/:underlay_uuid' do
    uuid_to_id(M::Topology, :uuid, :overlay_id)
    uuid_to_id(M::Topology, :underlay_uuid, :underlay_id)

    remove_system_parameters
    respond_with(R::TopologyLayer.generate(M::TopologyLayer.create(params)))
  end

  get '/:uuid/underlays' do
    show_relations(:Topology, :underlays, response_class: R::TopologyCollection)
  end

  delete '/:uuid/underlays/:underlay_uuid' do
    uuid_to_id(M::Topology, :uuid, :overlay_id)
    underlay = uuid_to_id(M::Topology, :underlay_uuid, :underlay_id)

    remove_system_parameters
    M::TopologyLayer.destroy(params)

    respond_with([underlay.uuid])
  end

end
