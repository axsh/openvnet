# -*- coding: utf-8 -*-

require 'trema/mac'

Vnet::Endpoints::V10::VnetAPI.namespace '/interfaces' do

  post do
    params = parse_params(@params, ['uuid','network_uuid','name','mode','active_datapath_uuid','owner_datapath_uuid','state'])

    if params.has_key?('uuid')
      raise E::DuplicateUUID, params['uuid'] unless M::Interface[params['uuid']].nil?
      params['uuid'] = M::Interface.trim_uuid(params['uuid'])
    end

    params['network_id'] = pop_uuid(M::Network, params, 'network_uuid').id if params.has_key?('network_uuid')
    params['active_datapath_id'] = pop_uuid(M::Datapath, params, 'active_datapath_uuid').id if params.has_key?('active_datapath_uuid')
    params['owner_datapath_id'] = pop_uuid(M::Datapath, params, 'owner_datapath_uuid').id if params.has_key?('owner_datapath_uuid')

    iface = M::Interface.create(params)

    respond_with(R::Interface.generate(iface))
  end

  get do
    ifaces = data_access.iface.all
    respond_with(R::InterfaceCollection.generate(ifaces))
  end

  get '/:uuid' do
    iface = data_access.iface[@params['uuid']]
    respond_with(R::Interface.generate(iface))
  end

  delete '/:uuid' do
    iface = data_access.iface.delete({:uuid => @params['uuid']})
    respond_with(R::Interface.generate(iface))
  end

  put '/:uuid' do
    params = parse_params(@params, ['uuid','network_uuid','name','mode','owner_datapath_uuid','active_datapath_uuid','state'])

    params['network_id'] = pop_uuid(M::Network, params, 'network_uuid').id if params.has_key?('network_uuid')
    params['active_datapath_id'] = pop_uuid(M::Datapath, params, 'active_datapath_uuid').id if params.has_key?('active_datapath_uuid')
    params['owner_datapath_id'] = pop_uuid(M::Datapath, params, 'owner_datapath_uuid').id if params.has_key?('owner_datapath_uuid')

    iface = data_access.iface.update(params)
    respond_with(R::Interface.generate(iface))
  end
end
