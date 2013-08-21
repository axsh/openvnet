# -*- coding: utf-8 -*-

require 'trema/mac'

Vnet::Endpoints::V10::VnetAPI.namespace '/ifaces' do

  post do
    params = parse_params(@params, ['uuid','network_id', 'owner_datapath_uuid', 'mac_addr','state','created_at','updated_at','ipv4_address'])

    if params.has_key?('uuid')
      raise E::DuplicateUUID, params['uuid'] unless M::Iface[params['uuid']].nil?
      params['uuid'] = M::Iface.trim_uuid(params['uuid'])
    end

    params['network_id'] = pop_uuid(M::Network, params, 'network_id').id if params.has_key?('network_id')
    params['owner_datapath_id'] = pop_uuid(M::Datapath, params, 'owner_datapath_uuid').id if params.has_key?('owner_datapath_uuid')

    params['mac_addr'] = parse_mac(params['mac_addr']) || raise(E::MissingArgument, 'mac_addr')
    params['ipv4_address'] = parse_ipv4(params['ipv4_address'])

    iface = M::Iface.create(params)

    respond_with(R::Iface.generate(iface))
  end

  get do
    ifaces = data_access.iface.all
    respond_with(R::IfaceCollection.generate(ifaces))
  end

  get '/:uuid' do
    iface = data_access.iface[@params['uuid']]
    respond_with(R::Iface.generate(iface))
  end

  delete '/:uuid' do
    iface = data_access.iface.delete({:uuid => @params['uuid']})
    respond_with(R::Iface.generate(iface))
  end

  put '/:uuid' do
    params = parse_params(@params, ['uuid','network_id','mac_addr','state','created_at','updated_at'])
    iface = data_access.iface.update(params)
    respond_with(R::Iface.generate(iface))
  end
end
