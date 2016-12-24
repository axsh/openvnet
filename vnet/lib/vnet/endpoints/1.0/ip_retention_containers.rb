Vnet::Endpoints::V10::VnetAPI.namespace '/ip_retention_containers' do
  def self.put_post_shared_params
    param :lease_time, :Integer
    param :grace_time, :Integer
  end

  put_post_shared_params
  param_uuid M::IpRetentionContainer
  post do
    post_new(:IpRetentionContainer)
  end

  get do
    get_all(:IpRetentionContainer)
  end

  get '/:uuid' do
    get_by_uuid(:IpRetentionContainer)
  end

  delete '/:uuid' do
    delete_by_uuid(:IpRetentionContainer)
  end

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:IpRetentionContainer)
  end

  get '/:uuid/ip_retentions' do
    show_relations(:IpRetentionContainer, :ip_retentions)
  end
end
