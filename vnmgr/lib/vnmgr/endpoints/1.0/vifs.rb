# -*- coding: utf-8 -*-

require 'trema/mac'

Vnmgr::Endpoints::V10::VNetAPI.namespace '/vifs' do

  post do
    params = parse_params(@params, ['uuid','network_id','mac_addr','state','created_at','updated_at','ipv4_address'])

    if params.has_key?('uuid')
      raise E::DuplicateUUID, params['uuid'] unless M::Vif[params['uuid']].nil?
      params['uuid'] = M::Vif.trim_uuid(params['uuid'])
    end

    if params.has_key?('mac_addr')
      params['mac_addr'] = Trema::Mac.new(params['mac_addr']).value || raise(E::InvalidUUID, 'foofoo')
    end

    network = M::Network[params['network_id']] || raise(E::InvalidUUID, params['network_id']) if params.has_key?('network_id')
    params['network_id'] = network.id if network

    ipv4_address = parse_ipv4(params.delete('ipv4_address'))

    vif = M::Vif.create(params)

    if network && ipv4_address
      M::IpLease.create({ :network_id => network.id,
                          :vif_id => vif.id,
                          :ip_address_id => M::IpAddress.create({:ipv4_address => ipv4_address}).id,
                        })
    end

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
