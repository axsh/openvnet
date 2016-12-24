# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/security_groups' do
  def self.put_post_shared_params
    param :display_name, :String
    param :description, :String
    param :rules, :String
  end

  put_post_shared_params
  param_uuid M::SecurityGroup
  param_options :display_name, required: true
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
    update_by_uuid(:SecurityGroup)
  end

  post '/:uuid/interfaces/:interface_uuid' do
    interface = check_syntax_and_get_id(M::Interface, 'interface_uuid', 'interface_id')
    security_group = check_syntax_and_get_id(M::SecurityGroup, 'uuid', 'security_group_id')

    filter = { :interface_id => interface.id, :security_group_id => security_group.id }
    M::SecurityGroupInterface.filter(filter).empty? ||
      raise(E::RelationAlreadyExists, "#{interface.uuid} <=> #{security_group.uuid}")

    M::SecurityGroupInterface.create(
      :interface_id => interface.id,
      :security_group_id => security_group.id
    )

    respond_with(R::SecurityGroup.interfaces(security_group))
  end

  get '/:uuid/interfaces' do
    show_relations(:SecurityGroup, :interfaces)
  end

  delete '/:uuid/interfaces/:interface_uuid' do
    security_group = check_syntax_and_pop_uuid(M::SecurityGroup)
    interface = check_syntax_and_pop_uuid(M::Interface, 'interface_uuid')

    relations = M::SecurityGroupInterface.batch.filter(:interface_id => interface.id,
      :security_group_id => security_group.id).all.commit

    # We call the destroy class method so we go trough NodeApi and send an
    # update isolation event
    relations.each { |r| M::SecurityGroupInterface.destroy(r.id) }
    respond_with(R::SecurityGroup.interfaces(security_group))
  end
end
