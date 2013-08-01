# -*- coding: utf-8 -*-

require 'trema/mac'

Vnet::Endpoints::V10::VnetAPI.namespace '/vifs' do

  post do
    params = parse_params(@params, ['uuid','network_id', 'owner_datapath_uuid', 'mac_addr','state','created_at','updated_at','ipv4_address'])

    if params.has_key?('uuid')
      raise E::DuplicateUUID, params['uuid'] unless M::Vif[params['uuid']].nil?
      params['uuid'] = M::Vif.trim_uuid(params['uuid'])
    end

    params['network_id'] = pop_uuid(M::Network, params, 'network_id').id if params.has_key?('network_id')
    params['owner_datapath_id'] = pop_uuid(M::Datapath, params, 'owner_datapath_uuid').id if params.has_key?('owner_datapath_uuid')

    params['mac_addr'] = parse_mac(params['mac_addr']) || raise(E::MissingArgument, 'mac_addr')
    params['ipv4_address'] = parse_ipv4(params['ipv4_address'])

    vif = M::Vif.create(params)

    respond_with(R::Vif.generate(vif))
  end

  get do
    vifs = data_access.vif.all
    respond_with(R::VifCollection.generate(vifs))
  end

  get '/:uuid' do
    vif = data_access.vif[@params['uuid']]
    respond_with(R::Vif.generate(vif))
  end

  delete '/:uuid' do
    vif = data_access.vif.delete({:uuid => @params['uuid']})
    respond_with(R::Vif.generate(vif))
  end

  put '/:uuid' do
    params = parse_params(@params, ['uuid','network_id','mac_addr','state','created_at','updated_at'])
    vif = data_access.vif.update(params)
    respond_with(R::Vif.generate(vif))
  end
end
