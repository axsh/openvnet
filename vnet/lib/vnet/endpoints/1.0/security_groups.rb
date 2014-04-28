# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/security_groups' do
  def self.put_post_shared_params
    param :display_name, :String
    param :description, :String
    param :rules, :String #TODO: Check rule syntax
  end

  put_post_shared_params
  param_options :display_name, required: true
  param_uuid :sg
  post do
    post_new :SecurityGroup
  end

  get do
    get_all :SecurityGroup
  end

  get('/:uuid') do
    get_by_uuid :SecurityGroup
  end

  delete('/:uuid') do
    delete_by_uuid :SecurityGroup
  end

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:SecurityGroup, put_post_shared_params)
  end

  post '/:uuid/interfaces/:interface_uuid' do
    interface = check_syntax_and_get_id(M::Interface, params, 'interface_uuid', 'interface_id')
    security_group = check_syntax_and_get_id(M::SecurityGroup, params, 'uuid', 'security_group_id')

    M::InterfaceSecurityGroup.filter(:interface_id => interface.id,
      :security_group_id => security_group.id).empty? ||
    raise(E::RelationAlreadyExists, "#{interface.uuid} <=> #{security_group.uuid}")

    M::InterfaceSecurityGroup.create(params)
    respond_with(R::SecurityGroup.interfaces(security_group))
  end

  get '/:uuid/interfaces' do
    show_relations(:SecurityGroup, :interfaces)
  end

  delete '/:uuid/interfaces/:interface_uuid' do
    params = parse_params(@params, ['uuid', 'interface_uuid'])
    check_required_params(params, ['uuid', 'interface_uuid'])

    security_group = check_syntax_and_pop_uuid(M::SecurityGroup, params)
    interface = check_syntax_and_pop_uuid(M::Interface, params, 'interface_uuid')

    relations = M::InterfaceSecurityGroup.batch.filter(:interface_id => interface.id,
      :security_group_id => security_group.id).all.commit

    # We call the destroy class method so we go trough NodeApi and send an
    # update isolation event
    relations.each { |r| M::InterfaceSecurityGroup.destroy(r.id) }
    respond_with(R::SecurityGroup.interfaces(security_group))
  end
end
